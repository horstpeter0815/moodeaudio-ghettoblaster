# moOde Audio Custom Build Project

Custom moOde Audio build for Raspberry Pi with enhanced display, network, and audio configurations.

## Project Overview

This project customizes moOde Audio for a specific hardware setup:
- **Display:** Waveshare 7.9" HDMI (400x1280 portrait → 1280x400 landscape)
- **Audio:** HiFiBerry AMP100
- **Network:** Ethernet (192.168.10.2) or WiFi access point
- **User:** andre (UID 1000, GID 1000)

## Quick Start

1. **Flash moOde Image:**
   ```bash
   # Use Balena Etcher or similar tool
   # Image: 2025-12-07-moode-r1001-arm64-lite.img
   ```

2. **Apply Customizations:**
   ```bash
   # Mount SD card
   # Run setup scripts from scripts/setup/
   ```

3. **Boot Pi:**
   - Display: Landscape mode (1280x400)
   - Web UI: Enabled by default
   - Network: Configured automatically

## Project Structure

```
moodeaudio-cursor/
├── .cursorrules          # Cursor project rules
├── .cursorignore         # Files to ignore
├── .cursor/              # Cursor configuration
├── moode-source/         # moOde source modifications
├── scripts/              # Setup and deployment scripts
├── docs/                 # Documentation
├── config/               # Configuration files
└── archive/              # Archived files
```

## Key Features

- ✅ **Display:** Landscape mode (1280x400) with working configuration
- ✅ **SSH:** Always enabled with guaranteed service
- ✅ **Network:** Ethernet and WiFi support
- ✅ **Web UI:** Enabled by default on first boot
- ✅ **User:** Custom user (andre) with proper UID/GID

## Documentation

- **Setup Guides:** `docs/setup/`
- **Troubleshooting:** `docs/troubleshooting/`
- **Working Configs:** `docs/working-configs/`

## Toolbox System

This project includes a unified toolbox that consolidates 334+ scripts into 5 easy-to-use tools:

```bash
# Interactive menu (recommended)
./tools/toolbox.sh

# Or use individual tools
./tools/build.sh    # Build and deployment
./tools/fix.sh      # System fixes
./tools/test.sh     # Testing (includes Docker test suite)
./tools/monitor.sh  # Monitoring
```

### Docker Test Suite

The project includes a comprehensive Docker-based test suite:

```bash
# Run complete test suite
./complete_test_suite.sh

# Run Docker simulations
./tools/test.sh --docker        # System simulation
./tools/test.sh --image         # Test image in container

# Or use individual Docker commands
./START_COMPLETE_SIMULATION.sh  # Complete boot simulation
./START_SYSTEM_SIMULATION_SIMPLE.sh  # System simulation
```

**Test Suite Features:**
- Complete boot simulation (Network, User, SSH, Display, Audio, Chromium)
- System simulation with systemd
- Image testing in containers
- Tests all 12 custom services
- Tests all 10 custom scripts
- Comprehensive logging

See `tools/README.md` and `TEST_SUITE_DOCKER_SUMMARY.md` for complete documentation.

## Scripts

- **Toolbox:** `tools/` - Unified tools (recommended)
- **Setup:** `scripts/setup/` - Initial setup scripts
- **Deployment:** `scripts/deployment/` - Deployment scripts
- **Fixes:** `scripts/fixes/` - Fix and maintenance scripts

## Configuration

- **Boot Config:** `config/boot/` - config.txt, cmdline.txt
- **Services:** `config/systemd/` - systemd service files
- **Network:** `config/network/` - Network configurations

## Important Notes

- Always backup working configurations before changes
- Test on SD card before final deployment
- Use sudo for system file modifications
- SSH user: andre (password: 0815)
- Default IP: 192.168.10.2 (Ethernet)

## Working Configurations

See `DISPLAY_CONFIG_WORKING.md` for display configuration details.

## License

This is a custom build project. moOde Audio is open source.

