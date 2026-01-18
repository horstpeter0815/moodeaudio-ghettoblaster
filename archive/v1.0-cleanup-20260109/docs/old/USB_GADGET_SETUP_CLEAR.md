# USB Gadget Mode Setup - Clear Instructions

## 🎯 Where to Run Each Command

### Option A: Configure BEFORE Building (Recommended - Mac Only)

**Run ALL commands on your Mac:**

1. **Configure Pi files (on Mac, before building):**
   ```bash
   cd ~/moodeaudio-cursor
   ./SETUP_USB_GADGET_MODE.sh
   ```
   - ✅ This modifies files in `moode-source/` directory
   - ✅ USB gadget mode will be included in your next build
   - ✅ No need to configure Pi after flashing

2. **Build your image:**
   ```bash
   ./tools/build.sh --deploy
   ```

3. **Flash SD card and boot Pi**

4. **Configure Mac (after Pi boots):**
   ```bash
   ./SETUP_USB_GADGET_MAC.sh
   ```
   - ✅ This runs on Mac only
   - ✅ Configures Mac's USB Ethernet interface

5. **Connect:**
   ```bash
   ssh andre@192.168.10.2
   ```

---

### Option B: Configure AFTER Flashing (Mac + SD Card)

**If you already have a flashed SD card:**

1. **Mount SD card on Mac** (bootfs and rootfs partitions)

2. **Configure Pi files (on Mac, with SD card mounted):**
   ```bash
   cd ~/moodeaudio-cursor
   ./SETUP_USB_GADGET_MODE.sh
   ```
   - ✅ Script detects mounted SD card automatically
   - ✅ Modifies files directly on SD card

3. **Eject SD card and boot Pi**

4. **Configure Mac (after Pi boots):**
   ```bash
   ./SETUP_USB_GADGET_MAC.sh
   ```
   - ✅ This runs on Mac only

5. **Connect:**
   ```bash
   ssh andre@192.168.10.2
   ```

---

### Option C: Configure on Running Pi (Pi via SSH/WebSSH)

**If Pi is already running and you have network access:**

1. **On Pi (via SSH or WebSSH):**
   ```bash
   # Download or copy SETUP_USB_GADGET_MODE.sh to Pi
   # Then run:
   sudo bash SETUP_USB_GADGET_MODE.sh
   ```
   - ⚠️ This modifies Pi's boot files directly
   - ⚠️ Requires reboot to take effect

2. **Reboot Pi:**
   ```bash
   sudo reboot
   ```

3. **On Mac (after Pi reboots):**
   ```bash
   cd ~/moodeaudio-cursor
   ./SETUP_USB_GADGET_MAC.sh
   ```
   - ✅ This runs on Mac only

4. **Connect:**
   ```bash
   ssh andre@192.168.10.2
   ```

---

## 📋 Command Summary

| Command | Where to Run | When |
|---------|--------------|------|
| `./SETUP_USB_GADGET_MODE.sh` | **Mac** (modifies SD card files) | Before building OR after flashing (SD card mounted) |
| `./SETUP_USB_GADGET_MODE.sh` | **Pi** (via SSH/WebSSH) | If Pi is already running |
| `./SETUP_USB_GADGET_MAC.sh` | **Mac ONLY** | After Pi boots with USB cable |

## 🔍 How to Tell Where You Are

**On Mac:**
- Terminal prompt shows: `username@MacBook-Pro` or similar
- You can run: `uname -a` → shows `Darwin`

**On Pi (via SSH/WebSSH):**
- Terminal prompt shows: `andre@GhettoBlaster` or `pi@raspberrypi`
- You can run: `uname -a` → shows `Linux`

## ❓ Which Option Should I Use?

- **Option A** if: You're building a new image
- **Option B** if: You already have a flashed SD card
- **Option C** if: Pi is already running and you have network access

## 🆘 Still Confused?

**Simplest approach:**

1. **On Mac:** Run `./SETUP_USB_GADGET_MODE.sh` (configures build files)
2. **On Mac:** Build image with `./tools/build.sh --deploy`
3. **On Mac:** Flash SD card and boot Pi
4. **On Mac:** Run `./SETUP_USB_GADGET_MAC.sh` (configures Mac)
5. **On Mac:** Connect with `ssh andre@192.168.10.2`

**All Mac commands, no Pi access needed!**

