# Video Pipeline Test - Waveshare 7.9" DSI LCD auf Raspberry Pi 4B

## Übersicht

Dieser Test prüft systematisch die gesamte Video-Pipeline vom Boot bis zur Bildausgabe auf dem Waveshare 7.9" DSI Display. Basierend auf:
- Raspberry Pi 4B technischer Dokumentation (2-lane MIPI DSI)
- Waveshare 7.9" DSI LCD Dokumentation
- VC4 KMS/DRM Stack

## Test-Struktur

### Phase 1: Boot und Hardware-Erkennung
### Phase 2: Device Tree und Overlays
### Phase 3: DSI Host Initialisierung
### Phase 4: Panel Driver und Binding
### Phase 5: DRM/KMS Stack
### Phase 6: Framebuffer
### Phase 7: Display Initialisierung
### Phase 8: I2C Kommunikation
### Phase 9: Backlight Control
### Phase 10: Video Signal Output

---

## Phase 1: Boot und Hardware-Erkennung

### Test 1.1: Boot-Log Analyse
```bash
# Prüfe Boot-Log auf DSI/Display-relevante Meldungen
dmesg | grep -iE "dsi|mipi|display|panel|vc4|drm|kms" | tee boot_dsi_analysis.log

# Erwartete Ausgaben:
# - DSI host initialization
# - Panel detection
# - VC4 KMS driver loading
# - DRM device creation
```

### Test 1.2: Hardware-Erkennung
```bash
# Prüfe ob DSI Hardware erkannt wird
ls -la /sys/bus/platform/devices/ | grep -i dsi
ls -la /sys/bus/platform/drivers/ | grep -i dsi

# Prüfe MIPI DSI Interface
ls -la /sys/class/mipi_dsi_host/ 2>/dev/null || echo "Kein MIPI DSI Host gefunden"
```

### Test 1.3: Device Tree Erkennung
```bash
# Prüfe ob Device Tree Overlay geladen wurde
ls -la /proc/device-tree/soc/dsi* 2>/dev/null
ls -la /proc/device-tree/__overlays__/ 2>/dev/null | grep waveshare

# Prüfe Device Tree Blob
ls -la /sys/firmware/devicetree/base/soc/dsi* 2>/dev/null
```

---

## Phase 2: Device Tree und Overlays

### Test 2.1: config.txt Validierung
```bash
# Prüfe config.txt auf korrekte Waveshare-Konfiguration
echo "=== CONFIG.TXT ANALYSIS ==="
grep -E "dtoverlay|display_auto_detect|hdmi" /boot/firmware/config.txt | grep -v "^#"

# Erwartete Konfiguration für Pi 4B:
# display_auto_detect=0
# hdmi_ignore_hotplug=1
# hdmi_blanking=1
# dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```

### Test 2.2: Overlay Status
```bash
# Prüfe ob Overlay geladen wurde
vcgencmd get_config dtoverlay | grep waveshare

# Prüfe Overlay-Parameter
cat /sys/firmware/devicetree/base/__symbols__/dpi* 2>/dev/null
cat /sys/firmware/devicetree/base/__symbols__/dsi* 2>/dev/null
```

### Test 2.3: Device Tree Kompilierung
```bash
# Prüfe ob Device Tree Overlay kompiliert wurde
ls -la /boot/firmware/overlays/vc4-kms-dsi-waveshare-panel.dtbo

# Prüfe Overlay-Info
dtc -I dtb -O dts /boot/firmware/overlays/vc4-kms-dsi-waveshare-panel.dtbo 2>/dev/null | grep -A 10 waveshare
```

---

## Phase 3: DSI Host Initialisierung

### Test 3.1: DSI Host Device
```bash
# Prüfe DSI Host Device
echo "=== DSI HOST DEVICES ==="
find /sys/devices -name "*dsi*" -type d 2>/dev/null
find /sys/bus/platform/devices -name "*dsi*" 2>/dev/null

# Prüfe DSI Host Driver
ls -la /sys/bus/platform/drivers/*dsi* 2>/dev/null
```

