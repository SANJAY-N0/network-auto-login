#!/bin/bash
set -e

echo "[+] Installing KPRCAS Auto-Login Daemon..."

# 1. Create target directories
mkdir -p "$HOME/scripts"
mkdir -p "$HOME/.config/systemd/user"

# 2. Copy scripts and service files
cp scripts/kprcas_autologin.sh "$HOME/scripts/kprcas_autologin.sh"
chmod +x "$HOME/scripts/kprcas_autologin.sh"

cp systemd/kprcas-autologin.service "$HOME/.config/systemd/user/kprcas-autologin.service"

# 3. Apply Wi-Fi power-save fix (requires sudo)
if [ -f "config/disable-powersave.conf" ]; then
    echo "[+] Applying Wi-Fi power-saving fix (requires sudo password)..."
    sudo cp config/disable-powersave.conf /etc/NetworkManager/conf.d/disable-powersave.conf
    sudo systemctl restart NetworkManager
fi

# 4. Set Wi-Fi auto-connect priority
if nmcli connection show "KPRCAS_Students" > /dev/null 2>&1; then
    echo "[+] Setting KPRCAS_Students autoconnect priority to 100..."
    nmcli connection modify "KPRCAS_Students" connection.autoconnect yes connection.autoconnect-priority 100
fi

# 5. Enable and start systemd daemon
echo "[+] Reloading and starting background service..."
systemctl --user daemon-reload
systemctl --user enable --now kprcas-autologin.service

echo "[✓] Installation complete! The daemon is running in the background."