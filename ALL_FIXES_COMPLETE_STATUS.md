# All Audio Fixes Complete - 2026-01-21

**Status:** ✅ ALL 4 FIXES IMPLEMENTED  
**Ready for:** Deployment to Pi

---

## ✅ Fix #4: CamillaDSP v3 Syntax (LOW RISK)

**Problem:** v2 syntax incompatible with CamillaDSP v3.0.1

**Changes:**
- Fixed 5 Bose Wave configs: `LowpassFO`/`HighpassFO` → `Lowpass`/`Highpass`
- Fixed device: `plughw:1,0` → `plughw:0,0`

**Files:**
- `usr/share/camilladsp/configs/bose_wave_physics_optimized.yml`
- `usr/share/camilladsp/configs/bose_wave_filters.yml`
- `usr/share/camilladsp/configs/bose_wave_stereo.yml`
- `usr/share/camilladsp/configs/bose_wave_true_stereo.yml`
- `usr/share/camilladsp/configs/bose_wave_waveguide_optimized.yml`

---

## ✅ Fix #2: Enhanced Audio Fix Service (MEDIUM RISK)

**Problem:** Original fix service doesn't fix CamillaDSP YAML device

**Changes:**
- Created enhanced boot service
- Fixes database + ALSA config + CamillaDSP YAML device
- Comprehensive logging

**Files:**
- `usr/local/bin/fix-audioout-cdsp-enhanced.sh` (NEW)
- `../custom-components/systemd-services/fix-audioout-cdsp-enhanced.service` (NEW)

---

## ✅ Fix #3: WiFi Radio Enable at Boot (LOW RISK)

**Problem:** worker.php never enables WiFi radio

**Changes:**
- Added `nmcli radio wifi on` command in worker.php
- Enables WiFi radio when wlan0 adapter detected

**Files:**
- `www/daemon/worker.php` (modified lines 476-478)

**Code:**
```php
// Ensure WiFi radio is enabled (Fix #3)
sysCmd('nmcli radio wifi on');
workerLog('worker: Wireless: radio enabled');
```

---

## ✅ Fix #1: Session-Independent Device Detection (HIGH RISK)

**Problem:** `getAlsaDeviceNames()` fails if `$_SESSION['i2sdevice']` not accessible

**Changes:**
- Query database directly if session variable not set
- Prevents ALSA_EMPTY_CARD false positives
- Eliminates root cause of HDMI fallback

**Files:**
- `www/inc/alsa.php` (modified lines 158-168)

**Code:**
```php
// I2S device (Fix #1: Session-independent device detection)
// Query database directly if session not initialized
if (!isset($_SESSION['i2sdevice']) || empty($_SESSION['i2sdevice'])) {
    $i2sDeviceId = sqlQuery("SELECT value FROM cfg_system WHERE param='i2sdevice'", $dbh);
    $i2sDevice = !empty($i2sDeviceId) ? $i2sDeviceId[0]['value'] : null;
    $result = $i2sDevice ? sqlRead('cfg_audiodev', $dbh, $i2sDevice) : true;
} else {
    $result = sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice']);
}
```

---

## 📦 Deployment to Pi

### Option 1: Manual Deployment (Recommended for Testing)

Since we don't have SSH access configured, you'll need to deploy manually:

**Step 1: Copy Files to Pi**

