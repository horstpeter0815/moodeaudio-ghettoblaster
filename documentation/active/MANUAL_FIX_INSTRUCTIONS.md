# MANUAL FIX INSTRUCTIONS - Pi 5 Landscape

**Date:** 2025-12-04  
**Status:** SSH connection issue - manual fix needed

---

## 🎯 FIX NEEDED

**Pi 5 Display Issues:**
- Cut off (not full Landscape)
- Sometimes flickers
- Needs to be full Landscape (1280x400)

---

## 🔧 QUICK FIX - 3 COMMANDS

**Execute on Pi 5 (via SSH or console):**

```bash
# 1. Fix config.txt
sudo sed -i '/^display_rotate=/d' /boot/config.txt
sudo sed -i '/display_rotate=/d' /boot/config.txt
sudo sed -i '/^hdmi_group=/d' /boot/config.txt
echo "display_rotate=3" | sudo tee -a /boot/config.txt
echo "hdmi_group=0" | sudo tee -a /boot/config.txt

# 2. Restart display service
sudo systemctl restart localdisplay

# 3. Check result
xrandr --query | grep "HDMI-2 connected"
```

---

## 📋 DETAILED FIX

### **Option 1: Copy Script to Pi 5**

```bash
# From Mac:
scp fix-pi5-landscape-now.sh pi2:/tmp/

# On Pi 5:
ssh pi2
bash /tmp/fix-pi5-landscape-now.sh
```

### **Option 2: Manual Commands**

See script `fix-pi5-landscape-now.sh` for all commands.

---

## ✅ WHAT THIS FIXES

- **display_rotate=3**: Rotates Portrait to Landscape
- **hdmi_group=0**: Standard HDMI (like HiFiBerry Pi 4)
- **Portrait mode in X11**: Rotated to Landscape on display
- **Result**: Full Landscape (1280x400), no cutoff, minimal flickering

---

**Status:** Script ready, execute when Pi 5 is accessible!

