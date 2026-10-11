@echo off
rem Override OSS_CAD_SUITE if you install the suite elsewhere.
if not defined OSS_CAD_SUITE (
    echo Set OSS_CAD_SUITE to your extracted OSS CAD Suite folder.
    exit /b 1
)
if not exist "%OSS_CAD_SUITE%\environment.bat" (
    echo Set OSS_CAD_SUITE to your extracted OSS CAD Suite folder.
    exit /b 1
)
set "YOSYSHQ_ROOT=%OSS_CAD_SUITE%\"
call "%OSS_CAD_SUITE%\environment.bat"
exit /b %errorlevel%
