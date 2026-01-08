#!/bin/bash
# Wake up and verify all three Raspberry Pi systems

echo "=========================================="
echo "WAKE UP ALL SYSTEMS"
echo "=========================================="
echo "Date: $(date)"
echo ""

# System definitions
SYSTEM1_IP="192.168.178.199"
SYSTEM1_USER="root"
SYSTEM1_PASS="hifiberry"
SYSTEM1_NAME="HiFiBerryOS Pi 4"

SYSTEM2_IP="192.168.178.134"
SYSTEM2_USER="andre"
SYSTEM2_NAME="moOde Pi 5"

SYSTEM3_HOSTNAME="moodepi4.local"
SYSTEM3_USER="andre"
SYSTEM3_NAME="moOde Pi 4"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

wake_system() {
    local system_num=$1
    local ip=$2
    local user=$3
    local pass=$4
    local name=$5
    local use_ssh_helper=$6
    
    echo "=========================================="
    echo "${BLUE}SYSTEM $system_num: $name${NC}"
    echo "=========================================="
    echo ""
    
    # 1. Ping test
    echo "1. Network Connectivity..."
    if ping -c 3 -W 2000 "$ip" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Online${NC}"
        ONLINE=true
    else
        echo -e "   ${RED}❌ Offline${NC}"
        ONLINE=false
        
        # Try aggressive ping wake-up
        echo "   Attempting to wake up with aggressive ping..."
        for i in {1..10}; do
            ping -c 1 -W 1000 "$ip" >/dev/null 2>&1 && break
            sleep 0.5
        done
        
        # Re-check
        if ping -c 1 -W 2000 "$ip" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Woke up!${NC}"
            ONLINE=true
        fi
    fi
    echo ""
    
    if [ "$ONLINE" = false ]; then
        echo -e "   ${YELLOW}⚠️  System appears to be powered off or unreachable${NC}"
        echo ""
        return 1
    fi
    
    # 2. SSH connectivity
    echo "2. SSH Connectivity..."
    if [ -n "$use_ssh_helper" ] && [ -f "$use_ssh_helper" ]; then
        if $use_ssh_helper "hostname" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ SSH OK (via helper)${NC}"
            SSH_CMD="$use_ssh_helper"
            SSH_OK=true
        else
            echo -e "   ${YELLOW}⚠️  SSH helper failed, trying direct SSH...${NC}"
            SSH_OK=false
        fi
    else
        SSH_OK=false
    fi
    
    if [ "$SSH_OK" = false ]; then
        if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$user@$ip" "hostname" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ SSH OK${NC}"
            SSH_CMD="sshpass -p '$pass' ssh -o StrictHostKeyChecking=no $user@$ip"
            SSH_OK=true
        else
            echo -e "   ${RED}❌ SSH failed${NC}"
            echo ""
            return 1
        fi
    fi
    echo ""
    
    # 3. Wake up services
    echo "3. Waking up services..."
    if [ -n "$use_ssh_helper" ] && [ "$SSH_OK" = true ]; then
        if [ "$system_num" == "1" ]; then
            # HiFiBerryOS
            $use_ssh_helper "systemctl is-active weston cog audio-visualizer 2>&1" | while read line; do
                if echo "$line" | grep -q "inactive"; then
                    echo "   Starting: $line"
                    $use_ssh_helper "sudo systemctl start $(echo $line | awk '{print $1}')" 2>&1
                fi
            done
        else
            # moOde systems
            $use_ssh_helper "systemctl is-active mpd localdisplay 2>&1" | while read line; do
                if echo "$line" | grep -q "inactive"; then
                    echo "   Starting: $line"
                    $use_ssh_helper "sudo systemctl start $(echo $line | awk '{print $1}')" 2>&1
                fi
            done
        fi
    else
        if [ "$system_num" == "1" ]; then
            sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "sudo systemctl start weston cog audio-visualizer 2>&1" || true
        else
            sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "sudo systemctl start mpd localdisplay 2>&1" || true
        fi
    fi
    echo ""
    
    # 4. System status
    echo "4. System Status..."
    if [ -n "$use_ssh_helper" ] && [ "$SSH_OK" = true ]; then
        STATUS=$($use_ssh_helper "hostname && uptime -p 2>/dev/null || uptime && echo 'IP:' \$(hostname -I | awk '{print \$1}')")
    else
        STATUS=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "hostname && uptime -p 2>/dev/null || uptime && echo 'IP:' \$(hostname -I | awk '{print \$1}')")
    fi
    echo "$STATUS" | sed 's/^/   /'
    echo ""
    
    echo -e "${GREEN}✅ System $system_num is online and responding${NC}"
    echo ""
    return 0
}

# Wake System 1: HiFiBerryOS Pi 4
wake_system 1 "$SYSTEM1_IP" "$SYSTEM1_USER" "$SYSTEM1_PASS" "$SYSTEM1_NAME" ""

# Wake System 2: moOde Pi 5
if [ -f "./pi5-ssh.sh" ]; then
    wake_system 2 "$SYSTEM2_IP" "$SYSTEM2_USER" "" "$SYSTEM2_NAME" "./pi5-ssh.sh"
else
    echo -e "${YELLOW}⚠️  pi5-ssh.sh not found${NC}"
    echo ""
fi

# Wake System 3: moOde Pi 4
SYSTEM3_IP=$(ping -c 1 -W 2000 "$SYSTEM3_HOSTNAME" 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$SYSTEM3_IP" ]; then
    if [ -f "./pi4-ssh.sh" ]; then
        wake_system 3 "$SYSTEM3_IP" "$SYSTEM3_USER" "" "$SYSTEM3_NAME" "./pi4-ssh.sh"
    else
        wake_system 3 "$SYSTEM3_IP" "$SYSTEM3_USER" "0815" "$SYSTEM3_NAME" ""
    fi
else
    echo "=========================================="
    echo "${RED}SYSTEM 3: $SYSTEM3_NAME${NC}"
    echo "=========================================="
    echo -e "${RED}❌ Cannot resolve $SYSTEM3_HOSTNAME${NC}"
    echo ""
fi

# Final summary
echo "=========================================="
echo "WAKE-UP SUMMARY"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Quick connectivity check
echo "Quick Connectivity Check:"
echo -n "System 1: "
ping -c 1 -W 1000 $SYSTEM1_IP >/dev/null 2>&1 && echo -e "${GREEN}✅ Online${NC}" || echo -e "${RED}❌ Offline${NC}"

echo -n "System 2: "
ping -c 1 -W 1000 $SYSTEM2_IP >/dev/null 2>&1 && echo -e "${GREEN}✅ Online${NC}" || echo -e "${RED}❌ Offline${NC}"

echo -n "System 3: "
if [ -n "$SYSTEM3_IP" ]; then
    ping -c 1 -W 1000 $SYSTEM3_IP >/dev/null 2>&1 && echo -e "${GREEN}✅ Online${NC}" || echo -e "${RED}❌ Offline${NC}"
else
    echo -e "${RED}❌ Cannot resolve${NC}"
fi

echo ""
echo "=========================================="

