# Build Integration Requirements

**Date:** January 13, 2026  
**Issue:** Build is incomplete - scripts missing, first-boot-setup not running

## Root Cause

The build process is not properly integrating all required components. This causes:
- Missing scripts after build
- First boot setup not running
- Services not enabled
- Configuration not applied
- Repeated failures requiring manual fixes

## What MUST Be in the Build

### 1. Required Scripts (must be copied to `/usr/local/bin/`)

- [ ] `persist-display-config.sh` - Ensures display settings persist
- [ ] `fix-display-orientation-before-peppy.sh` - Fixes display before PeppyMeter
- [ ] `worker-php-patch.sh` - Patches worker.php to prevent display override
- [ ] `first-boot-setup.sh` - Runs initial setup on first boot
- [ ] `post-build-overlays.sh` - Compiles custom overlays

**Current Status:** ❌ ALL MISSING from build

### 2. First Boot Setup (must run automatically)

The `first-boot-setup.sh` script must:
- [ ] Run on first boot (via systemd service or cloud-init)
- [ ] Create marker file `/var/lib/first-boot-setup.done`
- [ ] Apply worker.php patch
- [ ] Enable required services (nginx, php-fpm, mpd)
- [ ] Set up user 'andre' with correct UID 1000
- [ ] Enable SSH service
- [ ] Compile custom overlays

**Current Status:** ❌ NEVER RAN

### 3. Services (must be enabled in build)

- [ ] `nginx` - Web server
- [ ] `php8.4-fpm` or `php-fpm` - PHP processor
- [ ] `mpd` - Music Player Daemon (CRITICAL for moOde)
- [ ] `localdisplay` - Display service

**Current Status:** ❌ MPD was disabled, others may not persist

### 4. File Permissions (must be set in build)

- [ ] `/var/www` owned by `www-data:www-data`
- [ ] `/var/www` files: 644 permissions
- [ ] `/var/www` directories: 755 permissions
- [ ] `/var/local/www/db/moode-sqlite3.db` accessible by www-data

**Current Status:** ⚠️ Fixed manually, but should be in build

### 5. Database Configuration (must be set in build)

- [ ] `hdmi_scn_orient = 'portrait'` in cfg_system
- [ ] `alsa_output_mode = 'alsa'` in cfg_mpd (not 'iec958')
- [ ] `i2sdevice = 'sndrpihifiberry'` in cfg_mpd
- [ ] `cardnum = '0'` in cfg_mpd

**Current Status:** ⚠️ Some settings missing or wrong

### 6. Display Configuration (must be in build)

- [ ] `display_rotate=1` in `/boot/firmware/config.txt`
- [ ] `fbcon=rotate:1` in `/boot/firmware/cmdline.txt`
- [ ] `.xinitrc` with forum solution (rotate left)
- [ ] `hdmi_scn_orient='portrait'` in database

**Current Status:** ✅ Applied manually, but should be in build

## Build Process Fixes Needed

### 1. Script Integration

**Where:** Build process must copy scripts from `rag-upload-files/scripts/` to `/usr/local/bin/` on the image

**Action Required:**
- Add script copying step to build process
- Ensure scripts are executable
- Verify scripts exist after build

### 2. First Boot Setup Integration

**Where:** Systemd service or cloud-init must run `first-boot-setup.sh` on first boot

**Action Required:**
- Create systemd service: `first-boot-setup.service`
- Service should run once on boot
- Check for marker file to prevent re-running

### 3. Service Enablement

**Where:** Build must enable services, not just install them

**Action Required:**
- Enable services in build process
- Or ensure first-boot-setup enables them
- Verify services are enabled after build

### 4. Configuration Persistence

**Where:** Build must set initial database values

**Action Required:**
- Set database values during build
- Or ensure first-boot-setup sets them
- Verify values persist after boot

## Verification Checklist

After build, verify:

- [ ] All scripts exist in `/usr/local/bin/`
- [ ] `/var/lib/first-boot-setup.done` exists
- [ ] All required services are enabled
- [ ] Web interface works (all config pages load)
- [ ] Display rotation works (boot and X11)
- [ ] Audio configuration is correct
- [ ] File permissions are correct

### 7. PeppyMeter Configuration (must be set in build)

- [ ] `peppy_display = '0'` in database (disabled by default)
- [ ] PeppyMeter service disabled by default
- [ ] Config file: `screen.width = 1280`, `screen.height = 400`
- [ ] Config file: `exit.on.touch = True`

**Current Status:** ⚠️ Fixed manually, but should be in build

### 8. IP Address Configuration (must be in build)

- [ ] No hardcoded IPs in nginx configuration
- [ ] `.xinitrc` uses `local_display_url` from database (dynamic)
- [ ] Chromium uses database URL, not hardcoded IP
- [ ] All URLs use `localhost` or variables

**Current Status:** ⚠️ Fixed manually, but should be in build

## Current Workaround

Until build is fixed, we're applying fixes manually:
- ✅ Scripts created manually
- ✅ First boot setup run manually
- ✅ Services enabled manually
- ✅ Configuration set manually
- ✅ PeppyMeter configured manually
- ✅ IP addresses fixed manually

**This is NOT a solution - it's a workaround.**

## Next Steps

1. **Fix build process** to include all scripts
2. **Fix build process** to run first-boot-setup
3. **Fix build process** to enable services
4. **Fix build process** to set initial configuration
5. **Test build** to verify everything works without manual fixes

---

**This document identifies what needs to be fixed in the BUILD PROCESS, not just what needs to be fixed on the running system.**
