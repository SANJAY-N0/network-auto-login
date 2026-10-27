Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -File ""C:\Scripts\KPRCAS-Autologin\autologin.ps1""", 0, False