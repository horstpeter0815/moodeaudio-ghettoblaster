#!/bin/bash
################################################################################
# VIDEO PIPELINE TEST - 100% SICHER (ÜBERSCHREIBT NICHTS)
# Nur Lese-Operationen, keine Änderungen am System
################################################################################

# Farben
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

LOG_FILE="/tmp/video_pipeline_test_$(date +%Y%m%d_%H%M%S).log"

echo "=== VIDEO PIPELINE TEST (READ-ONLY) ===" | tee "$LOG_FILE"
echo "Start: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Test 1: Display Hardware
echo -e "${BLUE}●${NC} Test 1: Display Hardware..." | tee -a "$LOG_FILE"
if [[ -d /sys/class/drm ]]; then
    echo -e "${GREEN}✓${NC} DRM-System vorhanden" | tee -a "$LOG_FILE"
    ls -la /sys/class/drm/card* 2>/dev/null | head -5 | tee -a "$LOG_FILE"
else
    echo -e "${RED}✗${NC} DRM-System nicht gefunden" | tee -a "$LOG_FILE"
fi

# Test 2: HDMI Connector Status
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 2: HDMI Connector..." | tee -a "$LOG_FILE"
HDMI_FOUND=false
for hdmi in /sys/class/drm/card*-HDMI-*; do
    if [[ -f "$hdmi/status" ]]; then
        HDMI_FOUND=true
        hdmi_name=$(basename "$hdmi")
        status=$(cat "$hdmi/status" 2>/dev/null)
        enabled=$(cat "$hdmi/enabled" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓${NC} $hdmi_name: Status=$status, Enabled=$enabled" | tee -a "$LOG_FILE"
        
        if [[ -f "$hdmi/modes" ]]; then
            modes=$(cat "$hdmi/modes" 2>/dev/null | head -3)
            echo "   Modi: $modes" | tee -a "$LOG_FILE"
        fi
    fi
done

if [[ "$HDMI_FOUND" == false ]]; then
    echo -e "${YELLOW}⚠${NC} Kein HDMI-Connector gefunden" | tee -a "$LOG_FILE"
fi

# Test 3: Framebuffer
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 3: Framebuffer..." | tee -a "$LOG_FILE"
if [[ -e /dev/fb0 ]]; then
    echo -e "${GREEN}✓${NC} /dev/fb0 vorhanden" | tee -a "$LOG_FILE"
    if [[ -f /sys/class/graphics/fb0/virtual_size ]]; then
        fb_size=$(cat /sys/class/graphics/fb0/virtual_size)
        fb_bits=$(cat /sys/class/graphics/fb0/bits_per_pixel 2>/dev/null || echo "unknown")
        echo "   Größe: $fb_size @ ${fb_bits}bpp" | tee -a "$LOG_FILE"
    fi
else
    echo -e "${RED}✗${NC} /dev/fb0 nicht gefunden" | tee -a "$LOG_FILE"
fi

# Test 4: X11 Status
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 4: X11 Server..." | tee -a "$LOG_FILE"
if pgrep -x Xorg > /dev/null; then
    echo -e "${GREEN}✓${NC} X11 läuft" | tee -a "$LOG_FILE"
    export DISPLAY=:0
    
    # X11 Display Info
    if command -v xrandr > /dev/null 2>&1; then
        echo "   xrandr Output:" | tee -a "$LOG_FILE"
        xrandr 2>/dev/null | grep -E "connected|Screen|current" | head -10 | tee -a "$LOG_FILE"
        
        # Prüfe HDMI-2 Output
        if xrandr --output HDMI-2 --query 2>/dev/null | grep -q "connected"; then
            current_mode=$(xrandr --output HDMI-2 --query 2>/dev/null | grep "current" | awk '{print $2}')
            echo -e "${GREEN}✓${NC} HDMI-2: $current_mode" | tee -a "$LOG_FILE"
        else
            echo -e "${YELLOW}⚠${NC} HDMI-2 nicht erkannt" | tee -a "$LOG_FILE"
        fi
    fi
else
    echo -e "${RED}✗${NC} X11 läuft nicht" | tee -a "$LOG_FILE"
fi

# Test 5: Chromium Status
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 5: Chromium..." | tee -a "$LOG_FILE"
if pgrep -f chromium-browser > /dev/null; then
    echo -e "${GREEN}✓${NC} Chromium läuft" | tee -a "$LOG_FILE"
    ps aux | grep chromium-browser | grep -v grep | head -3 | awk '{print "   PID:", $2, "CMD:", $11, $12, $13}' | tee -a "$LOG_FILE"
else
    echo -e "${RED}✗${NC} Chromium läuft nicht" | tee -a "$LOG_FILE"
fi

# Test 6: Config Files (READ-ONLY)
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 6: Konfiguration (READ-ONLY)..." | tee -a "$LOG_FILE"

# config.txt
if [[ -f /boot/firmware/config.txt ]]; then
    echo -e "${GREEN}✓${NC} config.txt vorhanden" | tee -a "$LOG_FILE"
    echo "   display_rotate: $(grep 'display_rotate' /boot/firmware/config.txt || echo 'FEHLT')" | tee -a "$LOG_FILE"
    echo "   hdmi_mode: $(grep 'hdmi_mode' /boot/firmware/config.txt || echo 'FEHLT')" | tee -a "$LOG_FILE"
    echo "   disable_fw_kms_setup: $(grep 'disable_fw_kms_setup' /boot/firmware/config.txt || echo 'FEHLT')" | tee -a "$LOG_FILE"
else
    echo -e "${RED}✗${NC} config.txt nicht gefunden" | tee -a "$LOG_FILE"
fi

# cmdline.txt
if [[ -f /boot/firmware/cmdline.txt ]]; then
    echo -e "${GREEN}✓${NC} cmdline.txt vorhanden" | tee -a "$LOG_FILE"
    video_param=$(grep -o 'video=[^ ]*' /boot/firmware/cmdline.txt || echo "FEHLT")
    echo "   video= Parameter: $video_param" | tee -a "$LOG_FILE"
else
    echo -e "${RED}✗${NC} cmdline.txt nicht gefunden" | tee -a "$LOG_FILE"
fi

# xinitrc
if [[ -f /home/andre/.xinitrc ]]; then
    echo -e "${GREEN}✓${NC} .xinitrc vorhanden" | tee -a "$LOG_FILE"
    if grep -q "xrandr.*HDMI-2" /home/andre/.xinitrc; then
        echo "   Enthält xrandr HDMI-2 Konfiguration" | tee -a "$LOG_FILE"
    fi
    if grep -q "chromium-browser" /home/andre/.xinitrc; then
        echo "   Enthält Chromium-Start" | tee -a "$LOG_FILE"
    fi
else
    echo -e "${YELLOW}⚠${NC} .xinitrc nicht gefunden" | tee -a "$LOG_FILE"
fi

# Touchscreen Config
if [[ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]]; then
    echo -e "${GREEN}✓${NC} Touchscreen-Config vorhanden" | tee -a "$LOG_FILE"
    if grep -q "TransformationMatrix" /etc/X11/xorg.conf.d/99-touchscreen.conf; then
        matrix=$(grep "TransformationMatrix" /etc/X11/xorg.conf.d/99-touchscreen.conf)
        echo "   $matrix" | tee -a "$LOG_FILE"
    fi
else
    echo -e "${YELLOW}⚠${NC} Touchscreen-Config nicht gefunden" | tee -a "$LOG_FILE"
fi

# Test 7: Kernel Modules
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 7: Kernel Modules..." | tee -a "$LOG_FILE"
if lsmod | grep -q "^vc4"; then
    echo -e "${GREEN}✓${NC} VC4 DRM Driver geladen" | tee -a "$LOG_FILE"
else
    echo -e "${YELLOW}⚠${NC} VC4 Driver nicht geladen" | tee -a "$LOG_FILE"
fi

# Test 8: System Info
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}●${NC} Test 8: System Info..." | tee -a "$LOG_FILE"
echo "   OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo 'Unknown')" | tee -a "$LOG_FILE"
echo "   Kernel: $(uname -r)" | tee -a "$LOG_FILE"
echo "   Hardware: $(cat /proc/device-tree/model 2>/dev/null || echo 'Unknown')" | tee -a "$LOG_FILE"
echo "   Uptime: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')" | tee -a "$LOG_FILE"

# Zusammenfassung
echo "" | tee -a "$LOG_FILE"
echo "=== ZUSAMMENFASSUNG ===" | tee -a "$LOG_FILE"
echo "Log-Datei: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Ende: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo -e "${GREEN}✓${NC} Test abgeschlossen - KEINE ÄNDERUNGEN am System vorgenommen" | tee -a "$LOG_FILE"

