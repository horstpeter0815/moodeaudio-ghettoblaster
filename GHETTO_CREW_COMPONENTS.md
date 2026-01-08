# GHETTO CREW SYSTEM - COMPONENTS

**Datum:** $(date +"%Y-%m-%d %H:%M:%S")  
**System:** Ghetto Crew  
**Status:** ✅ Komponenten dokumentiert

---

## 🎵 GHETTO CREW SYSTEM

### **1. Ghetto Blaster** 🎵 (Master)
- **Rolle:** Zentrale / Leader
- **Hardware:** Raspberry Pi 5
- **Software:** moOde Audio (Ghetto OS)
- **Display:** 1280x400 + Touchscreen
- **Audio:** HiFiBerry AMP100

### **2. Ghetto Scratch** 🎧 (Slave)
- **Rolle:** Vinyl Player
- **Hardware:** Raspberry Pi Zero 2W
- **Audio:** HiFiBerry ADC Pro
- **Funktion:** Web-Stream zu Ghetto Blaster

### **3. Ghetto Boom** 🔊 (Slave)
- **Rolle:** Linker Lautsprecher
- **Hardware:** Bose 901L + HiFiBerry BeoCreate
- **Audio:** 3-Wege System (Bass, Mitten, Hochton)

### **4. Ghetto Mob** 🔊 (Slave)
- **Rolle:** Rechter Lautsprecher
- **Hardware:** Bose 901R + Custom Board
- **Audio:** 3-Wege System (Bass, Mitten, Hochton)

---

## 🔧 CUSTOM COMPONENTS (Ghetto Blaster)

### **Services** (Systemd)
- `audio-optimize.service`
- `auto-fix-display.service`
- `disable-console.service`
- `enable-ssh-early.service`
- `first-boot-setup.service`
- `fix-network-ip.service`
- `fix-ssh-sudoers.service`
- `fix-user-id.service`
- `ft6236-delay.service`
- `i2c-monitor.service`
- `i2c-stabilize.service`
- `localdisplay.service`
- `network-guaranteed.service`
- `peppymeter-extended-displays.service`
- `peppymeter.service`
- `ssh-guaranteed.service`
- `ssh-ultra-early.service`
- `ssh-watchdog.service`
- `xserver-ready.service`

### **Scripts**
- `analyze-measurement.py`
- `audio-optimize.sh`
- `auto-fix-display.sh`
- `first-boot-setup.sh`
- `fix-network-ip.sh`
- `force-ssh-on.sh`
- `generate-fir-filter.py`
- `i2c-monitor.sh`
- `i2c-stabilize.sh`
- `pcm5122-oversampling.sh`
- `peppymeter-extended-displays.py`
- `start-chromium-clean.sh`
- `worker-php-patch.sh`
- `xserver-ready.sh`

### **Device Tree Overlays**
- `ghettoblaster-amp100.dts`
- `ghettoblaster-ft6236.dts`

### **Audio Presets**
- `ghettoblaster-flat-eq.json`

