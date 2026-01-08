#!/bin/bash
# Complete Audio and Video Pipeline Diagnosis
# Checks every component step by step

DB="/var/local/www/db/moode-sqlite3.db"

echo "=========================================="
echo "COMPLETE AUDIO & VIDEO PIPELINE DIAGNOSIS"
echo "=========================================="
echo ""

# ===== 1. DATABASE CONFIGURATION =====
echo "=== 1. DATABASE CONFIGURATION ==="
echo ""

echo "Audio Settings:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('audioout', 'i2sdevice', 'i2soverlay', 'cardnum', 'alsa_output_mode', 'alsavolume', 'amixname') ORDER BY param;" 2>/dev/null
echo ""

echo "Display Settings:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('peppy_display', 'local_display', 'peppy_display_type', 'hdmi_scn_orient') ORDER BY param;" 2>/dev/null
echo ""

echo "CamillaDSP Settings:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param LIKE 'camilladsp%' OR param LIKE 'cdsp%' ORDER BY param;" 2>/dev/null
echo ""

echo "MPD Settings:"
sqlite3 "$DB" "SELECT param, value FROM cfg_mpd ORDER BY param;" 2>/dev/null
echo ""

# ===== 2. ALSA CONFIGURATION =====
echo "=== 2. ALSA CONFIGURATION ==="
echo ""

echo "Available ALSA cards:"
aplay -l 2>/dev/null || echo "aplay not available"
echo ""

echo "_audioout.conf (main ALSA output):"
cat /etc/alsa/conf.d/_audioout.conf 2>/dev/null || echo "File not found"
echo ""

echo "camilladsp.conf (if exists):"
cat /etc/alsa/conf.d/camilladsp.conf 2>/dev/null | head -20 || echo "File not found or empty"
echo ""

echo "peppy.conf (if exists):"
cat /etc/alsa/conf.d/peppy.conf 2>/dev/null | head -10 || echo "File not found (Peppy not active)"
echo ""

# ===== 3. CAMILLADSP CONFIGURATION =====
echo "=== 3. CAMILLADSP CONFIGURATION ==="
echo ""

CAMILLADSP_CONFIG=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)
echo "Active CamillaDSP config: $CAMILLADSP_CONFIG"
echo ""

if [ "$CAMILLADSP_CONFIG" != "off" ] && [ "$CAMILLADSP_CONFIG" != "" ]; then
    CONFIG_FILE="/usr/share/camilladsp/configs/$CAMILLADSP_CONFIG"
    if [ -f "$CONFIG_FILE" ]; then
        echo "Config file: $CONFIG_FILE"
        echo ""
        echo "Playback device in config:"
        grep -A 5 "playback:" "$CONFIG_FILE" | grep -E "device:|type:" || echo "Not found"
        echo ""
        echo "Samplerate:"
        grep "samplerate:" "$CONFIG_FILE" | head -1
        echo ""
        echo "Format:"
        grep -A 3 "playback:" "$CONFIG_FILE" | grep "format:" || echo "Not found"
    else
        echo "⚠ Config file not found: $CONFIG_FILE"
    fi
    
    echo ""
    echo "working_config.yml symlink:"
    ls -la /usr/share/camilladsp/working_config.yml 2>/dev/null || echo "Symlink not found"
fi
echo ""

# ===== 4. MPD CONFIGURATION =====
echo "=== 4. MPD CONFIGURATION ==="
echo ""

echo "MPD output device:"
grep -E "device|mixer_type" /etc/mpd.conf 2>/dev/null | head -10 || echo "mpd.conf not found"
echo ""

echo "MPD status:"
systemctl status mpd --no-pager -l | head -15 || echo "MPD service not found"
echo ""

# ===== 5. SERVICE STATUS =====
echo "=== 5. SERVICE STATUS ==="
echo ""

echo "MPD:"
systemctl is-active mpd 2>/dev/null && echo "  ✓ Running" || echo "  ✗ Not running"
echo ""

echo "CamillaDSP process:"
if pgrep camilladsp > /dev/null; then
    echo "  ✓ Running (PID: $(pgrep camilladsp))"
else
    echo "  ✗ Not running"
fi
echo ""

echo "mpd2cdspvolume:"
systemctl is-active mpd2cdspvolume 2>/dev/null && echo "  ✓ Active" || echo "  ✗ Inactive"
echo ""

