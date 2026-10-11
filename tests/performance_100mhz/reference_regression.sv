`timescale 1ns/1ps
module reference_regression;
  reg clk=0, reset=1;
  always #5 clk=~clk;
  main dut(.clk(clk), .reset(reset));
  reg active=0, halted=0;
  reg [31:0] rr[0:31];
  reg [7:0] memory[0:1023];
  reg [31:0] seed=32'hc0decafe, ref_pc;
  integer p, halt_pc, programs=0, commits=0, checks=0, stalls=0;
  integer run_seed, random_programs=128;
  string label;

  function automatic [31:0] rng(input [31:0] s);
    reg [31:0] t;
    begin t=s^(s<<13); t=t^(t>>17); rng=t^(t<<5); end
  endfunction
  function automatic [31:0] ri(input integer imm,rs1,f3,rd,op=19);
    ri=((imm&4095)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op;
  endfunction
  function automatic [31:0] r(input integer f7,rs2,rs1,f3,rd);
    r=(f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|51;
  endfunction
  function automatic [31:0] s(input integer imm,rs2,rs1,f3);
    s=(((imm>>5)&127)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&31)<<7)|35;
  endfunction
  function automatic [31:0] b(input integer imm,rs2,rs1,f3);
    b=(((imm>>12)&1)<<31)|(((imm>>5)&63)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((imm>>1)&15)<<8)|(((imm>>11)&1)<<7)|99;
  endfunction
  function automatic [31:0] j(input integer imm,rd);
    j=(((imm>>20)&1)<<31)|(((imm>>1)&1023)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&255)<<12)|(rd<<7)|111;
  endfunction
  function automatic [31:0] edge_value(input integer index);
    case(index)
      0:edge_value=0; 1:edge_value=1; 2:edge_value=32'hffffffff;
      3:edge_value=32'h80000000; 4:edge_value=32'h7fffffff;
      5:edge_value=32'h80000001; 6:edge_value=32'hfffffffe;
      default:edge_value=32'h12345678;
    endcase
  endfunction
  function automatic [31:0] word_at(input integer addr);
    word_at={memory[(addr+3)&1023],memory[(addr+2)&1023],memory[(addr+1)&1023],memory[addr&1023]};
  endfunction
  task automatic check(input string what,input [31:0] actual,want);
    checks++;
    if(actual!==want) $fatal(1,"%s: %s at PC=%08x got=%08x expected=%08x seed=%08x",label,what,ref_pc,actual,want,seed);
  endtask

  // Behavioral ISA interpreter: architectural state only, no pipeline model.
  // Compare every non-NOP writeback instruction in program order and its result.
  task automatic retire(input [31:0] actual);
    reg [31:0] insn,x,y,imm,value,next_pc,addr,raw;
    integer op,f3,f7,rd,rs1,rs2,nbytes;
    reg writes,take,legal;
    begin
      insn=word_at(integer'(ref_pc));
      for(integer n=0;n<256 && insn==32'h00000013;n++) begin
        ref_pc=(ref_pc+4)&1023; insn=word_at(integer'(ref_pc));
      end
      check("retired instruction order",actual,insn);
      op=integer'(insn[6:0]); f3=integer'(insn[14:12]); f7=integer'(insn[31:25]);
      rd=integer'(insn[11:7]);rs1=integer'(insn[19:15]);rs2=integer'(insn[24:20]);
      x=rr[rs1];y=rr[rs2];imm={{20{insn[31]}},insn[31:20]};
      value=0;next_pc=ref_pc+4;writes=0;take=0;legal=1;addr=0;raw=0;nbytes=0;
      case(op)
        55:begin value={insn[31:12],12'd0};writes=1;end
        23:begin value=ref_pc+{insn[31:12],12'd0};writes=1;end
        111:begin
          imm={{11{insn[31]}},insn[31],insn[19:12],insn[20],insn[30:21],1'b0};
          value=ref_pc+4;next_pc=ref_pc+imm;writes=1;
        end
        103:if(f3==0) begin value=ref_pc+4;next_pc=(x+imm)&32'hfffffffe;writes=1;end
        99:begin
          imm={{19{insn[31]}},insn[31],insn[7],insn[30:25],insn[11:8],1'b0};
          case(f3)
            0:take=(x==y);1:take=(x!=y);4:take=($signed(x)<$signed(y));
            5:take=($signed(x)>=$signed(y));6:take=(x<y);7:take=(x>=y);
            default:take=0;
          endcase
          if(take)next_pc=ref_pc+imm;
        end
        3:begin
          addr=x+imm; raw=word_at(integer'(addr));
          case(f3)
            0:value={{24{raw[7]}},raw[7:0]};1:value={{16{raw[15]}},raw[15:0]};
            2:value=raw;4:value={24'd0,raw[7:0]};5:value={16'd0,raw[15:0]};
            default:legal=0;
          endcase
          writes=legal;
        end
        35:begin
          imm={{20{insn[31]}},insn[31:25],insn[11:7]};addr=x+imm;
          case(f3) 0:nbytes=1;1:nbytes=2;2:nbytes=4;default:nbytes=0;endcase
          for(integer k=0;k<nbytes;k++)memory[(integer'(addr)+k)&1023]=8'(y>>(8*k));
        end
        19,51:begin
          if(op==19)begin
            y=imm;
            if(f3==1 && f7!=0)legal=0;
            if(f3==5 && f7!=0 && f7!=32)legal=0;
          end else if(f7!=0 && !(f7==32 && (f3==0 || f3==5)))legal=0;
          case(f3)
            0:value=(op==51 && f7==32)?x-y:x+y;
            1:value=x<<y[4:0];2:value={31'd0,($signed(x)<$signed(y))};
            3:value={31'd0,(x<y)};4:value=x^y;
            5:begin
              // Keep the signed expression outside a mixed signed/unsigned
              // ternary, which would coerce the arithmetic shift to unsigned.
              if(f7==32)value=$signed(x)>>>y[4:0];
              else value=x>>y[4:0];
            end
            6:value=x|y;7:value=x&y;
          endcase
          writes=legal;
        end
        default:writes=0; // Documented unsupported-instruction bubble policy.
      endcase
      check("register write enable",{31'd0,dut.RISCV_Core.wb_reg_write},{31'd0,writes});
      if(writes)begin
        check("destination register",{27'd0,dut.RISCV_Core.wb_rd_addr},32'(rd));
        check($sformatf("writeback insn=%08x x=%08x y=%08x",insn,x,y),dut.RISCV_Core.wb_final_data,value);
        if(rd!=0)rr[rd]=value;
      end
      rr[0]=0; commits++;
      if(integer'(ref_pc)==halt_pc)begin halted=1;active=0;end
      ref_pc=next_pc&1023;
    end
  endtask
  always @(posedge clk) begin
    if(active && !reset)begin
      if(dut.RISCV_Core.stall_out)stalls++;
      if(dut.RISCV_Core.wb_valid && dut.RISCV_Core.MEM_WB_Pipe.insr_out!=0 && dut.RISCV_Core.MEM_WB_Pipe.insr_out!=32'h00000013)
        retire(dut.RISCV_Core.MEM_WB_Pipe.insr_out);
    end
  end
  task automatic fresh(input string name);
    @(negedge clk);active=0;reset=1;label=name;
    repeat(3)@(negedge clk);
    for(integer k=0;k<256;k++)dut.System_Memory.ram[k]=32'h00000013;
    for(integer k=128;k<256;k++)begin seed=rng(seed);dut.System_Memory.ram[k]=seed;end
    p=0;halted=0;stalls=0;
  endtask
  task automatic emit(input [31:0] insn);
    dut.System_Memory.ram[p]=insn;p++;
  endtask
  task automatic constant(input integer rd,input [31:0] value);
    emit(((value+32'h800)&32'hfffff000)|(rd<<7)|55);
    emit(ri(integer'(value),rd,0,rd));
  endtask
  task automatic run_program;
    halt_pc=p*4;emit(j(0,0));
    for(integer k=0;k<1024;k++)memory[k]=8'(dut.System_Memory.ram[k/4]>>(8*(k%4)));
    for(integer k=0;k<32;k++)rr[k]=0;
    ref_pc=0;active=1;reset=0;
    for(integer cycle=0;cycle<2000 && !halted;cycle++)@(negedge clk);
    if(!halted)$fatal(1,"%s did not reach completion; ref PC=%08x",label,ref_pc);
    repeat(8)@(negedge clk);
    for(integer k=0;k<32;k++)check($sformatf("final x%0d",k),dut.RISCV_Core.register_file.CPU_reg[k],rr[k]);
    for(integer k=0;k<256;k++)check($sformatf("final memory word %0d",k),dut.System_Memory.ram[k],word_at(4*k));
    programs++;
  endtask

  initial begin
    if($value$plusargs("seed=%d",run_seed))seed=32'(run_seed);
    if($value$plusargs("programs=%d",random_programs))begin end
    $display("REFERENCE seed=%08x random_programs=%0d",seed,random_programs);
    if($test$plusargs("trace"))begin $dumpfile("tests/performance_100mhz/build/reference.vcd");$dumpvars(0,reference_regression);end

    // First instruction is deliberately not NOP, including a jump at reset PC.
    fresh("startup executes instruction once");emit(ri(1,1,0,1));emit(ri(1,1,0,1));run_program();
    fresh("JAL at PC zero and immediate link consumer");emit(j(12,1));emit(s(512,1,0,2));emit(ri(99,0,0,2));emit(ri(3,1,0,2));run_program();
    fresh("function call return and link forwarding");
    emit(j(16,1));emit(ri(1,5,0,5));emit(j(20,0));emit(ri(99,0,0,5));
    emit(ri(41,0,0,5));emit(ri(0,1,0,0,103));emit(s(512,1,0,2));emit(ri(2,5,0,6));run_program();
    fresh("negative JAL loop");emit(ri(3,0,0,1));emit(ri(-1,1,0,1));emit(b(8,0,1,0));emit(j(-8,0));emit(ri(12,0,0,2));run_program();

    // Load sources followed by every control-flow kind, with the saved PC held.
    fresh("load to JALR odd target and destination alias");dut.System_Memory.ram[128]=25;
    emit(ri(512,0,2,1,3));emit(ri(0,1,0,1,103));emit(s(516,1,0,2));
    emit(ri(99,0,0,2));emit(ri(99,0,0,3));emit(ri(99,0,0,4));emit(ri(0,1,0,2));run_program();
    fresh("load followed by JAL with false encoded source");
    emit(ri(512,0,2,8,3));emit(j(8,1));emit(s(512,8,0,2));emit(ri(0,1,0,2));run_program();
    check("no false load-to-JAL stalls",32'(stalls),0);
    fresh("immediate and AUIPC bits are not source registers");
    emit(ri(512,0,2,1,3));emit(ri(1,0,0,2));emit(ri(516,0,2,1,3));emit(32'h00008197);run_program();
    check("no false immediate/upper stalls",32'(stalls),0);
    for(integer gap=0;gap<4;gap++)begin
      fresh($sformatf("load branch PC with gap %0d",gap));dut.System_Memory.ram[128]=0;
      emit(ri(512,0,2,1,3));repeat(gap)emit(32'h00000013);
      emit(b(12,0,1,0));emit(j(40,2));emit(s(512,1,0,2));emit(ri(7,0,0,3));run_program();
    end
    fresh("older taken branch overrides younger jump");emit(b(12,0,0,0));emit(j(40,1));emit(s(512,1,0,2));emit(ri(11,0,0,2));run_program();
    fresh("older JALR overrides younger JAL");emit(ri(16,0,0,1));emit(ri(0,1,0,2,103));emit(j(40,3));emit(s(512,3,0,2));emit(ri(2,2,0,4));run_program();

    // Repeated loads to the same destination stress newest-value priority.
    for(integer typ=0;typ<6;typ++)if(typ!=3)begin
      for(integer offset=0;offset<4;offset++)if(typ==0||typ==4||((typ==1||typ==5)&&offset%2==0)||(typ==2&&offset==0))begin
        fresh($sformatf("back-to-back load/store type=%0d offset=%0d",typ,offset));
        dut.System_Memory.ram[128]=32'h80ff7f81;dut.System_Memory.ram[129]=32'hfe01aa55;
        emit(ri(512+offset,0,typ,1,3));emit(ri(516+offset,0,typ,1,3));
        emit(s(520,1,0,2));emit(ri(1,1,0,2));emit(ri(520,0,2,3,3));run_program();
      end
    end
    fresh("load determines store base and data");dut.System_Memory.ram[128]=532;
    emit(ri(512,0,2,1,3));emit(s(0,1,1,2));emit(ri(532,0,2,2,3));run_program();
    fresh("zero register load and store");emit(ri(512,0,2,0,3));emit(ri(7,0,0,1));emit(s(520,0,0,2));run_program();
    check("load x0 creates no stall",32'(stalls),0);
    fresh("consecutive byte stores reconstruct word");
    constant(1,32'h11223344);for(integer off=0;off<4;off++)begin emit(s(512+off,1,0,0));emit(ri(8,1,5,1));end
    emit(ri(512,0,2,2,3));run_program();
    fresh("data memory upper boundary and negative offsets");constant(1,1024);constant(2,32'hfedcba98);
    emit(s(-4,2,1,2));emit(ri(-4,1,2,3,3));emit(s(-1,2,1,0));emit(ri(-1,1,4,4,3));run_program();

    fresh("unsupported encodings have no side effects");constant(1,32'hdeadbeef);constant(2,512);
    for(integer f3=0;f3<8;f3++)emit(r(1,1,1,f3,3)); // All M-extension instructions, including MUL, are disabled.
    emit(r(127,1,1,0,3));emit(ri(32,1,1,3));emit(ri(512,1,5,3));
    emit(s(0,1,2,3));emit(s(0,1,2,4));emit(ri(0,2,3,3,3));emit(ri(0,2,6,3,3));
    emit(ri(0,2,1,3,103));emit(b(16,1,1,2));emit(32'hffffffff);emit(ri(1,0,0,4));run_program();

    // Exhaustive boundary pairs for the new direct branch comparator, with
    // both bypassed ALU operands and immediate load-use dependencies.
    for(integer f3=0;f3<8;f3++)if(f3!=2 && f3!=3)begin
      for(integer x=0;x<8;x++)for(integer y=0;y<8;y++)begin
        for(integer from_load=0;from_load<2;from_load++)begin
          fresh($sformatf("branch f3=%0d x=%0d y=%0d load=%0d",f3,x,y,from_load));
          constant(1,edge_value(x));
          if(from_load)begin
            dut.System_Memory.ram[128]=edge_value(y);
            emit(ri(512,0,2,2,3));
          end else constant(2,edge_value(y));
          emit(b(12,2,1,f3));
          emit(s(516,1,0,2)); // Must be squashed only for a taken branch.
          emit(ri(91,0,0,3));
          emit(ri(1,0,0,4));
          run_program();
        end
      end
    end
    fresh("disabled MUL preserves destination and dependent operands");
    constant(1,7);constant(2,9);constant(3,32'h76543210);
    emit(r(1,2,1,0,3));emit(ri(1,3,0,4));emit(s(512,3,0,2));
    emit(ri(516,0,2,1,3));emit(r(1,2,1,0,3));emit(ri(0,3,0,5));
    run_program();

    // Mixed short programs: real ISA interpreter supplies every expected result.
    for(integer prog=0;prog<random_programs;prog++)begin
      fresh($sformatf("mixed random program %0d",prog));
      emit(ri(512,0,0,31));
      for(integer rd=1;rd<9;rd++)begin seed=rng(seed);constant(rd,seed);end
      for(integer n=0;n<80;n++)begin
        integer choice,rs1,rs2,rd,f3,offset,imm;
        seed=rng(seed);choice=integer'(seed%16);rs1=integer'(seed[8:4]%9);rs2=integer'(seed[13:9]%9);
        rd=integer'(seed[18:14]%9);f3=integer'(seed[21:19]);offset=integer'(seed[29:22])&252;
        imm=integer'({{20{seed[11]}},seed[11:0]});
        case(choice)
          0,1:emit(r((f3==0||f3==5)&&seed[31]?32:0,rs2,rs1,f3,rd));
          2:emit(r(1,rs2,rs1,0,rd));
          3,4:begin
            if(f3==1)imm=integer'(seed[4:0]);
            if(f3==5)imm=integer'(seed[4:0])|(seed[31]?1024:0);
            emit(ri(imm,rs1,f3,rd));
          end
          5:emit((seed&32'hfffff000)|(rd<<7)|55);
          6:emit((seed&32'hfffff000)|(rd<<7)|23);
          7,8,9:begin
            case(seed%5) 0:f3=0;1:f3=1;2:f3=2;3:f3=4;4:f3=5;endcase
            if(f3==0||f3==4)offset+=integer'(seed[1:0]);
            if(f3==1||f3==5)offset+=integer'(seed[1])*2;
            emit(ri(offset,31,f3,rd,3));
          end
          10,11:begin
            f3=integer'(seed%3);if(f3==0)offset+=integer'(seed[1:0]);if(f3==1)offset+=integer'(seed[1])*2;
            emit(s(offset,rs2,31,f3));
          end
          12:begin
            case(seed%6)0:f3=0;1:f3=1;2:f3=4;3:f3=5;4:f3=6;5:f3=7;endcase
            emit(b((n<77)?8:4,rs2,rs1,f3));
          end
          13:emit(j((n<77)?8:4,rd));
          14:emit(ri((p+1)*4,0,0,rd,103)); // JALR to sequential PC, arbitrary link destination
          15:emit(ri(1,rs1,0,rd));
        endcase
      end
      run_program();
    end
    // Reset must squash a pending store before its RAM write edge.
    fresh("reset squashes pending store");dut.System_Memory.ram[128]=32'h11223344;
    emit(ri(7,0,0,1));emit(s(512,1,0,2));reset=0;
    for(integer n=0;n<20 && !dut.bus_we;n++)@(negedge clk);
    check("store reached memory stage",{31'd0,dut.bus_we},1);
    reset=1;repeat(3)@(negedge clk);
    check("reset suppresses memory write",dut.System_Memory.ram[128],32'h11223344);
    for(integer k=0;k<32;k++)check($sformatf("reset x%0d",k),dut.RISCV_Core.register_file.CPU_reg[k],0);
    $display("REFERENCE PASS: %0d programs, %0d compared instructions, %0d checks",programs,commits,checks);
    $finish;
  end
endmodule