### Test 3.2: DSI Host Binding
```bash
# Prüfe ob DSI Host an Driver gebunden ist
for dsi in /sys/bus/platform/devices/*dsi*; do
    if [ -d "$dsi" ]; then
        echo "Device: $(basename $dsi)"
        ls -la "$dsi/driver" 2>/dev/null && echo "  -> Bound to: $(basename $(readlink $dsi/driver))" || echo "  -> No driver bound"
    fi
done
```

### Test 3.3: DSI Host Status
```bash
# Prüfe DSI Host Status in dmesg
dmesg | grep -iE "dsi.*host|mipi.*dsi" | tail -20

# Prüfe DSI Host in /proc
cat /proc/device-tree/soc/dsi*/status 2>/dev/null
```

---

## Phase 4: Panel Driver und Binding

### Test 4.1: Panel Device Erkennung
```bash
# Prüfe Panel Device auf I2C Bus 10 (DSI I2C)
echo "=== PANEL DEVICE ON I2C-10 ==="
ls -la /sys/bus/i2c/devices/10-0045/ 2>/dev/null || echo "Panel device 10-0045 nicht gefunden"

# Prüfe alle I2C Devices auf Bus 10
for dev in /sys/bus/i2c/devices/10-*; do
    if [ -d "$dev" ]; then
        echo "Device: $(basename $dev)"
        cat "$dev/name" 2>/dev/null && echo "  Name: $(cat $dev/name)"
        ls -la "$dev/driver" 2>/dev/null && echo "  Driver: $(basename $(readlink $dev/driver))" || echo "  No driver"
    fi
done
```

### Test 4.2: Panel Driver Binding
```bash
# Prüfe welcher Driver an Panel gebunden ist
PANEL_DEV="/sys/bus/i2c/devices/10-0045"
if [ -d "$PANEL_DEV" ]; then
    echo "=== PANEL DRIVER BINDING ==="
    if [ -L "$PANEL_DEV/driver" ]; then
        DRIVER=$(basename $(readlink $PANEL_DEV/driver))
        echo "Panel bound to: $DRIVER"
        
        # Prüfe Driver-Module
        if [ "$DRIVER" = "ws_touchscreen" ]; then
            echo "WARNING: ws_touchscreen bound (should be panel_waveshare_dsi or similar)"
        fi
        
        # Prüfe Driver-Info
        ls -la "/sys/bus/i2c/drivers/$DRIVER/" 2>/dev/null
    else
        echo "ERROR: Panel not bound to any driver!"
    fi
fi
```

### Test 4.3: Panel Driver Module
```bash
# Prüfe geladene Panel-Module
echo "=== PANEL DRIVER MODULES ==="
lsmod | grep -iE "panel|waveshare|dsi"

# Erwartete Module:
# - panel_waveshare_dsi
# - ws_touchscreen (wenn Touchscreen aktiviert)
```

### Test 4.4: Panel Probe Status
```bash
# Prüfe Panel Probe in dmesg
dmesg | grep -iE "panel.*probe|waveshare.*probe|panel.*init" | tail -20

# Prüfe Panel-Initialisierung
dmesg | grep -iE "panel.*bound|panel.*registered" | tail -10
```

---

## Phase 5: DRM/KMS Stack

### Test 5.1: DRM Device Erkennung
```bash
# Prüfe DRM Devices
echo "=== DRM DEVICES ==="
ls -la /sys/class/drm/

# Erwartete Devices:
# - card0 (HDMI, falls aktiviert)
# - card1 (DSI, sollte vorhanden sein)
```

### Test 5.2: DRM Card Status
```bash
# Prüfe DRM Card für DSI
for card in /sys/class/drm/card*; do
    CARD_NAME=$(basename $card)
    echo "=== $CARD_NAME ==="
    
    # Prüfe Connectors
    for conn in $card/*-*; do
        if [ -d "$conn" ]; then
            CONN_NAME=$(basename $conn)
            echo "  Connector: $CONN_NAME"
            cat "$conn/status" 2>/dev/null && echo "    Status: $(cat $conn/status)"
            cat "$conn/enabled" 2>/dev/null && echo "    Enabled: $(cat $conn/enabled)"
            cat "$conn/dpms" 2>/dev/null && echo "    DPMS: $(cat $conn/dpms)"
            cat "$conn/modes" 2>/dev/null && echo "    Modes: $(cat $conn/modes | head -1)"
        fi
    done
done
```

