#!/bin/bash
# Synchroner Test für zwei Raspberry Pi 5
# Führt identische Tests auf beiden Geräten gleichzeitig durch

# IP-Adressen der beiden Pi 5
PI5_1_IP="${PI5_1_IP:-192.168.178.123}"  # Erste IP
PI5_2_IP="${PI5_2_IP:-192.168.178.124}"  # Zweite IP
PI_USER="andre"
PI_PASS="0815"

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Dual Raspberry Pi 5 Synchron Test"
echo "=========================================="
echo ""
echo "Pi 5 #1: $PI5_1_IP"
echo "Pi 5 #2: $PI5_2_IP"
echo ""

# Funktion: Führe Command auf beiden Pi aus
run_both() {
    local cmd="$1"
    local desc="$2"
    
    echo "----------------------------------------"
    echo "$desc"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}Pi 5 #1 ($PI5_1_IP):${NC}"
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI5_1_IP" "$cmd" 2>&1 | sed 's/^/  [1] /'
    
    echo ""
    echo -e "${YELLOW}Pi 5 #2 ($PI5_2_IP):${NC}"
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI5_2_IP" "$cmd" 2>&1 | sed 's/^/  [2] /'
    
    echo ""
}

# Funktion: Prüfe ob beide Pi erreichbar sind
check_connectivity() {
    echo "Prüfe Verbindung zu beiden Pi 5..."
    
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI5_1_IP" "echo 'Pi 5 #1 online'" 2>&1 | grep -q "online"; then
        echo -e "${GREEN}✓${NC} Pi 5 #1 erreichbar"
    else
        echo -e "${RED}✗${NC} Pi 5 #1 nicht erreichbar!"
        return 1
    fi
    
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI5_2_IP" "echo 'Pi 5 #2 online'" 2>&1 | grep -q "online"; then
        echo -e "${GREEN}✓${NC} Pi 5 #2 erreichbar"
    else
        echo -e "${RED}✗${NC} Pi 5 #2 nicht erreichbar!"
        return 1
    fi
    
    echo ""
    return 0
}

# Haupt-Test
main() {
    # Verbindung prüfen
    if ! check_connectivity; then
        echo "FEHLER: Beide Pi 5 müssen erreichbar sein!"
        echo "Bitte IP-Adressen prüfen:"
        echo "  export PI5_1_IP=192.168.178.XXX"
        echo "  export PI5_2_IP=192.168.178.XXX"
        exit 1
    fi
    
    # Test 1: Hardware-Info
    run_both "cat /proc/device-tree/model 2>/dev/null || echo 'Model nicht verfügbar'" "Hardware-Modell"
    
    # Test 2: Kernel-Version
    run_both "uname -r" "Kernel-Version"
    
    # Test 3: I2C Bus 0 (I2C0)
    run_both "i2cdetect -y 0 2>&1 | head -10" "I2C Bus 0 (I2C0)"
    
    # Test 4: I2C Bus 1
    run_both "i2cdetect -y 1 2>&1 | head -10" "I2C Bus 1"
    
    # Test 5: Framebuffer
    run_both "if [ -f /sys/class/graphics/fb0/virtual_size ]; then cat /sys/class/graphics/fb0/virtual_size; else echo 'Framebuffer nicht verfügbar'; fi" "Framebuffer Größe"
    
    # Test 6: DSI Status
    run_both "find /sys/class/drm -name 'DSI-*' -type d 2>/dev/null | head -5" "DSI Devices"
    
    # Test 7: Panel Driver
    run_both "dmesg | grep -iE 'panel.*waveshare|ws_panel' | tail -5" "Panel Driver (dmesg)"
    
    # Test 8: DSI dmesg
    run_both "dmesg | grep -iE 'dsi|DSI' | tail -10" "DSI Messages (dmesg)"
    
    # Test 9: Config.txt Check
    run_both "grep -E 'dtoverlay.*waveshare|dsi0|i2c0' /boot/firmware/config.txt 2>/dev/null | head -5" "Config.txt Waveshare Settings"
    
    # Test 10: Loaded Modules
    run_both "lsmod | grep -E 'vc4|panel|drm' | head -10" "Loaded DRM Modules"
    
    echo "=========================================="
    echo "Test abgeschlossen!"
    echo "=========================================="
    echo ""
    echo "Vergleiche die Ausgaben beider Pi 5."
    echo "Unterschiede deuten auf Hardware-Probleme hin."
    echo ""
}

# Script ausführen
main

