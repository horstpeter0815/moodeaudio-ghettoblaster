#!/bin/bash
################################################################################
# FIND PI ON LAN
# Scans the local network to find the Raspberry Pi
################################################################################

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[SCAN]${NC} Suche Pi im LAN..."
echo ""

# Get local network range
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "192.168.178.1")
NETWORK=$(echo "$LOCAL_IP" | cut -d. -f1-3)

echo -e "${BLUE}[INFO]${NC} Netzwerk: ${NETWORK}.0/24"
echo -e "${BLUE}[INFO]${NC} Scanne nach Raspberry Pi..."
echo ""

# Try common IPs first (faster)
COMMON_IPS=("${NETWORK}.134" "${NETWORK}.161" "${NETWORK}.162" "${NETWORK}.143")

for ip in "${COMMON_IPS[@]}"; do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        # Check if it's a Pi (SSH on port 22)
        if nc -z -G 1 "$ip" 22 2>/dev/null; then
            echo -e "${GREEN}[FOUND]${NC} Pi gefunden: $ip"
            echo ""
            echo "Verwende:"
            echo "  ./SETUP_MOODE_PI5.sh $ip"
            exit 0
        fi
    fi
done

# If not found in common IPs, scan the network
echo -e "${YELLOW}[SCAN]${NC} Erweiterte Suche..."
echo ""

# Try nmap if available
if command -v nmap &> /dev/null; then
    echo "Scanne mit nmap..."
    nmap -sn "${NETWORK}.0/24" 2>/dev/null | grep -E "Nmap scan report|Raspberry" | while read line; do
        if echo "$line" | grep -q "Nmap scan report"; then
            IP=$(echo "$line" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
            if [ -n "$IP" ] && nc -z -G 1 "$IP" 22 2>/dev/null; then
                echo -e "${GREEN}[FOUND]${NC} Pi gefunden: $IP"
                echo ""
                echo "Verwende:"
                echo "  ./SETUP_MOODE_PI5.sh $IP"
                exit 0
            fi
        fi
    done
fi

# Fallback: manual ping scan
echo "Manuelle Suche..."
for i in {1..254}; do
    ip="${NETWORK}.$i"
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        if nc -z -G 1 "$ip" 22 2>/dev/null; then
            echo -e "${GREEN}[FOUND]${NC} Pi gefunden: $ip"
            echo ""
            echo "Verwende:"
            echo "  ./SETUP_MOODE_PI5.sh $ip"
            exit 0
        fi
    fi
    if [ $((i % 50)) -eq 0 ]; then
        echo -n "."
    fi
done

echo ""
echo -e "${YELLOW}[WARN]${NC} Pi nicht gefunden. Prüfe:"
echo "  1. Ist der Pi per LAN-Kabel verbunden?"
echo "  2. Ist der Pi gebootet?"
echo "  3. Versuche manuell: ping ${NETWORK}.XXX"
exit 1

