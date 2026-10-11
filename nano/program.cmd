@echo off
setlocal
cd /d "%~dp0"
call toolchain.cmd
if errorlevel 1 exit /b 1
if not exist build\cpu_ram_led.fs (
    echo Run build.cmd first.
    exit /b 1
)
rem SRAM upload only. This does not replace the design stored in flash.
echo Loading CPU RAM LED design: %~dp0build\cpu_ram_led.fs
openFPGALoader -b tangnano20k build/cpu_ram_led.fs
if errorlevel 1 exit /b %errorlevel%
echo Expected LEDs: LED1, LED3, LED5 steadily on; LED0, LED2, LED4 off.
exit /b 0
