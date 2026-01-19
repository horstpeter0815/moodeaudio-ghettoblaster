# Scripts Directory

**Purpose:** Production scripts for system deployment and maintenance

---

## Directory Structure

### `/deployment/` - SD Card & Image Management
- `burn-sd-fast.sh` - Quick SD card burn script
- `burn-ghettoblaster-to-sd.sh` - Main deployment script
- `download-and-burn-v1.0-from-github.sh` - GitHub image deployment

### `/audio/` - Audio Configuration
- `SETUP_CAMILLA_PEPPY_V1.0.sh` - CamillaDSP + PeppyMeter setup
- Audio device configuration helpers

### `/display/` - Display Configuration
- Display orientation and resolution scripts
- X11 configuration helpers

### `/network/` - Network Tools
- Network configuration scripts
- Connection diagnostics

### `/system/` - System Maintenance
- `FIX_SD_CARD_COMPLETE_V1.0.sh` - Complete SD card fix
- System health checks
- Backup scripts

---

## Usage

All scripts should be run with appropriate permissions:
```bash
# Most scripts need sudo
sudo bash scripts/deployment/burn-sd-fast.sh

# Some are user-level
bash scripts/audio/check-audio-status.sh
```

---

## Maintenance

- **Keep:** Only actively used, production-ready scripts
- **Archive:** Old debugging scripts → `.archive/`
- **Document:** Each script should have header comments explaining purpose

---

**Last Updated:** 2026-01-19  
**Version:** v1.1 (Production-ready)
