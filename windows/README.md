# KPRCAS Wi-Fi Auto-Login (Windows)

A lightweight, zero-browser background tool for Windows that automatically authenticates through the `KPRCAS_Students` captive portal and prevents the 5-minute idle disconnection timeout.

---

## Files in this Folder

| File | Purpose |
| :--- | :--- |
| **`autologin.ps1`** | Main PowerShell script that tests connectivity, submits login credentials, and sends keep-alive heartbeats every 15s. |
| **`run_hidden.vbs`** | Silent VBScript launcher that prevents a black PowerShell console window from flashing on screen. |
| **`install.bat`** | 1-click setup script that copies files to `C:\Scripts\KPRCAS-Autologin` and creates the startup Task Scheduler job. |
| **`uninstall.bat`** | 1-click cleanup script that deletes the scheduled task and removes all installed files. |

---

## Quick Setup (1-Click)

1. Connect to the **`KPRCAS_Students`** Wi-Fi network and check **"Connect automatically"**.
2. Right-click **`install.bat`** and select **Run as administrator**.
3. Press any key when prompted.

The script is now installed and running silently in the background. It will automatically start whenever your laptop boots, wakes from sleep, or connects to the college Wi-Fi.

---

## Prevent 5-Minute Disconnects (Important)

Windows powers off wireless adapters when idle by default. Turn this off to prevent sudden Wi-Fi drops:

1. Press `Win + X` and select **Device Manager**.
2. Expand **Network adapters**.
3. Right-click your Wi-Fi adapter (e.g., *Intel Wi-Fi*, *Realtek Wireless*) and select **Properties**.
4. Go to the **Power Management** tab *(if available)*.
5. **Uncheck** `Allow the computer to turn off this device to save power`.
6. Click **OK**.

---

## How to Verify It's Running

- **Task Manager:** Press `Ctrl + Shift + Esc`. Look under **Background processes** for `Windows PowerShell`.
- **Task Scheduler:** Press `Win + R`, type `taskschd.msc`, click **Task Scheduler Library**, and verify **`KPRCAS_AutoLogin`** shows status **Running**.

---

## Uninstallation

To completely remove the background task and delete the script files:

1. Right-click **`uninstall.bat`** and select **Run as administrator**.
2. Press any key to confirm removal.