### Test 5.3: VC4 KMS Driver
```bash
# Prüfe VC4 KMS Driver
echo "=== VC4 KMS DRIVER ==="
dmesg | grep -iE "vc4|kms" | tail -20

# Prüfe VC4 Device
ls -la /sys/bus/platform/devices/*vc4* 2>/dev/null
ls -la /sys/bus/platform/drivers/vc4* 2>/dev/null
```

### Test 5.4: DRM/KMS Module Status
```bash
# Prüfe geladene DRM/KMS Module
lsmod | grep -iE "drm|vc4|kms"

# Erwartete Module:
# - drm
# - drm_kms_helper
# - vc4
```

---

## Phase 6: Framebuffer

### Test 6.1: Framebuffer Devices
```bash
# Prüfe Framebuffer Devices
echo "=== FRAMEBUFFER DEVICES ==="
ls -la /sys/class/graphics/

# Prüfe Framebuffer Info
for fb in /sys/class/graphics/fb*; do
    if [ -d "$fb" ]; then
        FB_NAME=$(basename $fb)
        echo "=== $FB_NAME ==="
        cat "$fb/name" 2>/dev/null && echo "  Name: $(cat $fb/name)"
        cat "$fb/virtual_size" 2>/dev/null && echo "  Virtual Size: $(cat $fb/virtual_size)"
        cat "$fb/virtual_size" 2>/dev/null | awk -F, '{print "  Resolution: " $1 "x" $2}'
    fi
done
```

### Test 6.2: Framebuffer Resolution
```bash
# Prüfe Framebuffer Resolution (sollte 1280x400 für Waveshare sein)
FB0="/sys/class/graphics/fb0"
if [ -d "$FB0" ]; then
    VIRT_SIZE=$(cat $FB0/virtual_size 2>/dev/null)
    echo "Framebuffer Resolution: $VIRT_SIZE"
    
    # Erwartete Resolution für Waveshare 7.9": 1280,400
    if echo "$VIRT_SIZE" | grep -q "1280,400"; then
        echo "✓ Correct resolution for Waveshare 7.9\""
    else
        echo "✗ Wrong resolution! Expected: 1280,400"
    fi
fi
```

### Test 6.3: Framebuffer zu DRM Mapping
```bash
# Prüfe Framebuffer zu DRM Card Mapping
for fb in /sys/class/graphics/fb*/device; do
    if [ -L "$fb" ]; then
        DEVICE=$(readlink $fb)
        echo "Framebuffer -> Device: $DEVICE"
        
        # Prüfe ob es zu einem DRM Card gehört
        if echo "$DEVICE" | grep -q "card"; then
            echo "  -> Maps to DRM card"
        fi
    fi
done
```

---

## Phase 7: Display Initialisierung

### Test 7.1: DSI-1 Connector Status
```bash
# Prüfe DSI-1 Connector (Pi 4B verwendet DSI-1, nicht DSI-2!)
DSI_CONN="/sys/class/drm/card1-DSI-1"
if [ -d "$DSI_CONN" ]; then
    echo "=== DSI-1 CONNECTOR STATUS ==="
    cat "$DSI_CONN/status" && echo "  Status: $(cat $DSI_CONN/status)"
    cat "$DSI_CONN/enabled" && echo "  Enabled: $(cat $DSI_CONN/enabled)"
    cat "$DSI_CONN/dpms" && echo "  DPMS: $(cat $DSI_CONN/dpms)"
    cat "$DSI_CONN/mode" && echo "  Mode: $(cat $DSI_CONN/mode)" || echo "  Mode: Not set"
else
    echo "ERROR: DSI-1 connector not found!"
    echo "Available connectors:"
    ls -la /sys/class/drm/card*/ 2>/dev/null | grep -E "^-.*DSI"
fi
```

