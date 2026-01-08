# EXECUTE THIS NOW ON PI 5

## OPTION 1: Copy script to Pi 5 and run it

```bash
# On Pi 5 console (Ctrl+Alt+F1 if at login screen):
cd /path/to/cursor
chmod +x MASTER_FIX_ALL.sh
./MASTER_FIX_ALL.sh
```

## OPTION 2: From Mac, execute remotely

```bash
# On your Mac:
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
./EXECUTE_REMOTELY.sh [PI5_IP] [USER]

# Example:
./EXECUTE_REMOTELY.sh 192.168.178.20 pi
```

## OPTION 3: One-liner on Pi 5

```bash
# Copy this entire command and paste on Pi 5:
curl -sSL https://raw.githubusercontent.com/.../MASTER_FIX_ALL.sh | bash
# OR if script is already on Pi 5:
chmod +x MASTER_FIX_ALL.sh && ./MASTER_FIX_ALL.sh
```

---

**THE MASTER_FIX_ALL.sh SCRIPT DOES EVERYTHING:**
- ✅ Kills old processes
- ✅ Disables display managers
- ✅ Fixes xinitrc
- ✅ Fixes touchscreen
- ✅ Starts X11
- ✅ Launches Chromium

**JUST RUN IT ON PI 5 NOW.**

