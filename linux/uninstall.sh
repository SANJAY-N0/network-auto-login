#!/bin/bash
set -e

echo "[+] Removing KPRCAS Auto-Login Daemon..."

# Stop and disable systemd service
systemctl --user stop kprcas-autologin.service 2>/dev/null || true
systemctl --user disable kprcas-autologin.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/kprcas-autologin.service"
systemctl --user daemon-reload

# Remove script
rm -f "$HOME/scripts/kprcas_autologin.sh"

# Remove power-save config
if [ -f "/etc/NetworkManager/conf.d/disable-powersave.conf" ]; then
    echo "[+] Removing power-save override (requires sudo password)..."
    sudo rm -f /etc/NetworkManager/conf.d/disable-powersave.conf
    sudo systemctl restart NetworkManager
fi

echo "[✓] Uninstalled successfully."