### Test 7.2: Display Mode Setting
```bash
# Prüfe ob Display Mode gesetzt wurde
DSI_CONN="/sys/class/drm/card1-DSI-1"
if [ -d "$DSI_CONN" ]; then
    MODE=$(cat "$DSI_CONN/mode" 2>/dev/null)
    if [ -n "$MODE" ]; then
        echo "Display Mode: $MODE"
        # Erwarteter Mode: 1280x400@60 oder ähnlich
    else
        echo "WARNING: No display mode set!"
        echo "Available modes:"
        cat "$DSI_CONN/modes" 2>/dev/null
    fi
fi
```

### Test 7.3: Panel Initialisierung
```bash
# Prüfe Panel Initialisierung in dmesg
echo "=== PANEL INITIALIZATION ==="
dmesg | grep -iE "panel.*init|panel.*enable|panel.*power" | tail -20

# Prüfe Panel Power Status
PANEL_DEV="/sys/bus/i2c/devices/10-0045"
if [ -d "$PANEL_DEV" ]; then
    if [ -f "$PANEL_DEV/power_state" ]; then
        echo "Panel Power State: $(cat $PANEL_DEV/power_state)"
    fi
fi
```

---

## Phase 8: I2C Kommunikation

### Test 8.1: I2C Bus Verfügbarkeit
```bash
# Prüfe I2C Bus 10 (DSI I2C für Pi 4B)
echo "=== I2C BUS 10 (DSI I2C) ==="
if [ -c /dev/i2c-10 ]; then
    echo "✓ I2C-10 device exists"
    
    # Prüfe I2C Bus Funktionalität (wenn i2cdetect verfügbar)
    if command -v i2cdetect >/dev/null 2>&1; then
        echo "Scanning I2C-10:"
        i2cdetect -y 10
    else
        echo "i2cdetect not available, checking sysfs:"
        ls -la /sys/bus/i2c/devices/10-*
    fi
else
    echo "✗ I2C-10 device not found!"
fi
```

### Test 8.2: Panel I2C Kommunikation
```bash
# Prüfe I2C Kommunikation mit Panel (Address 0x45)
PANEL_ADDR="0x45"
I2C_BUS="10"

if [ -c /dev/i2c-$I2C_BUS ]; then
    echo "=== PANEL I2C COMMUNICATION (Bus $I2C_BUS, Addr $PANEL_ADDR) ==="
    
    # Prüfe ob Device auf I2C Bus antwortet
    if command -v i2cget >/dev/null 2>&1; then
        # Versuche Register zu lesen (falls bekannt)
        echo "Attempting I2C read from $PANEL_ADDR..."
        i2cget -y $I2C_BUS $PANEL_ADDR 0x00 2>/dev/null && echo "✓ I2C communication successful" || echo "✗ I2C communication failed"
    fi
    
    # Prüfe I2C Timeout Fehler in dmesg
    echo "I2C errors in dmesg:"
    dmesg | grep -iE "i2c.*$PANEL_ADDR|i2c.*timeout|i2c.*error" | tail -10
fi
```

### Test 8.3: I2C Driver Status
```bash
# Prüfe I2C Driver für Panel
PANEL_DEV="/sys/bus/i2c/devices/10-0045"
if [ -d "$PANEL_DEV" ]; then
    echo "=== I2C DRIVER STATUS ==="
    
    # Prüfe Driver
    if [ -L "$PANEL_DEV/driver" ]; then
        DRIVER=$(basename $(readlink $PANEL_DEV/driver))
        echo "Driver: $DRIVER"
        
        # Prüfe Driver-Status
        if [ -f "$PANEL_DEV/power/control" ]; then
            echo "Power Control: $(cat $PANEL_DEV/power/control)"
        fi
    fi
    
    # Prüfe I2C Adapter
    ADAPTER=$(readlink $PANEL_DEV/../../i2c-10 2>/dev/null | xargs basename)
    echo "I2C Adapter: $ADAPTER"
fi
```

---

## Phase 9: Backlight Control

