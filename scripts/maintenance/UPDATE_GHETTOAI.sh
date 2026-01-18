#!/bin/bash
# Update GhettoAI Knowledge Base
# Creates/updates documentation for RAG training

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RAG_DIR="$PROJECT_ROOT/rag-upload-files"
DOCS_DIR="$RAG_DIR/v1.0-docs"

cd "$PROJECT_ROOT"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🤖 UPDATE GHETTOAI KNOWLEDGE BASE                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create directories
mkdir -p "$DOCS_DIR"

# 1. Create/Update Wizard Documentation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Creating Wizard documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > "$DOCS_DIR/v1.0_room_correction_wizard.md" << 'EOF'
# Room Correction Wizard - Complete Guide

## Overview
The Room Correction Wizard is a Roon-inspired tool for measuring and correcting room acoustics using smartphone microphones and pink noise.

## Access
- **Web Interface:** http://192.168.1.159/ (or ghettoblaster.local)
- **Location:** Audio Settings → Room Correction → Run Wizard
- **Direct URL:** http://192.168.1.159/snd-config.php

## Wizard Steps

### Step 1: Preparation
- Position smartphone at listening position
- Ensure microphone permissions are granted
- Reduce ambient noise

### Step 2: Ambient Noise Measurement
- Measures background noise (5 seconds)
- Required before main measurement
- Automatically subtracted from results

### Step 3: Continuous Measurement with Pink Noise
- Pink noise plays continuously
- Uses Web Audio API for real-time measurement
- 2-3 second rolling average
- Click "Apply Correction" when satisfied

### Step 4: Upload Measurement (Optional)
- Can upload WAV file instead of browser measurement
- Supports audio/wav format

### Step 5: Analysis & Filter Generation
- Shows frequency response graph
- Target curve selection (flat or house curve)
- Generates PEQ filter (12 bands, CamillaDSP Biquad)

### Step 6: Apply & Test
- Shows before/after comparison
- Applies filter via CamillaDSP
- A/B test available

## Technical Details

### Backend
- **File:** `moode-source/www/command/room-correction-wizard.php`
- **Commands:** start_wizard, upload_measurement, analyze_measurement, generate_peq, apply_peq, start_pink_noise, stop_pink_noise, process_frequency_response

### Frontend
- **File:** `moode-source/www/templates/snd-config.html`
- **Modal:** `#room-correction-wizard-modal`
- **Steps:** 6 steps (wizard-step-1 through wizard-step-6)

### Pink Noise
- Uses `sox` to generate continuous pink noise
- Stops MPD service to free audio device
- Uses ALSA device: `_audioout` (if CamillaDSP active) or `plughw:0,0` (direct)
- Volume controlled by system/ALSA volume

### Filter Generation
- Python script: `/usr/local/bin/generate-camilladsp-eq.py`
- Output: CamillaDSP YAML config with Biquad filters
- Location: `/usr/share/camilladsp/configs/`
- Preset naming: `room_correction_peq_YYYY-MM-DD_HH-MM-SS`

### Correction Limits
- Bass range (20-35 Hz): ±15 dB maximum
- All other frequencies: ±10 dB maximum

## Current Status
- ✅ All 6 steps implemented
- ✅ Web Audio API measurement working
- ✅ Pink noise playback working
- ✅ Filter generation working
- ✅ Auto-connect to WiFi configured

## Network Configuration
- **WiFi:** nam yang 2 (192.168.1.159)
- **Ethernet:** 192.168.2.3 (when connected)
- **Hostname:** ghettoblaster.local
- **Auto-Connect:** Enabled for WiFi

EOF

echo "✅ Created: v1.0_room_correction_wizard.md"

# 2. Create/Update Network Documentation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Creating Network documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > "$DOCS_DIR/v1.0_network_configuration.md" << 'EOF'
# Network Configuration - Complete Guide

## Current Configuration (2025-01-12)

