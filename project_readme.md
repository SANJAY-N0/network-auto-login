# KPRCAS Wi-Fi Auto-Login & Keep-Alive Daemon

[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://www.kernel.org/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Init](https://img.shields.io/badge/Service-Systemd-blue.svg)](https://systemd.io/)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

A zero-browser, automated background daemon for Linux that manages captive portal authentication for the **KPRCAS_Students** campus network. It authenticates via direct HTTP POST requests in milliseconds, prevents the 5-minute idle disconnection timeout through status heartbeats, and re-authenticates automatically upon system boot or lid-open wake events.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [How It Works](#how-it-works)
- [Repository Structure](#repository-structure)
- [File Breakdown](#file-breakdown)
- [Prerequisites](#prerequisites)
- [Quick Start Installation](#quick-start-installation)
- [Manual Step-by-Step Setup](#manual-step-by-step-setup)
- [Verification & Monitoring](#verification--monitoring)
- [Management Commands](#management-commands)
- [Uninstallation](#uninstallation)
- [Troubleshooting](#troubleshooting)
- [Security Notice](#security-notice)

---

## Overview

Most campus captive portals require connecting via a web browser, waiting for network redirection, manually entering credentials, and keeping a status popup window open to avoid being timed out.

This project bypasses browser overhead by interacting directly with the gateway's backend endpoints using `curl` and native Linux network subsystems:
- **No Browser Required:** Avoids loading heavy web assets (HTML/CSS/JS/images).
- **Fast Execution:** Submits credentials in under 200ms.
- **Background Persistence:** Runs via a lightweight `systemd` user service consuming virtually zero CPU/RAM.

---

## Key Features

- **Instant Authentication:** Dispatches an RFC-compliant HTTP POST request directly to the authentication gateway (`/submit/user_login.php`).
- **Heartbeat Keep-Alive:** Pings the gateway's status endpoint (`/submit/status_login.php`) every 15 seconds to permanently prevent the 5-minute idle session drop.
- **Automatic Wake Recovery:** Detects network connection events and logs in immediately when opening the laptop lid or waking from suspend.
- **Failover & Self-Healing:** Verifies route status against external DNS (`1.1.1.1`). If access is denied, it cycles the Wi-Fi connection via `nmcli` and re-authenticates.
- **Hardware Stability Fix:** Disables Linux Wi-Fi power-saving mode (`wifi.powersave = 2`) to stop wireless cards from entering low-power sleep states during idle periods.

---

## How It Works

```text
                  +-----------------------------------+
                  |  Laptop Opens Lid / System Boots  |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  | NetworkManager Auto-Connects to   |
                  |         KPRCAS_Students           |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  | Systemd runs kprcas_autologin.sh  |
                  |     (Loops every 15 seconds)      |
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
    | Send Direct curl POST Login   |   | Send Heartbeat Ping   |
    |  to /submit/user_login.php    |   | (/submit/status_login)|
    +---------------+---------------+   +-----------+-----------+
                    |                               |
                    v                               v
    +---------------+---------------+   +-----------+-----------+
    | Internet Unlocked via Gateway |   | Session Remains Alive |
    +-------------------------------+   +-----------------------+
```

1. **Association:** NetworkManager connects to `KPRCAS_Students` with top priority (`autoconnect-priority 100`).
2. **Ping Test:** The script evaluates real-world internet connectivity by issuing a 1-packet ping (`ping -c 1 -W 2 1.1.1.1`).
3. **Condition A (Ping Fails):** If the ping is dropped or hijacked by the captive portal, the script fires an HTTP POST payload with user credentials. If blocked further, it cycles the Wi-Fi adapter.
4. **Condition B (Ping Passes):** If internet is reachable, the script issues a silent GET request to `/submit/status_login.php`. The gateway resets its idle disconnection timer, maintaining session stability.

---

## Repository Structure

```text
kprcas-autologin/
├── config/
│   └── disable-powersave.conf    # NetworkManager power-saving override
├── scripts/
│   └── kprcas_autologin.sh       # Main login, monitoring, and heartbeat logic
├── systemd/
│   └── kprcas-autologin.service  # Systemd user daemon definition
├── .gitignore                    # Git file exclusions
├── install.sh                    # Automated installation script
├── uninstall.sh                  # Automated cleanup & removal script
└── README.md                     # Comprehensive documentation
```

---

## File Breakdown

| File Path | Target System Location | Purpose |
| :--- | :--- | :--- |
| `config/disable-powersave.conf` | `/etc/NetworkManager/conf.d/` | Disables Linux Wi-Fi sleep states (`powersave=2`) to prevent connection dropouts. |
| `scripts/kprcas_autologin.sh` | `~/scripts/kprcas_autologin.sh` | Main executable script that runs the connectivity loop, auto-login, and heartbeat. |
| `systemd/kprcas-autologin.service` | `~/.config/systemd/user/` | Runs the script as a user daemon on boot/wake without needing root permissions. |
| `install.sh` | Local repository | One-line installer to copy files, assign permissions, and enable services. |
| `uninstall.sh` | Local repository | Reverses all changes, disables services, and removes installed files. |

---

## Prerequisites

Ensure your Linux distribution has `curl` and `NetworkManager` installed:

### Ubuntu / Debian / Linux Mint
```bash
sudo apt update && sudo apt install -y curl network-manager
```

### Arch Linux / Manjaro
```bash
sudo pacman -S --needed curl networkmanager
```

### Fedora / RHEL
```bash
sudo dnf install -y curl NetworkManager
```

---

## Quick Start Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/kprcas-autologin.git
   cd kprcas-autologin
   ```

2. **Grant execution rights and run the installer:**
   ```bash
   chmod +x install.sh uninstall.sh
   ./install.sh
   ```

3. **Verify running status:**
   ```bash
   systemctl --user status kprcas-autologin.service
   ```

---

## Manual Step-by-Step Setup

If you prefer installing the files manually instead of using `install.sh`:

### 1. Disable Wi-Fi Power-Saving Mode
```bash
sudo mkdir -p /etc/NetworkManager/conf.d/
sudo cp config/disable-powersave.conf /etc/NetworkManager/conf.d/disable-powersave.conf
sudo systemctl restart NetworkManager
```

### 2. Configure Network Auto-Connect Priority
```bash
nmcli connection modify "KPRCAS_Students" connection.autoconnect yes connection.autoconnect-priority 100
```

### 3. Install the Script
```bash
mkdir -p ~/scripts
cp scripts/kprcas_autologin.sh ~/scripts/kprcas_autologin.sh
chmod +x ~/scripts/kprcas_autologin.sh
```

### 4. Deploy and Enable the User Service
```bash
mkdir -p ~/.config/systemd/user
cp systemd/kprcas-autologin.service ~/.config/systemd/user/kprcas-autologin.service
systemctl --user daemon-reload
systemctl --user enable --now kprcas-autologin.service
```

---

## Verification & Monitoring

### Check Background Service Status
```bash
systemctl --user status kprcas-autologin.service
```
*Expected status:* `Active: active (running)`

### Stream Live Service Logs
```bash
journalctl --user-unit=kprcas-autologin.service -f
```

### Test Hardware Lid-Close / Wake
1. Disconnect or close your laptop lid.
2. Wait 10 seconds and reopen it.
3. Verify internet connectivity immediately without launching a browser:
   ```bash
   ping -c 2 google.com
   ```

---

## Management Commands

| Action | Command |
| :--- | :--- |
| **View Status** | `systemctl --user status kprcas-autologin.service` |
| **Restart Daemon** | `systemctl --user restart kprcas-autologin.service` |
| **Stop Daemon** | `systemctl --user stop kprcas-autologin.service` |
| **Disable on Boot** | `systemctl --user disable kprcas-autologin.service` |
| **Live Logs** | `journalctl --user -u kprcas-autologin.service -f` |

---

## Uninstallation

To cleanly stop the background service and remove all installed configurations:

```bash
./uninstall.sh
```

---

## Troubleshooting

### 1. Connection name casing mismatch
NetworkManager connection names are case-sensitive. Verify the active name:
```bash
nmcli connection show --active
```
If your profile appears as `KPRCAS_STUDENTS` or `kprcas_students`, update the `SSID` variable in `~/scripts/kprcas_autologin.sh` to match.

### 2. Portal IP is unreachable
Confirm your machine has received a valid IP lease from the campus router:
```bash
ip route | grep default
ping -c 2 172.168.64.1
```

### 3. Service fails to start
Check the system journal for specific error lines:
```bash
journalctl --user -xeu kprcas-autologin.service
```

---

## Security Notice

The login script (`scripts/kprcas_autologin.sh`) contains plain-text network credentials. Ensure your user account is protected with standard permissions:
```bash
chmod 700 ~/scripts/kprcas_autologin.sh
```
Avoid committing modified scripts containing personal passwords to public repositories. Add custom configuration files to `.gitignore`.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.