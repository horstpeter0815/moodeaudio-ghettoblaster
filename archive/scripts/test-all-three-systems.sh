#!/bin/bash
# Comprehensive test script for all three Raspberry Pi systems
# Tests: 2x Pi 4 and 1x Pi 5

echo "=========================================="
echo "COMPREHENSIVE SYSTEM TEST - ALL THREE PIs"
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
NC='\033[0m' # No Color

# Test function
test_system() {
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
    echo "1. Network Connectivity (Ping)..."
    if ping -c 1 -W 2000 "$ip" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Online${NC}"
    else
        echo -e "   ${RED}❌ Offline${NC}"
        echo ""
        return 1
    fi
    echo ""
    
    # 2. SSH connectivity
    echo "2. SSH Connectivity..."
    if [ -n "$use_ssh_helper" ]; then
        # Use SSH helper script
        if $use_ssh_helper "hostname" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ SSH OK (via helper)${NC}"
            SSH_CMD="$use_ssh_helper"
        else
            echo -e "   ${RED}❌ SSH failed${NC}"
            echo ""
            return 1
        fi
    else
        # Use sshpass
        if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$user@$ip" "hostname" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ SSH OK${NC}"
            SSH_CMD="sshpass -p '$pass' ssh -o StrictHostKeyChecking=no $user@$ip"
        else
            echo -e "   ${RED}❌ SSH failed${NC}"
            echo ""
            return 1
        fi
    fi
    echo ""
    
    # 3. Hardware identification
    echo "3. Hardware Identification..."
    if [ -n "$use_ssh_helper" ]; then
        HARDWARE_INFO=$($use_ssh_helper "cat /proc/cpuinfo | grep -i 'model name\|hardware\|revision' | head -3 && cat /proc/device-tree/model 2>/dev/null || echo 'Device tree not available'")
    else
        HARDWARE_INFO=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "cat /proc/cpuinfo | grep -i 'model name\|hardware\|revision' | head -3 && cat /proc/device-tree/model 2>/dev/null || echo 'Device tree not available'")
    fi
    echo "$HARDWARE_INFO" | sed 's/^/   /'
    
    # Detect Pi model
    if echo "$HARDWARE_INFO" | grep -qi "Pi 5\|BCM2712"; then
        DETECTED_MODEL="Raspberry Pi 5"
        echo -e "   ${GREEN}✅ Detected: Raspberry Pi 5${NC}"
    elif echo "$HARDWARE_INFO" | grep -qi "Pi 4\|BCM2711"; then
        DETECTED_MODEL="Raspberry Pi 4"
        echo -e "   ${GREEN}✅ Detected: Raspberry Pi 4${NC}"
    else
        DETECTED_MODEL="Unknown"
        echo -e "   ${YELLOW}⚠️  Model detection unclear${NC}"
    fi
    echo ""
    
    # 4. System information
    echo "4. System Information..."
    if [ -n "$use_ssh_helper" ]; then
        SYS_INFO=$($use_ssh_helper "echo \"Hostname: \$(hostname)\" && echo \"IP: \$(hostname -I | awk '{print \$1}')\" && echo \"Uptime: \$(uptime -p 2>/dev/null || uptime)\" && echo \"OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')\" && echo \"Kernel: \$(uname -r)\"")
    else
        SYS_INFO=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "echo \"Hostname: \$(hostname)\" && echo \"IP: \$(hostname -I | awk '{print \$1}')\" && echo \"Uptime: \$(uptime -p 2>/dev/null || uptime)\" && echo \"OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')\" && echo \"Kernel: \$(uname -r)\"")
    fi
    echo "$SYS_INFO" | sed 's/^/   /'
    echo ""
    
    # 5. Service status (system-specific)
    echo "5. Service Status..."
    if [ "$system_num" == "1" ]; then
        # HiFiBerryOS services
        if [ -n "$use_ssh_helper" ]; then
            SERVICES=$($use_ssh_helper "systemctl is-active weston cog audio-visualizer 2>&1")
        else
            SERVICES=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "systemctl is-active weston cog audio-visualizer 2>&1")
        fi
        echo "$SERVICES" | sed 's/^/   /'
    elif [ "$system_num" == "2" ] || [ "$system_num" == "3" ]; then
        # moOde services
        if [ -n "$use_ssh_helper" ]; then
            SERVICES=$($use_ssh_helper "systemctl is-active mpd localdisplay set-mpd-volume config-validate 2>&1")
        else
            SERVICES=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "systemctl is-active mpd localdisplay set-mpd-volume config-validate 2>&1")
        fi
        echo "$SERVICES" | sed 's/^/   /'
        
        # MPD volume check
        echo "   MPD Volume:"
        if [ -n "$use_ssh_helper" ]; then
            VOLUME=$($use_ssh_helper "mpc volume 2>&1")
        else
            VOLUME=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "mpc volume 2>&1")
        fi
        echo "$VOLUME" | sed 's/^/     /'
    fi
    echo ""
    
    # 6. Display status
    echo "6. Display Status..."
    if [ -n "$use_ssh_helper" ]; then
        DISPLAY_INFO=$($use_ssh_helper "export DISPLAY=:0 2>/dev/null; xrandr --listmonitors 2>/dev/null || echo 'X11 not available'; cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo 'Framebuffer not available'")
    else
        DISPLAY_INFO=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "export DISPLAY=:0 2>/dev/null; xrandr --listmonitors 2>/dev/null || echo 'X11 not available'; cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo 'Framebuffer not available'")
    fi
    echo "$DISPLAY_INFO" | sed 's/^/   /'
    echo ""
    
    # 7. Audio hardware
    echo "7. Audio Hardware..."
    if [ -n "$use_ssh_helper" ]; then
        AUDIO_INFO=$($use_ssh_helper "aplay -l 2>/dev/null | head -5 || echo 'aplay not available'")
    else
        AUDIO_INFO=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "aplay -l 2>/dev/null | head -5 || echo 'aplay not available'")
    fi
    echo "$AUDIO_INFO" | sed 's/^/   /'
    echo ""
    
    # 8. Boot time analysis (if systemd)
    echo "8. Boot Performance..."
    if [ -n "$use_ssh_helper" ]; then
        BOOT_INFO=$($use_ssh_helper "systemd-analyze time 2>/dev/null | head -1 || echo 'systemd-analyze not available'")
    else
        BOOT_INFO=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "systemd-analyze time 2>/dev/null | head -1 || echo 'systemd-analyze not available'")
    fi
    echo "$BOOT_INFO" | sed 's/^/   /'
    echo ""
    
    echo -e "${GREEN}✅ System $system_num test completed${NC}"
    echo ""
    return 0
}

