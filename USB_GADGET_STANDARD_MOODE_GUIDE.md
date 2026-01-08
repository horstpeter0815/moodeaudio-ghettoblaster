# USB Gadget Mode - Standard moOde Audio Guide

This guide is for **standard moOde Audio downloads** (not custom builds).

## 🎯 Quick Setup

### Option 1: Configure SD Card on Mac (Easiest)

1. **Flash standard moOde image to SD card**

2. **Mount SD card on Mac** (you'll see `bootfs` and `rootfs` partitions)

3. **On Mac - Configure Pi:**
   ```bash
   cd ~/moodeaudio-cursor
   ./SETUP_USB_GADGET_STANDARD_MOODE.sh
   ```

4. **Eject SD card and boot Pi** with USB cable connected to Mac

5. **On Mac - Configure Mac:**
   ```bash
   ./SETUP_USB_GADGET_MAC.sh
   ```

6. **Connect:**
   ```bash
   ssh pi@192.168.10.2
   # or
   ssh moode@192.168.10.2
   ```

---

### Option 2: Configure Running Pi via SSH/WebSSH

If you already have network access to Pi:

1. **On Pi (via SSH or WebSSH):**
   ```bash
   # Download script to Pi first, then:
   sudo bash SETUP_USB_GADGET_STANDARD_MOODE.sh
   ```

2. **Reboot Pi:**
   ```bash
   sudo reboot
   ```

3. **On Mac - Configure Mac:**
   ```bash
   cd ~/moodeaudio-cursor
   ./SETUP_USB_GADGET_MAC.sh
   ```

4. **Connect via USB:**
   ```bash
   ssh pi@192.168.10.2
   ```

---

## 📋 What Gets Configured

### Pi Side:
- ✅ `config.txt`: Adds `dtoverlay=dwc2`
- ✅ `cmdline.txt`: Adds `modules-load=dwc2,g_ether`
- ✅ Systemd service: `usb-gadget-network.service`
- ✅ IP Address: 192.168.10.2

### Mac Side:
- ✅ USB Ethernet interface configured
- ✅ IP Address: 192.168.10.1

---

## 🔍 Finding Your moOde Username

Standard moOde uses different usernames. Try these:

```bash
ssh pi@192.168.10.2
# or
ssh moode@192.168.10.2
# or
ssh root@192.168.10.2
```

Check moOde documentation for the default username, or connect via WebSSH first to see the prompt.

---

## 🆘 Troubleshooting

### SD Card Not Detected

**On Mac:**
- Check Disk Utility - you should see `bootfs` and `rootfs` partitions
- If only one partition visible, SD card may not be properly formatted
- Try ejecting and re-inserting SD card

### Script Fails on Mac

**If you get permission errors:**
```bash
# Make script executable
chmod +x SETUP_USB_GADGET_STANDARD_MOODE.sh

# Try with sudo (if needed)
sudo ./SETUP_USB_GADGET_STANDARD_MOODE.sh
```

### Pi Not Responding After Boot

1. **Wait longer:** USB gadget initialization takes 30-60 seconds
2. **Check Mac network:** Look for new USB Ethernet interface in System Preferences
3. **Check Pi boot:** Look for activity LED or display
4. **Try ping:** `ping 192.168.10.2`

### SSH Connection Refused

1. **Check SSH is enabled on moOde:**
   - Access moOde web interface (if you have network)
   - Go to System > SSH
   - Enable SSH

2. **Or create SSH file on SD card:**
   ```bash
   # On Mac, with SD card mounted:
   touch /Volumes/bootfs/ssh
   ```

---

## 📝 Files Modified

The script creates backups:
- `config.txt.backup`
- `cmdline.txt.backup`

To restore originals:
```bash
cp config.txt.backup config.txt
cp cmdline.txt.backup cmdline.txt
```

---

## ✅ Verification

After setup, verify on Pi:

```bash
# Check USB gadget interface exists
ls /sys/class/net/usb0

# Check IP address
ip addr show usb0

# Should show: 192.168.10.2/24
```

---

## 📖 Related Files

- `SETUP_USB_GADGET_STANDARD_MOODE.sh` - Configure Pi (standard moOde)
- `SETUP_USB_GADGET_MAC.sh` - Configure Mac
- `USB_GADGET_SETUP_CLEAR.md` - General setup guide