### Test 9.1: Backlight Device
```bash
# Prüfe Backlight Devices
echo "=== BACKLIGHT DEVICES ==="
ls -la /sys/class/backlight/

# Prüfe Backlight Info
for bl in /sys/class/backlight/*; do
    if [ -d "$bl" ]; then
        BL_NAME=$(basename $bl)
        echo "=== $BL_NAME ==="
        cat "$bl/brightness" 2>/dev/null && echo "  Brightness: $(cat $bl/brightness)"
        cat "$bl/max_brightness" 2>/dev/null && echo "  Max Brightness: $(cat $bl/max_brightness)"
        cat "$bl/actual_brightness" 2>/dev/null && echo "  Actual Brightness: $(cat $bl/actual_brightness)"
    fi
done
```

### Test 9.2: Backlight Control Test
```bash
# Test Backlight Control (wenn Backlight Device vorhanden)
BL_DEV="/sys/class/backlight/*/brightness"
if ls $BL_DEV >/dev/null 2>&1; then
    BL_PATH=$(ls $BL_DEV | head -1 | xargs dirname)
    echo "=== BACKLIGHT CONTROL TEST ==="
    
    CURRENT=$(cat $BL_PATH/brightness)
    MAX=$(cat $BL_PATH/max_brightness)
    echo "Current: $CURRENT / Max: $MAX"
    
    # Test: Setze auf 50%
    TEST_VAL=$((MAX / 2))
    echo "Testing: Setting brightness to $TEST_VAL"
    echo $TEST_VAL | sudo tee $BL_PATH/brightness >/dev/null 2>&1
    sleep 1
    NEW_VAL=$(cat $BL_PATH/brightness)
    echo "New value: $NEW_VAL"
    
    # Zurück auf Original
    echo $CURRENT | sudo tee $BL_PATH/brightness >/dev/null 2>&1
else
    echo "No backlight device found"
fi
```

---

## Phase 10: Video Signal Output

### Test 10.1: Display Signal Test
```bash
# Prüfe ob Video-Signal ausgegeben wird
echo "=== VIDEO SIGNAL OUTPUT TEST ==="

# Prüfe DSI-1 Status
DSI_CONN="/sys/class/drm/card1-DSI-1"
if [ -d "$DSI_CONN" ]; then
    STATUS=$(cat $DSI_CONN/status 2>/dev/null)
    DPMS=$(cat $DSI_CONN/dpms 2>/dev/null)
    MODE=$(cat $DSI_CONN/mode 2>/dev/null)
    
    echo "DSI-1 Status: $STATUS"
    echo "DSI-1 DPMS: $DPMS"
    echo "DSI-1 Mode: ${MODE:-Not set}"
    
    if [ "$STATUS" = "connected" ] && [ "$DPMS" = "On" ] && [ -n "$MODE" ]; then
        echo "✓ Display signal should be active"
    else
        echo "✗ Display signal may not be active"
    fi
fi
```

### Test 10.2: Framebuffer Output Test
```bash
# Test: Schreibe Test-Pattern in Framebuffer
FB_DEV="/dev/fb0"
if [ -c "$FB_DEV" ]; then
    echo "=== FRAMEBUFFER OUTPUT TEST ==="
    
    # Prüfe Framebuffer Info
    if command -v fbset >/dev/null 2>&1; then
        echo "Framebuffer info:"
        fbset -i
    fi
    
    # Test: Setze einzelnes Pixel (falls möglich)
    echo "Note: Direct framebuffer write test requires root and specific tools"
fi
```

### Test 10.3: Visual Display Check
```bash
# Manueller Check (muss vom Benutzer durchgeführt werden)
echo "=== VISUAL DISPLAY CHECK ==="
echo "Bitte prüfen Sie visuell:"
echo "1. Ist die grüne LED am Display an/blinkend?"
echo "2. Zeigt das Display ein Bild?"
echo "3. Ist das Bild korrekt (nicht verzerrt/verschoben)?"
echo "4. Funktioniert der Touchscreen (falls aktiviert)?"
```

---

## Vollständiger Test-Durchlauf

