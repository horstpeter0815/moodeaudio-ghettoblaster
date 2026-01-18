# COMPLETE FIX LIST - Device Tree Level

## Issues to Fix:
1. **White screen on boot** - Display initialization timing
2. **IEC958 in audio chain** - Wrong ALSA mode for I2S device
3. **Volume not working properly** - Volume type misconfigured
4. **Audio stops after moment** - CamillaDSP config issues
5. **Bose Wave filters missing** - Need proper filter config at 96kHz
6. **Left/Right channel incorrect** - Bose Wave has Bass on L, Mids/Highs on R

## What Can Be Fixed at Device Tree Level:
1. ✅ **HiFiBerry AMP100 automute** - dtoverlay parameter
2. ✅ **Display initialization order** - can add delays/dependencies
3. ✅ **I2C clock speed** - for touch/audio stability
4. ❌ **IEC958 removal** - NOT device tree, this is ALSA software config
5. ❌ **CamillaDSP filters** - NOT device tree, this is userspace software
6. ❌ **Volume type** - NOT device tree, this is moOde config

## Device Tree Files to Read and Understand:
1. `/boot/firmware/overlays/hifiberry-amp100.dtbo` - Official HiFiBerry overlay
2. `./moode-source/boot/firmware/overlays/ghettoblaster-amp100.dts` - Custom overlay
3. `./hifiberry-amp100-pi5-overlay.dts` - Pi 5 specific overlay
4. `/boot/firmware/overlays/vc4-kms-v3d-pi5.dtbo` - Display driver
5. `./moode-source/boot/firmware/overlays/ghettoblaster-ft6236.dts` - Touch overlay

## Proper Fix Strategy:
### Device Tree Level (Hardware):
- HiFiBerry AMP100 with automute
- Display timing configuration
- I2C configuration for stability

### Software Level (Configuration):
- moOde database: alsa_output_mode = 'plughw'
- CamillaDSP: Bose Wave filters at 96kHz
- ALSA: proper routing through CamillaDSP
- Display: .xinitrc with proper rotation timing

## Next Steps:
1. Read all device tree files
2. Understand hardware configuration
3. Create proper device tree overlay
4. Remove all script-based fixes
5. Apply correct software configuration
