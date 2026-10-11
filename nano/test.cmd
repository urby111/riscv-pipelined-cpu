@echo off
setlocal
cd /d "%~dp0"
call toolchain.cmd
if errorlevel 1 exit /b 1
if not exist build mkdir build
if errorlevel 1 exit /b 1
"%PYTHON_EXECUTABLE%" generate_program.py
if errorlevel 1 exit /b 1
iverilog -g2012 -s nano_cpu_tb -o build/nano_cpu_tb.vvp -c sources.f tests/nano_cpu_tb.sv
if errorlevel 1 exit /b 1
vvp build/nano_cpu_tb.vvp
exit /b %errorlevel%
