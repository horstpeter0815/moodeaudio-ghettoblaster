# Custom Components

Custom components that are integrated into the moOde audio system during the build process.

## Structure

```
custom-components/
├── scripts/          # Python and shell scripts
├── services/         # Systemd service files
├── configs/          # Configuration templates
├── overlays/         # Device tree overlays
├── presets/          # Audio presets (EQ, filters)
└── templates/        # HTML templates
```

## Scripts

### Audio Processing
- `analyze-measurement.py` - Analyzes audio measurements, extracts frequency response
- `generate-fir-filter.py` - Generates FIR filters for audio processing
- `generate-camilladsp-eq.py` - (in moode-source) Generates CamillaDSP PEQ from frequency response

### Audio Optimization
- `audio-optimize.sh` - Audio system optimizations
- `pcm5122-oversampling.sh` - PCM5122 DAC oversampling configuration

### Display Management
- `auto-fix-display.sh` - Automatic display configuration
- `fix-display-toggle.sh` - Fix display not turning back on after toggle off
- `diagnose-display-black.sh` - Diagnose black screen (backlight only) issues
- `fix-display-black.sh` - Fix black screen by restarting Chromium properly
- `peppymeter-extended-displays.py` - PeppyMeter multi-display support
- `start-chromium-clean.sh` - Clean Chromium startup
- `xserver-ready.sh` - X server readiness check

### System Services
- `first-boot-setup.sh` - First boot initialization
- `simple-boot-logger.sh` - Boot logging utility
- `worker-php-patch.sh` - PHP worker patches

### Network
- `fix-network-ip.sh` - Network IP configuration

### Hardware
- `force-ssh-on.sh` - Force SSH enable
- `i2c-monitor.sh` - I2C bus monitoring
- `i2c-stabilize.sh` - I2C bus stabilization

## Services

Systemd service files that run the scripts at appropriate times.

### SSH Services
- `enable-ssh-early.service`
- `ssh-asap.service`
- `ssh-guaranteed.service`
- `ssh-ultra-early.service`
- `ssh-watchdog.service`

### Network Services
- `network-guaranteed.service`

### Display Services
- `auto-fix-display.service`
- `localdisplay.service`
- `xserver-ready.service`

### Audio Services
- `audio-optimize.service`

### PeppyMeter Services
- `peppymeter.service`
- `peppymeter-extended-displays.service`

### Debug Services
- `boot-debug-logger.service`

## Configuration Templates

- `configs/cmdline.txt.template` - Kernel command line
- `configs/config.txt.template` - Raspberry Pi configuration

## Device Tree Overlays

- `overlays/ghettoblaster-amp100.dts` - AMP100 amplifier overlay
- `overlays/ghettoblaster-ft6236.dts` - FT6236 touchscreen overlay

## Presets

- `presets/ghettoblaster-flat-eq.json` - Flat EQ preset

## Templates

- `templates/room-correction-wizard-modal.html` - Room correction wizard UI template

## Integration

These components are copied to `moode-source` during the build process. See `imgbuild/` for build scripts.