### Active Connections
- **WiFi:** nam-yang-2 (192.168.1.159)
- **Ethernet:** Ethernet (192.168.2.3)
- **Hostname:** ghettoblaster.local

### WiFi: nam yang 2
- **SSID:** NAM YANG 2
- **Password:** 1163855108
- **Security:** WPA1/WPA2
- **Auto-Connect:** ✅ Enabled
- **Priority:** 100
- **Method:** DHCP
- **IP:** 192.168.1.159/24

### Ethernet
- **Connection:** Ethernet
- **Method:** DHCP
- **IP:** 192.168.2.3/24
- **Network:** 192.168.2.0/24

## IP Address Reference

### ⚠️ CRITICAL: NEVER USE .101
**192.168.1.101** = **FOREIGN ROUTER** (NOT the Pi!)

### Valid IPs
- **192.168.1.159** - WiFi (nam yang 2)
- **192.168.2.3** - Ethernet
- **192.168.10.2** - Direct Ethernet (Mac-Pi, when connected)
- **ghettoblaster.local** - Hostname (mDNS)

## SSH Access
```bash
# Recommended (hostname)
ssh andre@ghettoblaster.local

# WiFi IP
ssh andre@192.168.1.159

# Ethernet IP
ssh andre@192.168.2.3
```

**Password:** 0815

## NetworkManager Configuration
- **Primary:** NetworkManager
- **Backup:** wpa_supplicant
- **Config Location:** `/etc/NetworkManager/system-connections/`

## Test Scripts
- **Network Test:** `~/test_network.sh` (on Pi)
- **Status Check:** `~/check_status.sh` (on Pi)

EOF

echo "✅ Created: v1.0_network_configuration.md"

# 3. Create System Status Documentation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Creating System status documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > "$DOCS_DIR/v1.0_system_status.md" << 'EOF'
# System Status - Ghettoblaster

## Current Status (2025-01-12)

### System Information
- **Hostname:** ghettoblaster
- **Model:** Raspberry Pi 5
- **OS:** moOde Audio (custom build)
- **Uptime:** Variable (recently booted)

### Services Status
- **MPD:** ✅ Active (Music Player Daemon)
- **CamillaDSP:** ⏳ Activating/Active
- **NetworkManager:** ✅ Active
- **SSH:** ✅ Active
- **CamillaGUI:** ✅ Active
- **Web Interface:** ✅ Accessible

### Network Status
- **WiFi:** ✅ Connected (nam-yang-2)
- **Ethernet:** ✅ Connected
- **Internet:** ✅ Working

### Audio Status
- **MPD:** Running
- **Volume:** 15% (safe level)
- **Output:** HiFiBerry AMP100

### System Resources
- **Disk Usage:** 11% (5.7G / 58G)
- **Memory:** 816Mi / 7.9Gi used
- **Temperature:** ~58°C (normal)

### Web Interface
- **URL:** http://192.168.1.159/
- **Status:** ✅ Accessible
- **Features:** Audio control, Room Correction Wizard, Settings

## Quick Status Check
Run on Pi: `bash ~/check_status.sh`

EOF

echo "✅ Created: v1.0_system_status.md"

# 4. Update manifest
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Updating RAG manifest..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$PROJECT_ROOT/tools/ai.sh" ]; then
    "$PROJECT_ROOT/tools/ai.sh" --manifest
    echo "✅ Manifest updated"
else
    echo "⚠️  ai.sh not found, skipping manifest update"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Wizard documentation created"
echo "✅ Network documentation created"
echo "✅ System status documentation created"
echo ""
echo "Files ready for upload:"
echo "  - $DOCS_DIR/v1.0_room_correction_wizard.md"
echo "  - $DOCS_DIR/v1.0_network_configuration.md"
echo "  - $DOCS_DIR/v1.0_system_status.md"
echo ""
echo "To upload to GhettoAI:"
echo "  1. Run: ./tools/ai.sh --status"
echo "  2. If needed: OPENWEBUI_TOKEN='<token>' ./tools/ai.sh --upload"
echo ""
