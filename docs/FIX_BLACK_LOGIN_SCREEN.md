# 🔧 Fix Black Login Screen Issue

**Problem:** Display shows black login screen instead of moOde web UI

---

## 🔍 Diagnosis Steps

Run these commands **directly on the Pi** (via SSH or console):

### 1. Check Chromium Status
```bash
# Check if Chromium is running
ps aux | grep chromium | grep -v grep

# Check Chromium process count
pgrep -f chromium | wc -l
```

### 2. Check Display Service
```bash
# Check localdisplay service status
sudo systemctl status localdisplay.service

# Check if service is enabled
systemctl is-enabled localdisplay.service
```

### 3. Check Web Server
```bash
# Check Apache status
sudo systemctl status apache2

# Test if web server responds
curl -I http://localhost/
```

### 4. Check X11 Display
```bash
# Check X11 is running
DISPLAY=:0 xdpyinfo | head -5

# Check what windows are open
DISPLAY=:0 xwininfo -root -tree | head -20
```

### 5. Check Chromium Logs
```bash
# View recent Chromium logs
tail -50 /var/log/chromium-clean.log

# Check for errors
grep -i error /var/log/chromium-clean.log | tail -10
```

### 6. Check for Login Screen
```bash
# Check if login manager is running
systemctl status lightdm 2>/dev/null
systemctl status gdm 2>/dev/null

# Check what's on display
DISPLAY=:0 xwininfo -root -tree | grep -i "login\|lightdm\|gdm"
```

---

## 🔧 Fix Solutions

### Fix 1: Restart Display Service
```bash
sudo systemctl restart localdisplay.service
sudo systemctl status localdisplay.service
```

### Fix 2: Manually Start Chromium
```bash
# Kill existing Chromium (if stuck)
pkill -9 chromium

# Start Chromium manually
DISPLAY=:0 /usr/local/bin/start-chromium-clean.sh

# Check if it started
ps aux | grep chromium | grep -v grep
```

### Fix 3: Disable Login Screen (if blocking)
```bash
# Disable lightdm (if installed)
sudo systemctl disable lightdm
sudo systemctl stop lightdm

# Disable gdm (if installed)
sudo systemctl disable gdm
sudo systemctl stop gdm

# Restart display service
sudo systemctl restart localdisplay.service
```

### Fix 4: Fix Web Server (if not running)
```bash
# Restart Apache
sudo systemctl restart apache2
sudo systemctl status apache2

# Test web server
curl http://localhost/
```

### Fix 5: Re-enable Display Service
```bash
# Enable and start service
sudo systemctl enable localdisplay.service
sudo systemctl start localdisplay.service

# Check status
sudo systemctl status localdisplay.service
```

### Fix 6: Check .xinitrc Configuration
```bash
# Check user's .xinitrc
cat ~/.xinitrc

# Should contain Chromium start command
# If missing, check default:
cat /home/andre/xinitrc.default
```

---

## 🎯 Most Common Causes

### 1. Login Screen Blocking
**Symptom:** Black screen with login prompt
**Fix:** Disable login manager (lightdm/gdm)

### 2. Chromium Not Starting
**Symptom:** No Chromium process running
**Fix:** Restart localdisplay.service or start manually

### 3. Web Server Not Ready
**Symptom:** Chromium starts but shows error page
**Fix:** Restart Apache and wait for it to be ready

### 4. X11 Not Running
**Symptom:** Cannot access DISPLAY=:0
**Fix:** Check X11 service, restart if needed

### 5. Chromium Crashed
**Symptom:** Chromium process exists but no window
**Fix:** Kill and restart Chromium

---

## 📋 Quick Fix Sequence

Run these commands in order:

```bash
# 1. Kill stuck processes
pkill -9 chromium
pkill -9 Xorg

# 2. Disable login screen
sudo systemctl disable lightdm gdm 2>/dev/null
sudo systemctl stop lightdm gdm 2>/dev/null

# 3. Restart web server
sudo systemctl restart apache2

# 4. Wait for web server
sleep 3

# 5. Restart display service
sudo systemctl restart localdisplay.service

# 6. Wait and check
sleep 5
ps aux | grep chromium | grep -v grep
```

---

## 🔍 Verify Fix

After applying fixes, verify:

```bash
# 1. Chromium is running
ps aux | grep chromium | grep -v grep
# Should show chromium process

# 2. Web server is running
curl -I http://localhost/
# Should return HTTP 200

# 3. Display shows content
DISPLAY=:0 xwininfo -root -tree | grep -i chromium
# Should show Chromium window

# 4. Check logs for errors
tail -20 /var/log/chromium-clean.log
# Should not show critical errors
```

---

## 📝 Notes

- **Login Screen:** If a login manager (lightdm/gdm) is enabled, it can block Chromium from starting
- **Web Server:** Chromium waits for web server to be ready, but if it times out, it may show a blank page
- **X11:** X11 must be running before Chromium can start
- **Permissions:** Chromium needs to run as the correct user (usually `andre`)

---

**Last Updated:** 2025-01-12
