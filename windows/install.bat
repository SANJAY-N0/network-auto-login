@echo off
setlocal EnableDelayedExpansion

echo [*] Installing KPRCAS Wi-Fi Auto-Login for Windows...

:: Check Administrator Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ERROR: Please right-click install.bat and select 'Run as administrator'.
    pause
    exit /b 1
)

:: Destination Directory
set "TARGET_DIR=C:\Scripts\KPRCAS-Autologin"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

:: Copy Files
copy /Y "%~dp0autologin.ps1" "%TARGET_DIR%\" >nul
copy /Y "%~dp0run_hidden.vbs" "%TARGET_DIR%\" >nul

:: Create Scheduled Task (Runs on Logon with Highest Privileges)
schtasks /create /tn "KPRCAS_AutoLogin" /tr "wscript.exe \"%TARGET_DIR%\run_hidden.vbs\"" /sc onlogon /rl highest /f >nul

:: Start the task immediately
schtasks /run /tn "KPRCAS_AutoLogin" >nul

echo [✓] Successfully installed!
echo [✓] The script is now running silently in the background and will start on every boot.
pause