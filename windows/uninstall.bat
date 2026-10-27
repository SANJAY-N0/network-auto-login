@echo off
echo [*] Uninstalling KPRCAS Wi-Fi Auto-Login...

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ERROR: Please right-click uninstall.bat and select 'Run as administrator'.
    pause
    exit /b 1
)

:: Delete Scheduled Task
schtasks /delete /tn "KPRCAS_AutoLogin" /f >nul 2>&1

:: Remove Installed Files
rmdir /s /q "C:\Scripts\KPRCAS-Autologin" >nul 2>&1

echo [✓] Successfully removed.
pause