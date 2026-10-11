@echo off
setlocal
cd /d "%~dp0"
call toolchain.cmd
if errorlevel 1 exit /b 1
if not exist build mkdir build
if errorlevel 1 exit /b 1
"%PYTHON_EXECUTABLE%" generate_program.py
if errorlevel 1 exit /b 1
yosys -l build/synthesis.log -s build.ys
if errorlevel 1 exit /b 1
nextpnr-himbaechel --log build/place_route.log --json build/cpu_ram_led.json --write build/cpu_ram_led_pnr.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=tangnano20k.cst --freq 27
if errorlevel 1 exit /b 1
gowin_pack -d GW2A-18C -o build/cpu_ram_led.fs build/cpu_ram_led_pnr.json
if errorlevel 1 exit /b 1
echo Bitstream ready: %~dp0build\cpu_ram_led.fs
exit /b 0
