# Build Integration Checklist - Next Build

**Date:** January 13, 2026  
**Purpose:** Ensure all fixes are integrated into the build process

## Pre-Build Checklist

Before starting the build, verify:

- [ ] All required scripts exist in `rag-upload-files/scripts/`
- [ ] `first-boot-setup.sh` includes all necessary setup
- [ ] Build process copies scripts to `/usr/local/bin/`
- [ ] Build process creates systemd service for first-boot-setup
- [ ] Build process sets initial database values
- [ ] Build process sets file permissions
- [ ] Build process enables required services

## What Must Be Integrated

### 1. Scripts (Copy to `/usr/local/bin/` during build)

**Source:** `rag-upload-files/scripts/`  
**Destination:** `/usr/local/bin/` on image

Required scripts:
- [x] `persist-display-config.sh` ✅ (created manually, needs build integration)
- [x] `worker-php-patch.sh` ✅ (created manually, needs build integration)
- [x] `first-boot-setup.sh` ✅ (exists, needs to run automatically)
- [x] `post-build-overlays.sh` ✅ (exists)
- [ ] `fix-display-orientation-before-peppy.sh` (if needed)

**Action:** Add to build process to copy these scripts

### 2. First Boot Setup (Run automatically)

**Script:** `rag-upload-files/scripts/first-boot-setup.sh`

Must be enhanced to include:
- [x] Compile custom overlays ✅
- [x] Apply worker.php patch ✅
- [x] Enable SSH ✅
- [x] Create user 'andre' ✅
- [ ] **Enable MPD service** (CRITICAL - currently missing!)
- [ ] **Enable nginx service**
- [ ] **Enable php-fpm service**
- [ ] **Set database initial values:**
  - `peppy_display = '0'`
  - `hdmi_scn_orient = 'portrait'`
  - `alsa_output_mode = 'alsa'`
  - `i2sdevice = 'sndrpihifiberry'`
- [ ] **Set file permissions:**
  - `/var/www` → `www-data:www-data`
  - Database accessible

**Action:** Enhance `first-boot-setup.sh` and ensure it runs via systemd service

### 3. Display Configuration (Set during build)

**Files to modify:**
- `/boot/firmware/config.txt`:
  - [x] `display_rotate=1` ✅
  - [x] `dtoverlay=vc4-kms-v3d,noaudio` ✅
  - [x] `hdmi_force_hotplug=1` ✅
  
- `/boot/firmware/cmdline.txt`:
  - [x] `fbcon=rotate:1` ✅

- `/home/andre/.xinitrc`:
  - [x] Forum solution (rotate left) ✅
  - [x] `SCREEN_RES="1280,400"` ✅
  - [x] Uses `local_display_url` from database ✅

- Database:
  - [x] `hdmi_scn_orient = 'portrait'` ✅

**Action:** Add to build process or first-boot-setup

### 4. Audio Configuration (Set during build)

**Files to modify:**
- `/boot/firmware/config.txt`:
  - [x] `dtoverlay=hifiberry-amp100` ✅

- Database:
  - [x] `alsa_output_mode = 'alsa'` ✅
  - [x] `i2sdevice = 'sndrpihifiberry'` ✅
  - [x] `cardnum = '0'` ✅

**Action:** Add to build process or first-boot-setup

### 5. PeppyMeter Configuration (Set during build)

**Files to modify:**
- `/etc/peppymeter/config.txt`:
  - [x] `screen.width = 1280` ✅
  - [x] `screen.height = 400` ✅
  - [x] `exit.on.touch = True` ✅

- Database:
  - [x] `peppy_display = '0'` (disabled by default) ✅

- Service:
  - [x] PeppyMeter service disabled ✅

**Action:** Add to build process or first-boot-setup

### 6. IP Address Configuration (Set during build)

**Files to check:**
- Nginx configs: No hardcoded IPs ✅
- `.xinitrc`: Uses `localhost` or database URL ✅

**Action:** Verify in build, ensure no hardcoded IPs

### 7. File Permissions (Set during build)

- [x] `/var/www` → `www-data:www-data` ✅
- [x] Database accessible ✅

**Action:** Add to build process or first-boot-setup

## Build Process Integration Points

### Stage 3: Custom Components

**File:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-deploy.sh`

This stage should:
1. Copy scripts from `rag-upload-files/scripts/` to image
2. Copy configuration files
3. Set up systemd service for first-boot-setup

**File:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`

This stage should:
1. Set file permissions
2. Enable services
3. Set initial database values (if possible)
4. Configure display/audio settings

### First Boot Service

**Create:** `/lib/systemd/system/first-boot-setup.service`

```ini
[Unit]
Description=Ghettoblaster First Boot Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/first-boot-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Enable:** In build process or first-boot-setup

## Enhanced first-boot-setup.sh Requirements

Add to `first-boot-setup.sh`:

1. **Enable MPD:**
   ```bash
   systemctl enable mpd
   systemctl start mpd
   ```

2. **Enable web services:**
   ```bash
   systemctl enable nginx
   systemctl enable php8.4-fpm  # or php-fpm
   ```

3. **Set database values:**
   ```bash
   sqlite3 /var/local/www/db/moode-sqlite3.db << 'SQL'
   UPDATE cfg_system SET value='0' WHERE param='peppy_display';
   UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';
   UPDATE cfg_mpd SET value='alsa' WHERE param='alsa_output_mode';
   UPDATE cfg_mpd SET value='sndrpihifiberry' WHERE param='i2sdevice';
   SQL
   ```

4. **Set file permissions:**
   ```bash
   chown -R www-data:www-data /var/www
   ```

5. **Configure PeppyMeter:**
   ```bash
   sed -i 's/^screen\.width = .*/screen.width = 1280/' /etc/peppymeter/config.txt
   sed -i 's/^screen\.height = .*/screen.height = 400/' /etc/peppymeter/config.txt
   sed -i 's/^exit\.on\.touch = .*/exit.on.touch = True/' /etc/peppymeter/config.txt
   systemctl disable peppymeter
   ```

## Post-Build Verification

After build, run `COMPREHENSIVE_VERIFICATION.sh` to verify:
- [ ] All services enabled and running
- [ ] Web interface works
- [ ] Display rotation works
- [ ] Audio configured correctly
- [ ] PeppyMeter configured correctly
- [ ] No hardcoded IPs
- [ ] File permissions correct

## Next Steps

1. **Update build scripts** to include all fixes
2. **Enhance first-boot-setup.sh** with missing items
3. **Create systemd service** for first-boot-setup
4. **Test build** and verify everything works
5. **Document** any build-specific changes

---

**This checklist ensures all fixes are integrated into the build process.**
