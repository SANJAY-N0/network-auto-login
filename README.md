# KPRCAS Wi-Fi Auto-Login & Keep-Alive Daemon

[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-blue.svg)](#)
[![Shell](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](#)

A zero-browser, automated background service for **Linux** and **Windows** that automates captive portal authentication for the `KPRCAS_Students` campus Wi-Fi network. It sends direct HTTP POST requests in milliseconds, prevents the 5-minute idle disconnection timeout via background heartbeats, and re-authenticates automatically upon boot, network reconnection, or lid-open wake events.

---

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Repository Structure](#repository-structure)
- [Quick Start & Installation](#quick-start--installation)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Linux Setup](#2-linux-setup)
  - [3. Windows Setup](#3-windows-setup)
- [Developer & Debug Mode](#developer--debug-mode)
- [Preventing 5-Minute Disconnects](#preventing-5-minute-disconnects)
- [File Breakdown](#file-breakdown)
- [Management Commands](#management-commands)
- [Uninstallation](#uninstallation)
- [Security Notice](#security-notice)
- [License](#license)

---

## Overview

Campus captive portals typically require opening a web browser, waiting for redirects, submitting credentials manually, and keeping a status popup tab open to avoid timeout drops.

This project completely bypasses the browser:
- **Zero Browser Overhead:** Directly targets the gateway endpoints (`/submit/user_login.php`) via `curl` (Linux) or `Invoke-WebRequest` (Windows).
- **Sub-Second Execution:** Authenticates the device's hardware MAC address in under 200ms.
- **Heartbeat Daemon:** Regularly hits `/submit/status_login.php` to prevent the gateway's 300-second (5-minute) idle timeout.
- **Auto-Recovery:** Detects connection failures, power-cycles the Wi-Fi link, and re-authenticates automatically.

---

## How It Works

```text
                  +-----------------------------------+
                  |  Laptop Lid Opens / System Boots  |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  | Wi-Fi Connects to KPRCAS_Students |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  | Daemon monitors connection status |
                  |     (Runs every 15 seconds)       |
                  +-----------------+-----------------+
                                    |
                                    v
                     [Ping External DNS: 1.1.1.1]
                                    |
                    +---------------+---------------+
                    |                               |
              [Ping Fails]                    [Ping Passes]
                    |                               |
                    v                               v
    +---------------+---------------+   +-----------+-----------+
    | Send Direct POST Login Req    |   | Send Heartbeat Ping   |
    |  to /submit/user_login.php    |   | (/submit/status_login)|
    +---------------+---------------+   +-----------+-----------+
                    |                               |
                    v                               v
    +---------------+---------------+   +-----------+-----------+
    | Full Internet Access Restored |   | Session Remains Alive |
    +-------------------------------+   +-----------------------+
```

---

## Repository Structure

```text
kprcas-auto-login/
├── linux/
│   ├── config/
│   │   └── disable-powersave.conf    # NetworkManager Wi-Fi stability fix
│   ├── scripts/
│   │   └── kprcas_autologin.sh       # Main Bash login & keep-alive script
│   ├── systemd/
│   │   └── kprcas-autologin.service  # Systemd user daemon unit
│   ├── install.sh                    # Linux automated installer
│   └── uninstall.sh                  # Linux uninstaller
├── windows/
│   ├── autologin.ps1                 # Main PowerShell login & keep-alive script
│   ├── run_hidden.vbs                # Silent background runner (no popups)
│   ├── install.bat                   # 1-click Windows installer (Task Scheduler)
│   └── uninstall.bat                 # 1-click Windows uninstaller
├── .gitignore                        # Git exclusion rules
└── README.md                         # Main repository documentation
```

---

## Quick Start & Installation

### 1. Clone the Repository

```bash
git clone https://github.com/SANJAY-N0/network-auto-log.git
cd network-auto-log
```

---

### 2. Linux Setup

#### Prerequisites
Ensure `curl` and `network-manager` are installed:
```bash
# Ubuntu / Debian / Mint
sudo apt update && sudo apt install -y curl network-manager

# Arch Linux
sudo pacman -S --needed curl networkmanager

# Fedora / RHEL
sudo dnf install -y curl NetworkManager
```

#### Automated Install
```bash
cd linux
chmod +x install.sh uninstall.sh scripts/kprcas_autologin.sh
./install.sh
```

The installer copies the files, applies the Wi-Fi power-save fix, sets network priority, and starts the background user daemon immediately.

---

### 3. Windows Setup

1. Open File Explorer and navigate to `network-auto-log\windows`.
2. Right-click **`install.bat`** and select **Run as administrator**.
3. Press any key when finished.

The installer creates a scheduled task (`KPRCAS_AutoLogin`) that launches the script silently on user logon using the VBS wrapper.

---

## Developer & Debug Mode

If you are developing, testing credentials, or troubleshooting network responses, you can run the scripts interactively in the foreground instead of running them as background services.

### Linux (Interactive Foreground Test)
```bash
# Run script directly from the repository
chmod +x linux/scripts/kprcas_autologin.sh
./linux/scripts/kprcas_autologin.sh
```

### Windows (Interactive Console Test)
Open PowerShell and run:
```powershell
powershell -ExecutionPolicy Bypass -NoProfile -File .\windows\autologin.ps1
```

### Customizing Credentials
To change the credentials or gateway endpoint, modify the variables at the top of the respective script:
* **Linux:** `linux/scripts/kprcas_autologin.sh`
* **Windows:** `windows/autologin.ps1`

```bash
SSID="KPRCAS_Students"
PORTAL_LOGIN="http://172.168.64.1:2280/submit/user_login.php"
PORTAL_HEARTBEAT="http://172.168.64.1:2280/submit/status_login.php"
USERNAME="CAS"
PASSWORD="your_password"
```

---

## Preventing 5-Minute Disconnects

Enterprise and campus routers drop clients when idle power-saving features disable the wireless interface.

### Linux Fix
The `install.sh` script installs `linux/config/disable-powersave.conf` to `/etc/NetworkManager/conf.d/disable-powersave.conf`:
```ini
[connection]
wifi.powersave = 2
```
*Value `2` forces the wireless hardware to remain fully active.*

### Windows Fix
1. Press `Win + X` $\rightarrow$ **Device Manager**.
2. Expand **Network adapters**.
3. Right-click your Wi-Fi adapter (e.g., *Intel Wi-Fi 6*, *Realtek*) $\rightarrow$ **Properties**.
4. Go to the **Power Management** tab *(if available)*.
5. **Uncheck** `Allow the computer to turn off this device to save power`.
6. Click **OK**.

---

## File Breakdown

| File | Target Location | Description |
| :--- | :--- | :--- |
| `linux/scripts/kprcas_autologin.sh` | `~/scripts/kprcas_autologin.sh` | Core Linux daemon script performing ping checks, `curl` logins, and heartbeat calls. |
| `linux/systemd/kprcas-autologin.service` | `~/.config/systemd/user/` | Systemd service definition running the Linux daemon automatically on boot/wake. |
| `linux/config/disable-powersave.conf` | `/etc/NetworkManager/conf.d/` | Disables Linux wireless power saving to prevent idle drops. |
| `linux/install.sh` | Local | Installs files, sets permissions, and activates the Linux systemd service. |
| `linux/uninstall.sh` | Local | Stops service and restores Linux system configuration. |
| `windows/autologin.ps1` | `C:\Scripts\KPRCAS-Autologin\` | Core PowerShell script monitoring network state and issuing web requests. |
| `windows/run_hidden.vbs` | `C:\Scripts\KPRCAS-Autologin\` | Silent launcher preventing console window popups on Windows. |
| `windows/install.bat` | Local | Registers `KPRCAS_AutoLogin` task in Windows Task Scheduler. |
| `windows/uninstall.bat` | Local | Removes Windows scheduled task and cleans up script folder. |

---

## Management Commands

### Linux Service Management
```bash
# Check service status
systemctl --user status kprcas-autologin.service

# View live real-time logs
journalctl --user-unit=kprcas-autologin.service -f

# Restart the service
systemctl --user restart kprcas-autologin.service

# Stop the service
systemctl --user stop kprcas-autologin.service
```

### Windows Task Verification
- **Task Manager:** Open `Task Manager` (`Ctrl + Shift + Esc`) $\rightarrow$ check **Background processes** for `Windows PowerShell`.
- **Task Scheduler:** Open `taskschd.msc` $\rightarrow$ click **Task Scheduler Library** $\rightarrow$ locate `KPRCAS_AutoLogin` (Status: `Running`).

---

## Uninstallation

### Linux
```bash
cd linux
./uninstall.sh
```

### Windows
1. Right-click `windows\uninstall.bat` and select **Run as administrator**.
2. Press any key when prompted.

---

## Security Notice

The configuration files contain network authentication credentials.
- Ensure your personal script files have restricted file permissions (`chmod 700`).
- If you use customized personal accounts, do not commit passwords to public Git repositories.
- Use `.gitignore` to prevent committing local logs and environment files.

---

## License

This project is open-source under the [MIT License](LICENSE).