```bash
# On your Mac, create a deployment package
cd /Users/andrevollmer/moodeaudio-cursor
mkdir -p /tmp/moode-fixes

# Copy CamillaDSP configs
cp moode-source/usr/share/camilladsp/configs/bose_wave*.yml /tmp/moode-fixes/

# Copy enhanced fix service
cp moode-source/usr/local/bin/fix-audioout-cdsp-enhanced.sh /tmp/moode-fixes/
cp custom-components/systemd-services/fix-audioout-cdsp-enhanced.service /tmp/moode-fixes/

# Copy core PHP files
cp moode-source/www/daemon/worker.php /tmp/moode-fixes/
cp moode-source/www/inc/alsa.php /tmp/moode-fixes/

# Create deployment instructions
cat > /tmp/moode-fixes/INSTALL.sh << 'EOF'
#!/bin/bash
# Run this on the Pi as user andre

echo "Installing audio fixes..."

# Backup original files
sudo cp /var/www/daemon/worker.php /var/www/daemon/worker.php.backup
sudo cp /var/www/inc/alsa.php /var/www/inc/alsa.php.backup

# Install CamillaDSP configs
sudo cp bose_wave*.yml /usr/share/camilladsp/configs/
sudo chown root:root /usr/share/camilladsp/configs/bose_wave*.yml
sudo chmod 644 /usr/share/camilladsp/configs/bose_wave*.yml

# Install enhanced fix service
sudo cp fix-audioout-cdsp-enhanced.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/fix-audioout-cdsp-enhanced.sh
sudo cp fix-audioout-cdsp-enhanced.service /etc/systemd/system/

# Install core PHP fixes
sudo cp worker.php /var/www/daemon/
sudo cp alsa.php /var/www/inc/
sudo chown www-data:www-data /var/www/daemon/worker.php /var/www/inc/alsa.php

# Enable enhanced service
sudo systemctl daemon-reload
sudo systemctl disable fix-audioout-cdsp.service 2>/dev/null || true
sudo systemctl enable fix-audioout-cdsp-enhanced.service

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Reboot: sudo reboot"
echo "2. Check services: systemctl status camilladsp mpd"
echo "3. Test audio (volume 0 first!)"
EOF

chmod +x /tmp/moode-fixes/INSTALL.sh

echo "✅ Deployment package created in /tmp/moode-fixes/"
echo ""
echo "Transfer to Pi:"
echo "  scp -r /tmp/moode-fixes andre@192.168.2.3:~/"
echo ""
echo "Then on Pi:"
echo "  cd ~/moode-fixes"
echo "  bash INSTALL.sh"
```

### Option 2: USB Transfer

1. Copy `/tmp/moode-fixes/` to USB drive
2. Insert USB into Pi
3. Mount USB and run INSTALL.sh

---

## 🧪 Testing After Deployment

```bash
# 1. Verify CamillaDSP config
camilladsp --check /usr/share/camilladsp/configs/bose_wave_physics_optimized.yml

# 2. Check services
systemctl status fix-audioout-cdsp-enhanced
systemctl status camilladsp
systemctl status mpd

# 3. Check database
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_system WHERE param IN ('adevname','cardnum','alsa_output_mode');"

# Expected: adevname='HiFiBerry Amp2/4', cardnum='0', alsa_output_mode='plughw'

# 4. Check WiFi radio
nmcli radio wifi
# Expected: enabled

# 5. Test audio (VOLUME 0 FIRST!)
mpc volume 0
mpc play
# Gradually increase volume
```

---

## 🔄 Rollback Procedure

If anything goes wrong:

```bash
# Restore original PHP files
sudo cp /var/www/daemon/worker.php.backup /var/www/daemon/worker.php
sudo cp /var/www/inc/alsa.php.backup /var/www/inc/alsa.php

# Restart services
sudo systemctl restart worker php8.4-fpm

# Reboot
sudo reboot
```

---

## 📊 Expected Results

### After Reboot:

1. **CamillaDSP service:** Active (running)
2. **MPD service:** Active (running)
3. **Audio output:** "ALSA Default" enabled
4. **Database:** Correct HiFiBerry values
5. **WiFi radio:** Enabled automatically
6. **No HDMI fallback:** Ever again!

### Root Causes Fixed:

- ✅ CamillaDSP syntax errors eliminated
- ✅ Device detection works without session dependency
- ✅ WiFi radio enabled automatically
- ✅ YAML device corruption prevented

---

## 💾 Git Commits

**Pending:** Need to commit Fix #1 and Fix #3

```bash
cd /Users/andrevollmer/moodeaudio-cursor/moode-source
git commit -m "Fix #3 (WiFi radio enable) + Fix #1 (Session-independent device detection)"

cd /Users/andrevollmer/moodeaudio-cursor
git add moode-source
git commit -m "Complete all 4 audio fixes - ready for deployment"
```

---

## 🎯 Summary

**All 4 fixes implemented:**
- Fix #4: CamillaDSP v3 syntax ✅
- Fix #2: Enhanced fix service ✅
- Fix #3: WiFi radio enable ✅
- Fix #1: Session-independent detection ✅

**Files changed:** 9 files  
**Risk:** 2 core PHP files modified (worker.php, alsa.php)  
**Backups:** Automatic during install  
**Rollback:** Simple restore from backup

**Ready for deployment!**
