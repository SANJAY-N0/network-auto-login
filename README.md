# KPRCAS Wi-Fi Auto-Login & Keep-Alive Daemon

A zero-browser, automated background solution for **Linux** and **Windows** that handles captive portal authentication for the `KPRCAS_Students` campus Wi-Fi network. It authenticates via direct HTTP POST requests in milliseconds, prevents the 5-minute idle disconnection timeout using heartbeat pings, and automatically reconnects upon system boot or lid-open wake events.

---

## Features

- **Zero-Browser Login:** Uses native HTTP requests (`curl` on Linux, `Invoke-WebRequest` on Windows) to log in instantly without launching Chrome or Firefox.
- **5-Minute Timeout Fix:** Continuously sends status heartbeats (`/submit/status_login.php`) to keep the gateway session active.
- **Wake-on-Open Auto-Login:** Re-authenticates immediately when you open your laptop lid or wake from sleep.
- **Self-Healing Connection:** Detects internet drops, power-cycles the Wi-Fi interface if blocked, and re-authenticates automatically.
- **Hardware Power-Saving Fix:** Disables aggressive Wi-Fi sleep states on both OS platforms to eliminate connection drops.
- **True Background Daemon:** Operates completely invisibly with zero popups or open terminal windows.

---

## Repository Structure

```text
kprcas-auto-login/
├── linux/
│   ├── config/
│   │   └── disable-powersave.conf    # NetworkManager Wi-Fi stability fix
│   ├── scripts/
│   │   └── kprcas_autologin.sh       # Linux core login & keep-alive daemon
│   ├── systemd/
│   │   └── kprcas-autologin.service  # Systemd user service definition
│   ├── install.sh                    # 1-command Linux installer
│   ├── uninstall.sh                  # Complete Linux removal script
│   └── README.md                     # Linux-specific documentation
│
├── windows/
│   ├── autologin.ps1                 # Windows PowerShell daemon script
│   ├── run_hidden.vbs                # Silent VBS launcher (suppresses console)
│   ├── install.bat                   # 1-click Windows installer (Task Scheduler)
│   ├── uninstall.bat                 # 1-click Windows cleanup script
│   └── README.md                     # Windows-specific documentation
│
├── .gitignore
└── README.md                         # Main repository documentation
```

---

## Quick Start

### For Linux Users

1. Open your terminal and navigate to the `linux` folder:
   ```bash
   cd linux
   ```
2. Make the scripts executable and run the installer:
   ```bash
   chmod +x install.sh uninstall.sh
   ./install.sh
   ```
3. Check daemon status:
   ```bash
   systemctl --user status kprcas-autologin.service
   ```

*(To uninstall on Linux, simply run `./uninstall.sh`)*

---

### For Windows Users

1. Connect to the **`KPRCAS_Students`** Wi-Fi and verify **"Connect automatically"** is checked.
2. Open the `windows/` folder in File Explorer.
3. Right-click **`install.bat`** and select **Run as administrator**.
4. Press any key to complete the installation.

*(To uninstall on Windows, right-click `uninstall.bat` and select **Run as administrator**)*

---

## How It Works

```text
                  +-----------------------------------+
                  |  Laptop Opens Lid / System Boots  |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  | Auto-Connects to KPRCAS_Students  |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  | Background Daemon Checks Internet |
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
    | Send Direct POST Login Request|   | Send Heartbeat Ping   |
    |  to /submit/user_login.php    |   | (/submit/status_login)|
    +---------------+---------------+   +-----------+-----------+
                    |                               |
                    v                               v
    +---------------+---------------+   +-----------+-----------+
    |   Internet Gateway Unlocked   |   | Session Kept Active   |
    +-------------------------------+   +-----------------------+
```

1. **Association:** Your device automatically connects to `KPRCAS_Students` with elevated priority.
2. **Ping Verification:** The background service checks internet access by pinging `1.1.1.1`.
3. **If Blocked:** The script sends a direct POST payload with login credentials to `http://172.168.64.1:2280/submit/user_login.php`, authenticating the hardware MAC address at the router firewall.
4. **If Connected:** The script sends a heartbeat to `http://172.168.64.1:2280/submit/status_login.php`, resetting the gateway's 5-minute inactivity timer.

---

## Essential: Preventing 5-Minute Wi-Fi Drops

Campus routers often disconnect devices when the wireless adapter enters low-power sleep modes:

- **Linux:** Automatically handled by `linux/install.sh` by configuring `/etc/NetworkManager/conf.d/disable-powersave.conf` (`wifi.powersave = 2`).
- **Windows:** 
  1. Press `Win + X` $\rightarrow$ **Device Manager**.
  2. Expand **Network adapters** $\rightarrow$ Right-click your Wi-Fi device $\rightarrow$ **Properties**.
  3. Under the **Power Management** tab, uncheck **"Allow the computer to turn off this device to save power"** and click **OK**.

---

## Security Notice

The automation scripts contain preconfigured authentication parameters. Ensure that your local files have restricted permissions (`chmod 700` on Linux) and avoid pushing personal account passwords to public git repositories.

---

## License

This project is licensed under the MIT License.
