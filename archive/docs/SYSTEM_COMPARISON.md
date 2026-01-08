# SYSTEM COMPARISON: Pi 4 vs Pi 5

**Purpose:** Document system-specific differences to prevent configuration mistakes

---

## 📁 BOOT CONFIGURATION PATHS

### **Raspberry Pi 4:**
- `/boot/config.txt` - Main boot configuration
- `/boot/cmdline.txt` - Kernel command line

### **Raspberry Pi 5:**
- `/boot/config.txt` - May exist but not always used
- `/boot/firmware/config.txt` - **Primary boot configuration**
- `/boot/firmware/cmdline.txt` - **Primary kernel command line**

**⚠️ IMPORTANT:** Always check BOTH locations on Pi 5!

---

## 🖥️ DISPLAY SERVER

### **Raspberry Pi 4 (HiFiBerryOS):**
- Uses **Wayland (Weston)**
- Display service: `weston.service`
- Configuration: Wayland-specific

### **Raspberry Pi 5 (moOde):**
- Uses **Xorg (X11)**
- Display service: `localdisplay.service`
- Configuration: X11-specific (`.xinitrc`, `xorg.conf.d`)

---

## 👤 USER & PERMISSIONS

### **Raspberry Pi 4:**
- X server runs as: **root**
- User: Usually `root` or system user

### **Raspberry Pi 5:**
- X server runs as: **root**
- User: `andre`
- **Requires:** `xhost +SI:localuser:andre` for X permissions

---

## 🔧 SERVICE CONFIGURATION

### **Systemd Overrides:**
- Location: `/etc/systemd/system/<service>.service.d/override.conf`
- **Important:** Must clear `ExecStart=` before setting new one
- Exception: `Type=oneshot` services can have multiple `ExecStart`

### **Service Dependencies:**
- Always check `After=`, `Requires=`, `Wants=` in service files
- Verify dependencies are running before starting dependent service

---

## 📡 NETWORK

### **IP Address Detection:**
- Pi 4: `moodepi4.local` or `pi3` alias
- Pi 5: `ghettopi4.local` or `pi2` alias
- **Issue:** IP addresses can change
- **Solution:** Use mDNS names or implement auto-detection

---

## 🎨 DISPLAY ROTATION

### **Configuration:**
- Parameter: `display_rotate=N` in `config.txt`
- Values:
  - `0` = 0° (no rotation)
  - `1` = 90° clockwise
  - `2` = 180°
  - `3` = 270° clockwise (Portrait → Landscape)

### **Verification:**
- Check framebuffer: `cat /sys/class/graphics/fb0/virtual_size`
- Check X11: `xrandr --query`
- Check boot screen: Visual inspection after reboot

---

## 🖱️ TOUCHSCREEN

### **Device Detection:**
- Command: `xinput list`
- Look for: "WaveShare" device
- Get ID: `xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+'`

### **Configuration:**
- Calibration matrix: `Coordinate Transformation Matrix`
- Event handling: `libinput Send Events Mode Enabled`
- Xorg config: `/etc/X11/xorg.conf.d/40-libinput-touchscreen.conf`

### **Common Issues:**
- Touch events detected but not converted to pointer events
- Solution: Touch-to-pointer bridge or X server configuration

---

## 🎵 AUDIO SERVICES

### **MPD (Music Player Daemon):**
- Service: `mpd.service`
- Configuration: `/etc/mpd.conf`
- **Dependency:** Audio hardware must be detected
- **Issue:** "Audio hardware not found" = MPD won't start

### **PeppyMeter:**
- Location: `/opt/peppymeter`
- Resolution configs: `1280x400`, `800x480`, etc.
- **Dependency:** Requires MPD or audio source
- **Issue:** Exits immediately if no audio source

---

## ✅ VERIFICATION CHECKLIST

### **After Configuration Changes:**
- [ ] Check all relevant config files (both `/boot/` and `/boot/firmware/`)
- [ ] Verify changes persisted (grep for parameter)
- [ ] Test service start/stop
- [ ] Check service logs for errors
- [ ] Verify display/output works
- [ ] Document changes made

### **Before Service Configuration:**
- [ ] Check service dependencies
- [ ] Verify required services are running
- [ ] Research systemd override syntax
- [ ] Test service manually first
- [ ] Check system-specific requirements

---

**Last Updated:** 2025-12-04  
**Status:** Active reference document