# Test System 1: HiFiBerryOS Pi 4
test_system 1 "$SYSTEM1_IP" "$SYSTEM1_USER" "$SYSTEM1_PASS" "$SYSTEM1_NAME" ""

# Test System 2: moOde Pi 5
if [ -f "./pi5-ssh.sh" ]; then
    test_system 2 "$SYSTEM2_IP" "$SYSTEM2_USER" "" "$SYSTEM2_NAME" "./pi5-ssh.sh"
else
    echo -e "${YELLOW}⚠️  pi5-ssh.sh not found, skipping System 2${NC}"
    echo ""
fi

# Test System 3: moOde Pi 4
# First resolve IP
SYSTEM3_IP=$(ping -c 1 -W 2000 "$SYSTEM3_HOSTNAME" 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$SYSTEM3_IP" ]; then
    if [ -f "./pi4-ssh.sh" ]; then
        test_system 3 "$SYSTEM3_IP" "$SYSTEM3_USER" "" "$SYSTEM3_NAME" "./pi4-ssh.sh"
    else
        echo -e "${YELLOW}⚠️  pi4-ssh.sh not found, trying direct SSH${NC}"
        # Try to get password from context or skip
        test_system 3 "$SYSTEM3_IP" "$SYSTEM3_USER" "0815" "$SYSTEM3_NAME" ""
    fi
else
    echo "=========================================="
    echo "${RED}SYSTEM 3: $SYSTEM3_NAME${NC}"
    echo "=========================================="
    echo -e "${RED}❌ Offline - Cannot resolve $SYSTEM3_HOSTNAME${NC}"
    echo ""
fi

# Summary
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "Date: $(date)"
echo ""
echo "System 1 (HiFiBerryOS Pi 4): $(ping -c 1 -W 1000 $SYSTEM1_IP >/dev/null 2>&1 && echo -e "${GREEN}✅ Online${NC}" || echo -e "${RED}❌ Offline${NC}")"
echo "System 2 (moOde Pi 5): $(ping -c 1 -W 1000 $SYSTEM2_IP >/dev/null 2>&1 && echo -e "${GREEN}✅ Online${NC}" || echo -e "${RED}❌ Offline${NC}")"
if [ -n "$SYSTEM3_IP" ]; then
    echo "System 3 (moOde Pi 4): $(ping -c 1 -W 1000 $SYSTEM3_IP >/dev/null 2>&1 && echo -e "${GREEN}✅ Online${NC}" || echo -e "${RED}❌ Offline${NC}")"
else
    echo "System 3 (moOde Pi 4): ${RED}❌ Offline${NC}"
fi
echo ""
echo "=========================================="