### Automatischer Test-Script
```bash
#!/bin/bash
# video_pipeline_test.sh - Vollständiger Video-Pipeline Test

LOG_FILE="video_pipeline_test_$(date +%Y%m%d_%H%M%S).log"

{
    echo "=== VIDEO PIPELINE TEST START ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo ""
    
    echo "=== PHASE 1: BOOT AND HARDWARE DETECTION ==="
    # Test 1.1-1.3 hier einfügen
    
    echo ""
    echo "=== PHASE 2: DEVICE TREE AND OVERLAYS ==="
    # Test 2.1-2.3 hier einfügen
    
    echo ""
    echo "=== PHASE 3: DSI HOST INITIALIZATION ==="
    # Test 3.1-3.3 hier einfügen
    
    echo ""
    echo "=== PHASE 4: PANEL DRIVER AND BINDING ==="
    # Test 4.1-4.4 hier einfügen
    
    echo ""
    echo "=== PHASE 5: DRM/KMS STACK ==="
    # Test 5.1-5.4 hier einfügen
    
    echo ""
    echo "=== PHASE 6: FRAMEBUFFER ==="
    # Test 6.1-6.3 hier einfügen
    
    echo ""
    echo "=== PHASE 7: DISPLAY INITIALIZATION ==="
    # Test 7.1-7.3 hier einfügen
    
    echo ""
    echo "=== PHASE 8: I2C COMMUNICATION ==="
    # Test 8.1-8.3 hier einfügen
    
    echo ""
    echo "=== PHASE 9: BACKLIGHT CONTROL ==="
    # Test 9.1-9.2 hier einfügen
    
    echo ""
    echo "=== PHASE 10: VIDEO SIGNAL OUTPUT ==="
    # Test 10.1-10.3 hier einfügen
    
    echo ""
    echo "=== TEST COMPLETE ==="
    echo "Date: $(date)"
    
} | tee "$LOG_FILE"

echo "Test log saved to: $LOG_FILE"
```

---

## Erwartete Ergebnisse

### Erfolgreiche Pipeline:
1. ✓ DSI Host erkannt und initialisiert
2. ✓ Panel Device auf I2C-10 (0x45) erkannt
3. ✓ Panel Driver (panel_waveshare_dsi) gebunden
4. ✓ DRM Card1 (DSI) erstellt
5. ✓ DSI-1 Connector: connected, enabled, DPMS On
6. ✓ Framebuffer: 1280x400
7. ✓ Display Mode gesetzt: 1280x400@60 (oder ähnlich)
8. ✓ I2C Kommunikation funktioniert (keine Timeouts)
9. ✓ Backlight Device vorhanden und kontrollierbar
10. ✓ Visuelles Bild auf Display

### Häufige Fehler:
1. ✗ Panel nicht gebunden → ws_touchscreen blockiert Panel
2. ✗ DSI Host nicht initialisiert → Device Tree Problem
3. ✗ I2C Timeout → Hardware-Problem (Kabel, Power, Panel)
4. ✗ Kein Display Mode → DRM/KMS Problem
5. ✗ Falsche Resolution → Framebuffer/HDMI Konflikt

---

## Troubleshooting Guide

### Problem: Panel nicht initialisiert
**Diagnose:**
- Prüfe Phase 4 (Panel Driver Binding)
- Prüfe dmesg auf "panel.*probe" Fehler
- Prüfe I2C Kommunikation (Phase 8)

**Lösung:**
- `disable_touch` in config.txt hinzufügen
- Panel Driver manuell binden (falls möglich)
- Hardware prüfen (Kabel, Power)

### Problem: I2C Timeout
**Diagnose:**
- Prüfe Phase 8 (I2C Kommunikation)
- Prüfe dmesg auf "I2C.*timeout" oder "ETIMEDOUT"

**Lösung:**
- Hardware prüfen: DSI Kabel, Power (≥0.6A), Panel Controller
- I2C Bus prüfen: `/dev/i2c-10` vorhanden?
- DIP Switches prüfen: I2C0 aktiviert?

### Problem: Kein Display Mode
**Diagnose:**
- Prüfe Phase 7 (Display Initialisierung)
- Prüfe DSI-1 Connector Status

**Lösung:**
- Mode manuell setzen (falls möglich)
- DRM/KMS Stack prüfen
- Panel Initialisierung prüfen

---

## Referenzen

- Raspberry Pi 4B Datasheet (Release 1.1, March 2024)
- Waveshare 7.9" DSI LCD Wiki
- VC4 KMS/DRM Dokumentation
- Linux DRM Subsystem Dokumentation

