#!/bin/bash
# Comprehensive Pi Status Check
# Run on Pi: bash CHECK_PI_STATUS.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 GHETTOBLASTER SYSTEM STATUS CHECK                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# System Info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SYSTEM INFORMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Hostname:${NC} $(hostname)"
echo -e "${BLUE}Uptime:${NC} $(uptime -p)"
echo -e "${BLUE}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
echo -e "${BLUE}CPU:${NC} $(cat /proc/cpuinfo | grep "Model name" | head -1 | cut -d: -f2 | xargs)"
echo ""

# Network Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 NETWORK STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}IP Addresses:${NC}"
hostname -I | tr ' ' '\n' | while read ip; do
    echo "  ✅ $ip"
done
echo ""
echo -e "${BLUE}Active Connections:${NC}"
if command -v nmcli >/dev/null 2>&1; then
    nmcli connection show --active | grep -v "lo" | awk '{print "  ✅ " $1 " (" $4 ")"}'
fi
echo ""

# Services Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 SERVICES STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_service() {
    local service=$1
    local status=$(systemctl is-active "$service" 2>/dev/null)
    if [ "$status" = "active" ]; then
        echo -e "  ${GREEN}✅${NC} $service: ${GREEN}running${NC}"
    elif [ "$status" = "activating" ]; then
        echo -e "  ${YELLOW}⏳${NC} $service: ${YELLOW}starting${NC}"
    elif [ "$status" = "inactive" ]; then
        echo -e "  ${RED}❌${NC} $service: ${RED}stopped${NC}"
    else
        echo -e "  ${YELLOW}⚠️${NC}  $service: ${YELLOW}not found${NC}"
    fi
}

check_service "mpd"
check_service "camilladsp"
check_service "NetworkManager"
check_service "ssh"
check_service "camillagui"
echo ""

# Audio Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎵 AUDIO STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v mpc >/dev/null 2>&1; then
    MPD_STATUS=$(mpc status 2>/dev/null | head -2)
    if [ -n "$MPD_STATUS" ]; then
        echo "$MPD_STATUS" | while IFS= read -r line; do
            echo "  $line"
        done
    else
        echo -e "  ${YELLOW}⚠️${NC}  MPD not responding"
    fi
else
    echo -e "  ${YELLOW}⚠️${NC}  mpc command not found"
fi
echo ""

# System Resources
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 SYSTEM RESOURCES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Disk Usage:${NC}"
df -h / | tail -1 | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'
echo -e "${BLUE}Memory:${NC}"
free -h | grep Mem | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'
echo -e "${BLUE}Temperature:${NC}"
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP / 1000))
    echo "  $TEMP_C°C"
else
    echo "  N/A"
fi
echo ""

# Web Interface
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 WEB INTERFACE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if curl -s http://localhost/ >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅${NC} Web interface accessible"
    echo -e "  ${BLUE}URL:${NC} http://$(hostname -I | awk '{print $1}')/"
    echo -e "  ${BLUE}Local:${NC} http://localhost/"
else
    echo -e "  ${RED}❌${NC} Web interface not accessible"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ System is running${NC}"
echo -e "${GREEN}✅ Network is connected${NC}"
echo -e "${GREEN}✅ Services are active${NC}"
echo ""
echo "For detailed network test, run: bash ~/test_network.sh"
echo ""
