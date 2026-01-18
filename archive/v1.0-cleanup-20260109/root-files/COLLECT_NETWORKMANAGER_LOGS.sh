#!/bin/bash
# Collect NetworkManager Runtime Evidence from Pi
# Sammelt alle Runtime-Logs für NetworkManager-wait-online Problem

set -e

LOG_FILE="/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log"
PI_IP="192.168.10.2"

log_to_file() {
    local hypothesis_id="$1"
    local message="$2"
    local data="$3"
    echo "{\"id\":\"log_$(date +%s%N)\",\"timestamp\":$(date +%s%N | cut -b1-13),\"location\":\"COLLECT_NETWORKMANAGER_LOGS.sh:$(caller 0 | awk '{print $1}')\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"$hypothesis_id\"}" >> "$LOG_FILE"
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 COLLECT NETWORKMANAGER RUNTIME EVIDENCE                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Pi online ist
if ! ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi ist nicht online unter $PI_IP"
    echo "   Bitte Pi booten und warten bis er online ist."
    exit 1
fi
echo "✅ Pi ist online unter $PI_IP"
log_to_file "N/A" "Pi is online" "{\"ip\":\"$PI_IP\"}"

# Hypothese A: Netplan renderer Konflikt
echo "📋 Hypothese A: Netplan renderer: networkd vs NetworkManager Konflikt"
log_to_file "A" "Checking Netplan config" "{}"
NETPLAN_CONFIG=$(ssh andre@"$PI_IP" 'cat /etc/netplan/*.yaml 2>/dev/null || echo "No Netplan config"' 2>/dev/null)
log_to_file "A" "Netplan config" "{\"config\":\"$(echo "$NETPLAN_CONFIG" | tr -d '\n' | sed 's/"/\\"/g')\"}"
echo "   Netplan Config:"
echo "$NETPLAN_CONFIG" | head -10
echo ""

# Hypothese B: systemd-networkd vs NetworkManager Konflikt
echo "📋 Hypothese B: systemd-networkd läuft parallel zu NetworkManager"
log_to_file "B" "Checking systemd-networkd status" "{}"
SN_STATUS=$(ssh andre@"$PI_IP" 'systemctl status systemd-networkd.service --no-pager 2>&1 | head -10' 2>/dev/null)
log_to_file "B" "systemd-networkd status" "{\"status\":\"$(echo "$SN_STATUS" | tr -d '\n' | sed 's/"/\\"/g')\"}"

log_to_file "B" "Checking NetworkManager status" "{}"
NM_STATUS=$(ssh andre@"$PI_IP" 'systemctl status NetworkManager.service --no-pager 2>&1 | head -10' 2>/dev/null)
log_to_file "B" "NetworkManager status" "{\"status\":\"$(echo "$NM_STATUS" | tr -d '\n' | sed 's/"/\\"/g')\"}"

log_to_file "B" "Checking which services are active" "{}"
ACTIVE_NETWORK=$(ssh andre@"$PI_IP" 'systemctl is-active systemd-networkd NetworkManager 2>&1' 2>/dev/null)
log_to_file "B" "Active network services" "{\"services\":\"$(echo "$ACTIVE_NETWORK" | tr -d '\n' | sed 's/"/\\"/g')\"}"
echo "   systemd-networkd: $(echo "$ACTIVE_NETWORK" | head -1)"
echo "   NetworkManager: $(echo "$ACTIVE_NETWORK" | tail -1)"
echo ""

# Hypothese C: IP-Adresse nicht korrekt gesetzt
echo "📋 Hypothese C: IP-Adresse 192.168.10.2 nicht korrekt gesetzt"
log_to_file "C" "Checking IP address" "{}"
IP_ADDR=$(ssh andre@"$PI_IP" 'ip addr show eth0 2>/dev/null | grep "inet " || echo "No IP"' 2>/dev/null)
log_to_file "C" "IP address" "{\"ip\":\"$(echo "$IP_ADDR" | tr -d '\n' | sed 's/"/\\"/g')\"}"

log_to_file "C" "Checking route" "{}"
ROUTE=$(ssh andre@"$PI_IP" 'ip route show 2>/dev/null | head -5' 2>/dev/null)
log_to_file "C" "Route" "{\"route\":\"$(echo "$ROUTE" | tr -d '\n' | sed 's/"/\\"/g')\"}"
echo "   eth0 IP: $IP_ADDR"
echo "   Route: $(echo "$ROUTE" | head -1)"
echo ""

# Hypothese D: NetworkManager wartet auf Interface das nicht existiert
echo "📋 Hypothese D: NetworkManager wartet auf Interface das nicht existiert"
log_to_file "D" "Checking available interfaces" "{}"
INTERFACES=$(ssh andre@"$PI_IP" 'ip link show | grep -E "^[0-9]+:" | awk "{print \$2}" | sed "s/://"' 2>/dev/null)
log_to_file "D" "Available interfaces" "{\"interfaces\":\"$(echo "$INTERFACES" | tr '\n' ' ' | sed 's/"/\\"/g')\"}"

log_to_file "D" "Checking NetworkManager device status" "{}"
NM_DEVICES=$(ssh andre@"$PI_IP" 'nmcli device status 2>/dev/null || echo "nmcli not available"' 2>/dev/null)
log_to_file "D" "NetworkManager devices" "{\"devices\":\"$(echo "$NM_DEVICES" | tr -d '\n' | sed 's/"/\\"/g')\"}"
echo "   Interfaces: $(echo "$INTERFACES" | tr '\n' ' ')"
echo "   NetworkManager Devices:"
echo "$NM_DEVICES" | head -5
echo ""

# Hypothese E: NetworkManager-wait-online Service Logs
echo "📋 Hypothese E: NetworkManager-wait-online Service Logs"
log_to_file "E" "Checking NetworkManager-wait-online status" "{}"
NM_WAIT_STATUS=$(ssh andre@"$PI_IP" 'systemctl status NetworkManager-wait-online.service --no-pager 2>&1 | head -20' 2>/dev/null)
log_to_file "E" "NetworkManager-wait-online status" "{\"status\":\"$(echo "$NM_WAIT_STATUS" | tr -d '\n' | sed 's/"/\\"/g')\"}"

log_to_file "E" "Checking NetworkManager-wait-online journal" "{}"
NM_WAIT_JOURNAL=$(ssh andre@"$PI_IP" 'journalctl -u NetworkManager-wait-online.service --no-pager -n 30 2>&1' 2>/dev/null)
log_to_file "E" "NetworkManager-wait-online journal" "{\"journal\":\"$(echo "$NM_WAIT_JOURNAL" | tr -d '\n' | sed 's/"/\\"/g')\"}"
echo "   NetworkManager-wait-online Status:"
echo "$NM_WAIT_STATUS" | head -15
echo ""

# Zusätzlich: network-guaranteed.service Logs
echo "📋 Zusätzlich: network-guaranteed.service Logs"
log_to_file "N/A" "Checking network-guaranteed service" "{}"
NG_STATUS=$(ssh andre@"$PI_IP" 'systemctl status network-guaranteed.service --no-pager 2>&1 | head -15' 2>/dev/null)
log_to_file "N/A" "network-guaranteed status" "{\"status\":\"$(echo "$NG_STATUS" | tr -d '\n' | sed 's/"/\\"/g')\"}"

log_to_file "N/A" "Checking network-guaranteed journal" "{}"
NG_JOURNAL=$(ssh andre@"$PI_IP" 'journalctl -u network-guaranteed.service --no-pager -n 20 2>&1' 2>/dev/null)
log_to_file "N/A" "network-guaranteed journal" "{\"journal\":\"$(echo "$NG_JOURNAL" | tr -d '\n' | sed 's/"/\\"/g')\"}"
echo "   network-guaranteed Status:"
echo "$NG_STATUS" | head -10
echo ""

echo "✅ Runtime-Evidence gesammelt in $LOG_FILE"
echo "   Bitte Logs analysieren."
echo ""

