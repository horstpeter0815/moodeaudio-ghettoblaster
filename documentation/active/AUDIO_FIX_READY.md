# AUDIO FIX READY

**Date:** 2025-12-04  
**Script:** `fix-audio-hardware-pi5.sh`

---

## 🎯 WHAT THE SCRIPT DOES

### **1. Enables HDMI Audio:**
- Removes `noaudio` from vc4-kms-v3d-pi5 overlay
- Sets `dtparam=audio=on`
- Creates backup of config.txt

### **2. Updates ALSA Configuration:**
- Configures ALSA for HDMI audio (card 1)
- Updates `/etc/asound.conf`

### **3. Updates MPD Configuration:**
- Changes MPD to use HDMI audio device
- Updates mixer device
- Creates backup of mpd.conf

### **4. Restarts MPD:**
- Restarts MPD service to apply changes

### **5. Reboot Required:**
- Asks if you want to reboot now
- Reboot is needed for audio hardware changes

---

## 🚀 HOW TO RUN

### **Option 1: Run the script**
```bash
./fix-audio-hardware-pi5.sh
```

### **Option 2: Review first, then run**
1. Review the script: `cat fix-audio-hardware-pi5.sh`
2. If you approve, run it: `./fix-audio-hardware-pi5.sh`

---

## ⚠️ IMPORTANT NOTES

1. **Backups Created:**
   - `/boot/firmware/config.txt.backup-*`
   - `/etc/mpd.conf.backup-*`

2. **Reboot Required:**
   - Audio hardware changes need a reboot
   - Script will ask if you want to reboot now

3. **After Reboot:**
   - Test audio with: `./test-complete-audio-system.sh`
   - Or manually: `ssh pi2 "mpc play"`

---

## 🔄 ROLLBACK (if needed)

If something goes wrong, you can restore:
```bash
ssh pi2 "sudo cp /boot/firmware/config.txt.backup-* /boot/firmware/config.txt"
ssh pi2 "sudo cp /etc/mpd.conf.backup-* /etc/mpd.conf"
ssh pi2 "sudo reboot"
```

---

**Status:** Script ready - waiting for approval to run

