`timescale 1ns/1ps
module cpu_regression;
  reg clk=0, reset=1;
  always #5 clk=~clk;
  main dut(.clk(clk), .reset(reset));
  integer checks=0, failures=0;
  integer p, i, f, variant;
  reg [31:0] a,b,expected,seed=32'h12345678;
  string names[0:9];

  function automatic [31:0] enc_i(input integer imm,rs1,f3,rd,op=19);
    enc_i=((imm & 4095)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op;
  endfunction
  function automatic [31:0] enc_r(input integer f7,rs2,rs1,f3,rd);
    enc_r=(f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|51;
  endfunction
  function automatic [31:0] enc_s(input integer imm,rs2,rs1,f3);
    enc_s=(((imm>>5)&127)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&31)<<7)|35;
  endfunction
  function automatic [31:0] enc_b(input integer imm,rs2,rs1,f3);
    enc_b=(((imm>>12)&1)<<31)|(((imm>>5)&63)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((imm>>1)&15)<<8)|(((imm>>11)&1)<<7)|99;
  endfunction
  function automatic [31:0] enc_j(input integer imm,rd);
    enc_j=(((imm>>20)&1)<<31)|(((imm>>1)&1023)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&255)<<12)|(rd<<7)|111;
  endfunction
  function automatic [31:0] alu_ref(input integer op,input reg [31:0] x,y);
    case(op)
      0:alu_ref=x+y; 1:alu_ref=x-y; 2:alu_ref=x<<y[4:0];
      3:alu_ref={31'b0,($signed(x)<$signed(y))}; 4:alu_ref={31'b0,(x<y)};
      5:alu_ref=x^y; 6:alu_ref=x>>y[4:0]; 7:alu_ref=$signed(x)>>>y[4:0];
      8:alu_ref=x|y; 9:alu_ref=x&y;
    endcase
  endfunction
  function automatic integer funct(input integer op);
    case(op)
      0,1:funct=0; 2:funct=1; 3:funct=2; 4:funct=3; 5:funct=4;
      6,7:funct=5; 8:funct=6; 9:funct=7;
    endcase
  endfunction
  function automatic [31:0] rng(input [31:0] s);
    reg [31:0] t;
    begin t=s^(s<<13); t=t^(t>>17); rng=t^(t<<5); end
  endfunction
  task automatic fresh;
    @(negedge clk); reset=1;
    repeat(3) @(negedge clk);
    for(integer k=0;k<256;k=k+1) dut.System_Memory.ram[k]=32'h00000013;
    p=1; // First word is NOP: avoids duplicate fetch while reset is asserted.
  endtask
  task automatic emit(input [31:0] insn);
    dut.System_Memory.ram[p]=insn; p=p+1;
  endtask
  task automatic constant(input integer rd,input [31:0] value);
    reg [31:0] upper;
    begin
      upper=(value+32'h800)&32'hfffff000;
      emit(upper|(rd<<7)|55);
      emit(enc_i(integer'(value),rd,0,rd));
    end
  endtask
  task automatic run_cpu(input integer cycles=35);
    reset=0;
    repeat(cycles) @(negedge clk);
  endtask
  task automatic check(input string label,input [31:0] actual,want);
    checks++;
    if(actual!==want) begin
      failures++;
      $display("FAIL %s: got=%08x expected=%08x",label,actual,want);
    end
  endtask
  task automatic regcheck(input string label,input integer rd,input [31:0] want);
    check(label,dut.RISCV_Core.register_file.CPU_reg[rd],want);
  endtask

  initial begin
    if($test$plusargs("trace")) begin $dumpfile("tests/build/cpu.vcd"); $dumpvars(0,cpu_regression); end
    names[0]="ADD"; names[1]="SUB"; names[2]="SLL"; names[3]="SLT";
    names[4]="SLTU"; names[5]="XOR"; names[6]="SRL"; names[7]="SRA";
    names[8]="OR"; names[9]="AND";
    // Every register ALU instruction: directed boundaries plus deterministic random operands.
    for(integer op=0;op<10;op++) begin
      for(integer n=0;n<24;n++) begin
        seed=rng(seed); a=seed; seed=rng(seed); b=seed;
        case(n)
          0:begin a=0;b=0;end
          1:begin a=32'h80000000;b=31;end
          2:begin a=32'hffffffff;b=1;end
          3:begin a=32'h7fffffff;b=32'hffffffff;end
          4:begin a=32'h80000000;b=32'h7fffffff;end
          5:begin a=32'hffffffff;b=32;end
        endcase
        fresh(); constant(1,a); constant(2,b);
        emit(enc_r((op==1||op==7)?32:0,2,1,funct(op),3));
        run_cpu(); regcheck($sformatf("%s vector %0d",names[op],n),3,alu_ref(op,a,b));
      end
    end
    $display("ALU register checks complete: %0d failures / %0d checks",failures,checks);
    for(integer op=0;op<10;op++) if(op!=1) begin
      for(integer n=0;n<12;n++) begin
        seed=rng(seed); a=seed; seed=rng(seed); b={{20{seed[11]}},seed[11:0]};
        if(op==2||op==6||op==7) b=b&31;
        fresh(); constant(1,a);
        emit(enc_i(integer'(b)|((op==7)?1024:0),1,funct(op),3));
        run_cpu(); regcheck($sformatf("%s immediate %0d",names[op],n),3,alu_ref(op,a,b));
      end
    end
    fresh(); emit(enc_i(99,0,0,0)); emit(enc_i(7,0,0,1));
    emit(enc_i(2,1,0,1)); emit(enc_r(0,1,1,0,2));
    emit(enc_i(0,0,0,0)); emit(enc_r(0,1,2,0,3));
    run_cpu(); regcheck("x0 hardwired zero",0,0); regcheck("forwarding newest value",2,18); regcheck("WB forwarding",3,27);
    fresh(); emit(32'habcde1b7); emit(32'h00001197);
    run_cpu(); regcheck("AUIPC at PC=8",3,32'h1008);
    // AUIPC immediate bits overlap rs1; should never cause operand forwarding.
    fresh(); emit(enc_i(7,0,0,1)); emit(32'h00008197);
    run_cpu(); regcheck("AUIPC ignores false rs1 dependency",3,32'h8008);
    fresh(); emit(32'habcde1b7); run_cpu(); regcheck("LUI",3,32'habcde000);

    // Load extension and byte lanes, with known data independent of stores.
    for(integer typ=0;typ<6;typ++) if(typ!=3) begin
      for(integer off=0;off<4;off++) if(typ==0||typ==4||((typ==1||typ==5)&&(off%2==0))||(typ==2&&off==0)) begin
        fresh(); dut.System_Memory.ram[128]=32'h80ff7f81;
        emit(enc_i(512+off,0,typ,3,3));
        b=32'h80ff7f81>>(off*8);
        case(typ)
          0:expected={{24{b[7]}},b[7:0]}; 1:expected={{16{b[15]}},b[15:0]};
          2:expected=b; 4:expected={24'b0,b[7:0]}; 5:expected={16'b0,b[15:0]};
        endcase
        run_cpu(); regcheck($sformatf("load funct3=%0d offset=%0d",typ,off),3,expected);
      end
    end
    // Store all valid lanes at four consecutive word addresses.
    for(integer typ=0;typ<3;typ++) begin
      for(integer wordno=0;wordno<4;wordno++) begin
        for(integer off=0;off<4;off++) if(typ==0||(typ==1&&off%2==0)||(typ==2&&off==0)) begin
          fresh(); dut.System_Memory.ram[128+wordno]=32'h11223344;
          constant(1,32'ha1b2c3d4); emit(enc_s(512+4*wordno+off,1,0,typ));
          case(typ)
            0:expected=(32'h11223344&~(32'hff<<(off*8)))|(32'hd4<<(off*8));
            1:expected=(32'h11223344&~(32'hffff<<(off*8)))|(32'hc3d4<<(off*8));
            2:expected=32'ha1b2c3d4;
          endcase
          run_cpu(); check($sformatf("store size=%0d word=%0d offset=%0d",typ,wordno,off),dut.System_Memory.ram[128+wordno],expected);
        end
      end
    end
    fresh(); dut.System_Memory.ram[128]=41;
    emit(enc_i(512,0,2,1,3)); emit(enc_i(1,1,0,2));
    run_cpu(); regcheck("load-use immediate dependency",2,42);
    fresh(); dut.System_Memory.ram[128]=32'h12345678; dut.System_Memory.ram[132]=0;
    emit(enc_i(512,0,2,1,3)); emit(enc_s(528,1,0,2));
    run_cpu(); check("load-to-store dependency",dut.System_Memory.ram[132],32'h12345678);

    // Each branch both taken and not taken; wrong-path register/store must be flushed.
    for(integer typ=0;typ<8;typ++) if(typ!=2&&typ!=3) begin
      for(integer taken=0;taken<2;taken++) begin
        fresh();
        case(typ)
          0:begin a=7;b=taken?7:8;end
          1:begin a=7;b=taken?8:7;end
          4:begin a=taken?32'hffffffff:7;b=1;end
          5:begin a=taken?7:32'hffffffff;b=1;end
          6:begin a=taken?1:32'hffffffff;b=7;end
          7:begin a=taken?32'hffffffff:1;b=7;end
        endcase
        constant(1,a); constant(2,b); emit(enc_b(12,2,1,typ));
        emit(enc_i(99,0,0,3)); emit(enc_s(528,2,0,2)); emit(enc_i(11,0,0,4));
        dut.System_Memory.ram[132]=0;
        run_cpu(); regcheck($sformatf("branch %0d taken=%0d flush",typ,taken),3,taken?0:99);
        regcheck($sformatf("branch %0d taken=%0d target",typ,taken),4,11);
        check($sformatf("branch %0d taken=%0d store flush",typ,taken),dut.System_Memory.ram[132],taken?0:b);
      end
    end
    fresh(); emit(enc_i(3,0,0,1)); emit(enc_i(-1,1,0,1)); emit(enc_b(-4,0,1,1)); emit(enc_i(22,0,0,3));
    run_cpu(); regcheck("backward branch loop",1,0); regcheck("backward branch exit",3,22);
    fresh(); emit(enc_j(12,1)); emit(enc_i(99,0,0,3)); emit(enc_i(99,0,0,4)); emit(enc_i(7,0,0,5));
    run_cpu(); regcheck("JAL link PC+4",1,8); regcheck("JAL flush",3,0); regcheck("JAL target",5,7);
    fresh(); emit(enc_i(20,0,0,1)); emit(enc_i(0,1,0,2,103)); emit(enc_i(99,0,0,3)); emit(enc_i(99,0,0,4)); emit(enc_i(7,0,0,5));
    run_cpu(); regcheck("JALR link PC+4",2,12); regcheck("JALR flush",3,0); regcheck("JALR target",5,7);
    // Load stall must preserve the decoded instruction's PC.
    fresh(); dut.System_Memory.ram[128]=1;
    emit(enc_i(512,0,2,1,3)); emit(enc_b(12,1,1,0)); emit(enc_i(99,0,0,3)); emit(enc_i(99,0,0,4)); emit(enc_i(7,0,0,5));
    run_cpu(); regcheck("load-to-branch target after stall",5,7);
    fresh(); emit(enc_i(21,0,0,1)); emit(enc_i(0,1,0,2,103));
    reset=0;
    // Observe the actual redirect, since the word-index fetch port hides bit 0.
    for(integer n=0;n<10;n++) begin
      if(dut.RISCV_Core.ex_jump_back) begin
        @(negedge clk);
        check("JALR clears target bit zero",dut.RISCV_Core.program_counter.count_reg,20);
        break;
      end
      @(negedge clk);
      if(n==9) check("JALR redirect timeout",0,1);
    end
    fresh();
    dut.System_Memory.ram[0]=enc_i(1,1,0,1);
    // Hold reset with the first instruction installed, as at normal startup.
    repeat(3) @(negedge clk);
    run_cpu(); regcheck("first instruction executes once after reset",1,1);
    $display("RESULT: %0d checks, %0d passed, %0d failed",checks,checks-failures,failures);
    if(failures) $fatal(1,"CPU regression failed");
    $finish;
  end
endmodule
