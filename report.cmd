@echo off
setlocal

:: 寻找系统中的 Git Bash (bash.exe)
set BASH_PATH=
for /f "tokens=*" %%i in ('where bash 2^>nul') do (
    set BASH_PATH=%%i
    goto :found
)

:found
if "%BASH_PATH%"=="" (
    echo [Error] 未检测到 Git Bash 环境！
    echo 请确认您已安装 Git for Windows，并将其添加到了系统环境变量中。
    exit /b 1
)

:: 调用 bash 环境执行 report.sh，并将所有参数透明传递
"%BASH_PATH%" "%~dp0report.sh" %*