# Toolbox Cleanup Plan

## Overview
Audit and organize the `custom-components/` toolbox directory.

## Current State Analysis

### Scripts (15 files)
Located in `custom-components/scripts/`

#### Python Scripts
1. `analyze-measurement.py` - ✅ **ACTIVE** - Room correction wizard
2. `generate-fir-filter.py` - ✅ **ACTIVE** - FIR filter generation
3. `peppymeter-extended-displays.py` - ✅ **ACTIVE** - PeppyMeter displays

#### Shell Scripts
1. `audio-optimize.sh` - ✅ **ACTIVE** - Audio optimizations
2. `auto-fix-display.sh` - ✅ **ACTIVE** - Display fixes
3. `first-boot-setup.sh` - ✅ **ACTIVE** - First boot
4. `fix-network-ip.sh` - ✅ **ACTIVE** - Network config
5. `force-ssh-on.sh` - ✅ **ACTIVE** - SSH enable
6. `i2c-monitor.sh` - ✅ **ACTIVE** - I2C monitoring
7. `i2c-stabilize.sh` - ✅ **ACTIVE** - I2C stabilization
8. `pcm5122-oversampling.sh` - ✅ **ACTIVE** - DAC config
9. `simple-boot-logger.sh` - ✅ **ACTIVE** - Boot logging
10. `start-chromium-clean.sh` - ✅ **ACTIVE** - Chromium startup
11. `worker-php-patch.sh` - ✅ **ACTIVE** - PHP patches
12. `xserver-ready.sh` - ✅ **ACTIVE** - X server check

### Services (22 files)
All appear to be active systemd services.

### Missing Script
- `generate-camilladsp-eq.py` - Located in `moode-source/usr/local/bin/` but not in `custom-components/scripts/`
  - Should be moved/copied to `custom-components/scripts/` for source control

## Recommendations

### 1. Add Missing Script
- Move `generate-camilladsp-eq.py` to `custom-components/scripts/`
- Update build process to copy it

### 2. Documentation
- ✅ Created `custom-components/README.md` with overview
- Add inline documentation to scripts that lack it

### 3. Organization
- Current organization is good (scripts, services, configs, etc.)
- No consolidation needed - each script has a specific purpose

### 4. Root Directory Scripts
- Many temporary fix scripts in root directory
- Should be archived/moved to `archive/scripts/` if not actively used
- This is separate from the `custom-components/` toolbox

## Next Steps

1. ✅ Create README.md for custom-components
2. Move `generate-camilladsp-eq.py` to custom-components/scripts
3. Review root directory scripts separately (many are temporary)
4. Add inline documentation to scripts missing it

