# Scripts Directory

**Purpose:** Organized scripts by category

## Directory Structure

```
scripts/
├── network/     # Network configuration scripts
├── wizard/      # Room Correction Wizard scripts
├── deployment/  # Deployment and SD card scripts
├── fixes/       # One-off fix scripts
├── setup/       # Initial setup scripts
├── audio/       # Audio configuration scripts
└── display/     # Display configuration scripts
```

## Usage

### Network Scripts
```bash
cd ~/moodeaudio-cursor && ./scripts/network/SETUP_GHETTOBLASTER_WIFI_CLIENT.sh
cd ~/moodeaudio-cursor && ./scripts/network/FIX_NETWORK_PRECISE.sh
```

### Wizard Scripts
```bash
cd ~/moodeaudio-cursor && ./scripts/wizard/DEPLOY_WIZARD_NOW.sh
cd ~/moodeaudio-cursor && ./scripts/wizard/COMPLETE_WIZARD_SETUP.sh
```

### Deployment Scripts
```bash
cd ~/moodeaudio-cursor && ./scripts/deployment/BURN_IMAGE_TO_SD.sh
cd ~/moodeaudio-cursor && ./scripts/deployment/deploy-simple.sh
```

### Fix Scripts
```bash
cd ~/moodeaudio-cursor && ./scripts/fixes/FIX_DISPLAY_NOW.sh
cd ~/moodeaudio-cursor && ./scripts/fixes/APPLY_XINITRC_DISPLAY.sh
```

### Setup Scripts
```bash
cd ~/moodeaudio-cursor && ./scripts/setup/SETUP_MOODE_PI5_WEB_UI.sh
cd ~/moodeaudio-cursor && ./scripts/setup/SETUP_ETHERNET_DHCP.sh
```

## Toolbox Integration

**Preferred:** Use toolbox tools instead of direct scripts:

```bash
# Network fixes
cd ~/moodeaudio-cursor && ./tools/fix.sh --network

# Deployment
cd ~/moodeaudio-cursor && ./tools/build.sh --deploy

# Testing
cd ~/moodeaudio-cursor && ./tools/test.sh --all

# Interactive menu
cd ~/moodeaudio-cursor && ./tools/toolbox.sh
```

## Adding New Scripts

1. **Check toolbox first** - Does `tools/[category].sh` have this function?
2. **Choose directory** - Put script in appropriate `scripts/[category]/`
3. **Follow naming** - Use `ACTION_DESCRIPTION.sh` format
4. **Update toolbox** - Add function to toolbox if commonly used

---

**Last Updated:** January 7, 2026

