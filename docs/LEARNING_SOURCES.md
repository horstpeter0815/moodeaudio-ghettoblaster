# Learning Sources - What to Reference

## Critical Understanding

When creating attempts, I MUST reference:
1. **GitHub Repositories** - Actual source code
2. **moOde Forum** - Tested configurations from community
3. **Working Backup** - The ONE tested solution

## GitHub Repositories We Have

### Services Repositories
Located in: `services-repos/`

- **MPD** (`mpd/`) - Music Player Daemon source code
- **CamillaDSP** (`camilladsp/`) - Audio DSP processing
- **BlueZ** (`bluez/`) - Bluetooth stack
- **Shairport-Sync** (`shairport-sync/`) - AirPlay receiver
- **Snapcast** (`snapcast/`) - Multi-room audio
- **Squeezelite** (`squeezelite/`) - Logitech Media Server client
- **Spotifyd** (`spotifyd/`) - Spotify daemon
- **nqptp** (`nqptp/`) - Network PTP daemon

**How to use:**
- Reference actual source code when implementing features
- Check how services are configured
- Understand dependencies and requirements

### Drivers Repositories
Located in: `drivers-repos/`

- **ALSA** (`alsa-lib/`, `alsa-utils/`, `alsa-plugins/`) - Audio system
- **HiFiBerry DSP** (`hifiberry-dsp/`) - HiFiBerry audio processing
- **Waveshare Drivers** (`waveshare-drivers/`, `waveshare-dsi-lcd/`) - Display drivers
- **FT6236 Driver** (`ft6236-driver/`) - Touchscreen driver
- **Raspberry Pi Linux** (`raspberrypi-linux/`) - Kernel source
- **Device Tree Compiler** (`device-tree-compiler/`) - DTS compiler
- **i2c-tools** (`i2c-tools/`) - I2C utilities

**How to use:**
- Reference driver source when configuring hardware
- Check device tree overlays
- Understand hardware requirements

## moOde Forum Knowledge

Located in: `documentation/master/MOODE_FORUM_KNOWLEDGE_BASE.md`

**Contains:**
- Tested configurations from moOde community
- Working solutions for common problems
- Display configurations
- Network setups
- Audio configurations

**Forum Solution Files:**
- `FORUM_SOLUTION_7.9_DISPLAY.md` - Display configuration
- `FORUM_SOLUTION_APPLIED.md` - Applied forum fixes
- `APPLY_FORUM_SOLUTION.sh` - Script to apply forum solutions

**How to use:**
- Reference forum solutions when solving problems
- These are community-tested configurations
- Prefer forum solutions over guessing

## Working Backup (The ONE Solution)

Located in: `moode-working-backup/`

**Status:** WORKING - Touch, Sound, Everything works!

**This is the ONLY tested, verified, working solution.**

**How to use:**
- Reference this when restoring working state
- Compare attempts against this
- This is what actually works

## Learning Process

When creating an attempt:

1. **Check Forum Knowledge Base first**
   - Has this problem been solved before?
   - What did the community do?

2. **Reference GitHub Repositories**
   - How is this implemented in source code?
   - What are the actual requirements?

3. **Compare with Working Backup**
   - What's different from what works?
   - What can we learn from the working state?

4. **Then create attempt**
   - Based on actual knowledge, not guessing
   - Reference real sources

## Rules

- ❌ NEVER guess - always reference sources
- ✅ ALWAYS check forum knowledge base first
- ✅ ALWAYS reference GitHub repos for implementation
- ✅ ALWAYS compare with working backup
- ✅ Only call it "solution" if tested and verified

