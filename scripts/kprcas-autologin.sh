#!/bin/bash

# Configuration
SSID="KPRCAS_Students"
PORTAL_LOGIN="http://172.168.64.1:2280/submit/user_login.php"
PORTAL_HEARTBEAT="http://172.168.64.1:2280/submit/status_login.php"
CHECK_IP="1.1.1.1"

# Login function sending direct HTTP POST
login_portal() {
    curl -s -X POST "$PORTAL_LOGIN" \
      --data-urlencode "usrname=CAS" \
      --data-urlencode "newpasswd=admin@407" \
      --data-urlencode "terms=on" \
      --data-urlencode "page_sid=internal" \
      --data-urlencode "org_url=http://connectivity-check.ubuntu.com/" \
      --data-urlencode "update_btn=Login" > /dev/null 2>&1
}

while true; do
    # Check currently connected Wi-Fi SSID
    CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

    if [ "$CURRENT_SSID" = "$SSID" ]; then
        # Check if internet access is active
        if ! ping -c 1 -W 2 "$CHECK_IP" > /dev/null 2>&1; then
            # No internet -> authenticate with portal
            login_portal
            sleep 2

            # If still blocked, cycle network interface and re-authenticate
            if ! ping -c 1 -W 2 "$CHECK_IP" > /dev/null 2>&1; then
                nmcli connection down "$SSID" > /dev/null 2>&1
                nmcli connection up "$SSID" > /dev/null 2>&1
                sleep 3
                login_portal
            fi
        else
            # Internet is active -> send heartbeat to prevent 5-min captive portal timeout
            curl -s "$PORTAL_HEARTBEAT" > /dev/null 2>&1
        fi
    fi

    # Check state every 15 seconds
    sleep 15
done