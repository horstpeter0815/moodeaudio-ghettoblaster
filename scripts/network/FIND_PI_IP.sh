#!/bin/bash
################################################################################
#
# Find Pi IP Address on Network
#
# Scans network to find the Pi's IP address
# Useful when Pi is on WiFi with DHCP
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIND]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

log "=== Finding Pi IP Address ==="
echo ""

# Get local network range
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
if [ -z "$LOCAL_IP" ]; then
    error "Cannot determine local IP address"
    exit 1
fi

NETWORK=$(echo "$LOCAL_IP" | cut -d. -f1-3)
info "Local network: $NETWORK.x"
info "Scanning for Pi..."
echo ""

# Known Pi IPs
KNOWN_IPS=(
    "192.168.10.2"  # Ethernet static
    "192.168.10.3"  # WiFi static (if configured)
)

# Check known IPs first
for ip in "${KNOWN_IPS[@]}"; do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        log "✅ Found Pi at: $ip"
        echo ""
        info "Try accessing:"
        echo "  http://$ip/"
        echo "  ssh andre@$ip"
        exit 0
    fi
done

# Scan common ranges
info "Scanning network range..."
FOUND=0

# Scan 192.168.10.x range
for i in {1..254}; do
    ip="${NETWORK}.$i"
    if [ "$ip" = "$LOCAL_IP" ]; then
        continue
    fi
    
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        # Check if it's a Pi (SSH on port 22)
        if nc -z -G 1 "$ip" 22 2>/dev/null; then
            # Try SSH to confirm it's the Pi
            if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "andre@$ip" "hostname" 2>/dev/null | grep -qi "raspberry\|moode\|pi"; then
                log "✅ Found Pi at: $ip"
                FOUND=1
                break
            fi
        fi
    fi
done

if [ $FOUND -eq 1 ]; then
    echo ""
    info "Pi found at: $ip"
    echo ""
    info "Access web UI:"
    echo "  http://$ip/"
    echo ""
    info "SSH access:"
    echo "  ssh andre@$ip"
else
    warn "Pi not found on network"
    echo ""
    info "Try:"
    echo "  1. Check Pi is booted and connected to WiFi"
    echo "  2. Check router admin page for connected devices"
    echo "  3. Try: arp -a | grep -i 'b8:27:eb\|dc:a6:32\|e4:5f:01' (Pi MAC prefixes)"
    echo ""
    info "Or configure WiFi with static IP in v1.0 setup"
fi
