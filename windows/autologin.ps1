# Configuration
$SSID = "KPRCAS_Students"
$LOGIN_URL = "http://172.168.64.1:2280/submit/user_login.php"
$HEARTBEAT_URL = "http://172.168.64.1:2280/submit/status_login.php"
$CHECK_HOST = "1.1.1.1"

function Test-Internet {
    try {
        return (Test-Connection -ComputerName $CHECK_HOST -Count 1 -Quiet -TimeoutSeconds 2)
    } catch {
        return $false
    }
}

function Send-Login {
    $body = @{
        usrname    = "CAS"
        newpasswd  = "admin@407"
        terms      = "on"
        page_sid   = "internal"
        org_url    = "http://connectivity-check.ubuntu.com/"
        update_btn = "Login"
    }

    try {
        Invoke-WebRequest -Uri $LOGIN_URL -Method Post -Body $body -UseBasicParsing -TimeoutSec 5 | Out-Null
    } catch {
        # Suppress network exceptions during reconnect
    }
}

function Send-Heartbeat {
    try {
        Invoke-WebRequest -Uri $HEARTBEAT_URL -Method Get -UseBasicParsing -TimeoutSec 5 | Out-Null
    } catch {
        # Suppress transient errors
    }
}

while ($true) {
    # Extract active Wi-Fi SSID
    $currentSSID = ""
    $wlan = netsh wlan show interfaces
    foreach ($line in $wlan) {
        if ($line -match '^\s+SSID\s+:\s+(.+)$') {
            $currentSSID = $matches[1].Trim()
            break
        }
    }

    if ($currentSSID -eq $SSID) {
        if (-not (Test-Internet)) {
            # Internet disconnected -> Authenticate
            Send-Login
            Start-Sleep -Seconds 2

            # If still offline, bounce Wi-Fi connection and retry
            if (-not (Test-Internet)) {
                netsh wlan disconnect | Out-Null
                Start-Sleep -Seconds 1
                netsh wlan connect name="$SSID" | Out-Null
                Start-Sleep -Seconds 3
                Send-Login
            }
        } else {
            # Internet online -> Ping heartbeat to stop 5-minute disconnect
            Send-Heartbeat
        }
    }

    # Interval check
    Start-Sleep -Seconds 15
}