# Login Screen Fix - Moode Audio Not Starting

**Problem:** Login screen showing instead of Moode Audio

---

## QUICK FIX

```bash
./fix_login_screen.sh
```

**Then:**
```bash
# If X11 not running, start it:
startx

# Or reboot:
sudo reboot
```

---

## THE PROBLEM

**Possible causes:**
1. X11 not started
2. Chromium not in xinitrc
3. xinitrc missing or broken
4. Display manager (LightDM/GDM) showing login screen
5. X11 crashed or failed to start

---

## MANUAL FIX

### Step 1: Check X11
```bash
ps aux | grep X
ps aux | grep Xorg
```

**If not running:**
```bash
startx
```

### Step 2: Check Chromium
```bash
ps aux | grep chromium
```

**If not running:**
```bash
# Check xinitrc
cat ~/.xinitrc

# If missing Chromium, add it
```

### Step 3: Check xinitrc
```bash
# Check if exists
ls -la ~/.xinitrc

# Check if executable
chmod +x ~/.xinitrc

# Check content
cat ~/.xinitrc | grep chromium
```

### Step 4: Fix xinitrc
```bash
# If xinitrc is missing Chromium, run:
./fix_login_screen.sh
```

---

## IF YOU SEE LOGIN SCREEN

### Option 1: Get to Console
1. Press `Ctrl+Alt+F1` (or F2, F3)
2. Login
3. Run: `startx`

### Option 2: Disable Display Manager
```bash
# Check if LightDM/GDM is running
systemctl status lightdm
systemctl status gdm

# Disable if running
sudo systemctl disable lightdm
sudo systemctl disable gdm
sudo reboot
```

### Option 3: Start X11 Manually
```bash
# From console (Ctrl+Alt+F1)
startx
```

---

## VERIFY MOODE IS RUNNING

```bash
# Check Moode web server
systemctl status moode

# Check if accessible
curl http://localhost/

# Check Chromium
ps aux | grep chromium
```

---

## COMPLETE FIX

```bash
# Run fix script
./fix_login_screen.sh

# If X11 not running, start it
startx

# Or reboot
sudo reboot
```

---

## AFTER FIX

**You should see:**
- ✅ Moode Audio web interface
- ✅ Chromium in kiosk mode
- ✅ No login screen

**If still login screen:**
1. Check: `ps aux | grep chromium`
2. Check: `ps aux | grep X`
3. Check: `cat ~/.xinitrc`
4. Run: `./fix_login_screen.sh` again
5. Reboot: `sudo reboot`

---

**Run the fix script. It will diagnose and fix the issue.**

