# Quick Fix - Login Screen Instead of Moode

**Problem:** You see login screen, not Moode Audio

---

## IMMEDIATE FIX

### On Pi 5, run:
```bash
./fix_login_screen.sh
```

**Then:**
```bash
# Start X11 if not running
startx

# Or reboot
sudo reboot
```

---

## IF YOU'RE AT LOGIN SCREEN NOW

### Option 1: Get to Console
1. Press `Ctrl+Alt+F1` (or F2, F3)
2. Login with your username/password
3. Run: `startx`

### Option 2: Login and Start X11
1. Login at the login screen
2. After login, run: `startx`

---

## WHAT THE FIX DOES

1. ✅ Checks if X11 is running
2. ✅ Checks if Chromium is running
3. ✅ Checks if xinitrc exists and has Chromium
4. ✅ Creates/fixes xinitrc if needed
5. ✅ Starts X11 if not running

---

## VERIFY AFTER FIX

```bash
# Check X11
ps aux | grep X

# Check Chromium
ps aux | grep chromium

# Check xinitrc
cat ~/.xinitrc | grep chromium
```

---

## IF STILL NOT WORKING

```bash
# Check Moode service
systemctl status moode

# Check if web server is running
curl http://localhost/

# Check X11 logs
cat ~/.xsession-errors

# Check system logs
journalctl -xe | tail -50
```

---

**Run `./fix_login_screen.sh` - it will fix it!**