echo "PeppyMeter (local_display):"
systemctl is-active localui 2>/dev/null && echo "  ✓ Running" || echo "  ✗ Not running"
echo ""

# ===== 6. CONFIGURATION CONFLICTS =====
echo "=== 6. CONFIGURATION CONFLICTS ==="
echo ""

I2SDEV=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='i2sdevice';" 2>/dev/null)
I2SOVR=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='i2soverlay';" 2>/dev/null)
PEPPY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)
LOCAL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)

CONFLICTS=0

if [ "$I2SDEV" != "None" ] && [ "$I2SDEV" != "" ] && [ "$I2SOVR" != "None" ] && [ "$I2SOVR" != "" ]; then
    echo "  ⚠ AUDIO CONFLICT: Both I2S device and DT Overlay are set"
    CONFLICTS=1
else
    echo "  ✓ Audio: No conflict"
fi

if [ "$PEPPY" = "1" ] && [ "$LOCAL" = "1" ]; then
    echo "  ⚠ DISPLAY CONFLICT: Both Peppy and Local Display are enabled"
    CONFLICTS=1
else
    echo "  ✓ Display: No conflict"
fi

if [ $CONFLICTS -eq 0 ]; then
    echo "  ✓ No configuration conflicts detected"
fi
echo ""

# ===== 7. AUDIO PIPELINE FLOW =====
echo "=== 7. AUDIO PIPELINE FLOW ==="
echo ""

echo "Current audio chain:"
echo "  Source: MPD"
echo "  Output: $(grep 'device' /etc/mpd.conf 2>/dev/null | head -1 | awk '{print $2}' | tr -d '\"')"
echo "  ALSA Device: $(grep 'slave.pcm' /etc/alsa/conf.d/_audioout.conf 2>/dev/null | awk '{print $2}' | tr -d '\"')"

CAMILLADSP_CONFIG=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)
if [ "$CAMILLADSP_CONFIG" != "off" ] && [ "$CAMILLADSP_CONFIG" != "" ]; then
    echo "  CamillaDSP: $CAMILLADSP_CONFIG"
    CAMILLADSP_DEVICE=$(grep -A 5 "playback:" "/usr/share/camilladsp/configs/$CAMILLADSP_CONFIG" 2>/dev/null | grep "device:" | awk '{print $2}' | tr -d '\"')
    echo "    → Output Device: $CAMILLADSP_DEVICE"
fi

MIXER_TYPE=$(sqlite3 "$DB" "SELECT value FROM cfg_mpd WHERE param='mixer_type';" 2>/dev/null)
echo "  Mixer Type: $MIXER_TYPE"
echo ""

# ===== 8. RECOMMENDATIONS =====
echo "=== 8. RECOMMENDATIONS ==="
echo ""

if [ $CONFLICTS -eq 1 ]; then
    echo "⚠ Configuration conflicts detected - these must be resolved:"
    echo ""
    if [ "$I2SDEV" != "None" ] && [ "$I2SOVR" != "None" ]; then
        echo "  - Audio: Choose EITHER I2S Device OR DT Overlay (not both)"
    fi
    if [ "$PEPPY" = "1" ] && [ "$LOCAL" = "1" ]; then
        echo "  - Display: Choose EITHER Peppy Display OR Local Display (not both)"
    fi
    echo ""
fi

CAMILLADSP_CONFIG=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)
if [ "$CAMILLADSP_CONFIG" != "off" ] && [ "$CAMILLADSP_CONFIG" != "" ]; then
    CAMILLADSP_DEVICE=$(grep -A 5 "playback:" "/usr/share/camilladsp/configs/$CAMILLADSP_CONFIG" 2>/dev/null | grep "device:" | awk '{print $2}' | tr -d '\"')
    if echo "$CAMILLADSP_DEVICE" | grep -qi "peppy"; then
        echo "⚠ CamillaDSP device is set to 'peppy' - this may not exist"
        echo "  Recommended: Change to plughw:0,0 or hw:0,0"
        echo ""
    fi
fi

if ! pgrep camilladsp > /dev/null && [ "$CAMILLADSP_CONFIG" != "off" ] && [ "$CAMILLADSP_CONFIG" != "" ]; then
    echo "⚠ CamillaDSP config is active but process is not running"
    echo "  Try: Play audio to trigger CamillaDSP startup"
    echo ""
fi

echo "=========================================="
echo "DIAGNOSIS COMPLETE"
echo "=========================================="

