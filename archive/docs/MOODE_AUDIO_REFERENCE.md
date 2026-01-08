# MOODE AUDIO SYSTEM REFERENCE

**Purpose:** Comprehensive reference for moOde Audio player architecture  
**Last Updated:** 2025-12-04

---

## 🎵 SYSTEM OVERVIEW

**moOde Audio** is a music player distribution for Raspberry Pi based on Debian/Raspberry Pi OS.

### **Core Philosophy:**
- Minimal, optimized for audio playback
- Web-based interface
- MPD (Music Player Daemon) as core engine
- Systemd for service management

---

## 🎼 CORE COMPONENTS

### **1. MPD (Music Player Daemon)**

**Purpose:** Core audio playback engine

**Service:** `mpd.service`

**Configuration:** `/etc/mpd.conf`

**Key Features:**
- Local file playback
- Web radio streaming
- Playlist management
- Database management
- Metadata handling

**Dependencies:**
- Audio hardware must be detected
- ALSA or PulseAudio backend
- Music library location configured

**Common Issues:**
- "Audio hardware not found" - Hardware not detected
- Service fails to start - Check audio device configuration
- No sound - Check mixer controls and volume

**Troubleshooting:**
```bash
# Check service status
systemctl status mpd.service

# Check logs
journalctl -u mpd.service -n 50

# Test audio device
aplay -l
alsamixer
```

---

### **2. Web Interface**

**Technology:** PHP-based web application

**Location:** `/var/www/`

**Port:** Typically 80 (HTTP)

**Features:**
- Playback control
- Library management
- Settings configuration
- Metadata display
- Playlist management

**Access:**
- Local: `http://localhost:80`
- Network: `http://<pi-ip>:80`

---

### **3. Display Services**

#### **localdisplay.service**

**Purpose:** Manages local display output

**Technology:** Xorg (X11) on moOde

**Dependencies:**
- X server must be running
- Display hardware connected
- User permissions configured

**Configuration:**
- Service: `/etc/systemd/system/localdisplay.service`
- Override: `/etc/systemd/system/localdisplay.service.d/override.conf`
- X Session: `/home/<user>/.xinitrc`

**X Server Configuration:**
- Main Config: `/etc/X11/xorg.conf` (if exists)
- Snippets: `/etc/X11/xorg.conf.d/*.conf`
- User Config: `/home/<user>/.xinitrc`

**Common Issues:**
- X server fails to start - Check display hardware
- Permissions denied - Configure `xhost`
- Wrong resolution - Check `xrandr` and config

**Troubleshooting:**
```bash
# Check service status
systemctl status localdisplay.service

# Check X server
ps aux | grep X
xrandr --query

# Check permissions
xhost
```

#### **Chromium Kiosk Mode**

**Purpose:** Display web interface fullscreen

**Launch Command:**
```bash
chromium-browser --kiosk --no-sandbox --user-data-dir=/tmp/chromium-data http://localhost:80
```

**Key Flags:**
- `--kiosk` - Fullscreen kiosk mode
- `--no-sandbox` - Required when running as root
- `--user-data-dir` - User data directory
- URL - Web interface address

**Configuration:**
- Typically in `/home/<user>/.xinitrc`
- Started by `localdisplay.service`

---

### **4. Audio System**

#### **ALSA (Advanced Linux Sound Architecture)**

**Purpose:** Low-level audio interface

**Tools:**
- `aplay` - Play audio files
- `arecord` - Record audio
- `alsamixer` - Mixer control
- `amixer` - Command-line mixer

**Device Detection:**
```bash
# List audio devices
aplay -l

# List mixer controls
amixer scontrols
```

**Mixer Configuration:**
- Controls: Volume, mute, etc.
- Device: Specified in MPD config
- Default: Often "PCM" or "Master"

#### **Audio Hardware**

**Types:**
- HDMI audio
- USB DAC
- I2S DAC (HiFiBerry, etc.)
- Analog output (3.5mm jack)

**Configuration:**
- Automatic detection (preferred)
- Manual configuration in `/etc/mpd.conf`
- Device selection in moOde web interface

---

### **5. Systemd Services**

#### **Key Services:**

**mpd.service:**
- **Purpose:** Music Player Daemon
- **Config:** `/etc/mpd.conf`
- **Dependencies:** Audio hardware

**localdisplay.service:**
- **Purpose:** Display management
- **Dependencies:** X server, display hardware
- **Config:** `/home/<user>/.xinitrc`

**peppymeter.service:**
- **Purpose:** Audio visualizer
- **Dependencies:** MPD, X server
- **Location:** `/opt/peppymeter/`

#### **Service Dependencies:**

**Syntax:**
```ini
[Unit]
After=service1.service
Requires=service2.service
Wants=service3.service
```

**Types:**
- `After=` - Start after this service
- `Requires=` - Hard dependency (fails if dependency fails)
- `Wants=` - Soft dependency (continues if dependency fails)

**Example:**
```ini
[Unit]
After=localdisplay.service
Requires=localdisplay.service

[Service]
ExecStartPre=/bin/bash -c "until [ -S /tmp/.X11-unix/X0 ]; do sleep 1; done"
Environment=DISPLAY=:0
```

---

### **6. Configuration Files**

#### **System Configuration:**

**Boot:**
- `/boot/firmware/config.txt` - Boot configuration (Pi 5)
- `/boot/firmware/cmdline.txt` - Kernel parameters (Pi 5)

**MPD:**
- `/etc/mpd.conf` - MPD configuration

**Systemd:**
- `/etc/systemd/system/` - Service definitions
- `/etc/systemd/system/<service>.service.d/override.conf` - Service overrides

#### **User Configuration:**

**X Server:**
- `/home/<user>/.xinitrc` - X session startup
- `/home/<user>/.Xauthority` - X authentication

**X Server Config:**
- `/etc/X11/xorg.conf.d/*.conf` - Configuration snippets
- `/etc/X11/xorg.conf` - Main config (if exists)

---

## 🔧 COMMON CONFIGURATIONS

### **Display Setup (1280x400 Landscape):**

**config.txt:**
```ini
display_rotate=3
hdmi_group=0
```

**xinitrc:**
```bash
#!/bin/sh
xhost +SI:localuser:andre
chromium-browser --kiosk --no-sandbox --user-data-dir=/tmp/chromium-data http://localhost:80 &
```

### **Touchscreen Configuration:**

**Xorg Config:**
```ini
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchProduct "WaveShare"
    Driver "libinput"
    Option "CalibrationMatrix" "0 -1 1 1 0 0 0 0 1"
    Option "SendEventsMode" "enabled"
EndSection
```

**xinitrc:**
```bash
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)
xinput enable "$WAVESHARE_ID"
xinput set-prop "$WAVESHARE_ID" "libinput Send Events Mode Enabled" 1 0
xinput set-prop "$WAVESHARE_ID" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
```

---

## 🛠️ TROUBLESHOOTING

### **MPD Issues:**

**Service won't start:**
```bash
# Check status
systemctl status mpd.service

# Check logs
journalctl -u mpd.service -n 50

# Check audio device
aplay -l
```

**No sound:**
```bash
# Check mixer
alsamixer
amixer sget Master

# Test playback
aplay /usr/share/sounds/alsa/Front_Left.wav
```

### **Display Issues:**

**X server won't start:**
```bash
# Check service
systemctl status localdisplay.service

# Check logs
journalctl -u localdisplay.service -n 50

# Check display hardware
xrandr --query
```

**Chromium not displaying:**
```bash
# Check if running
pgrep -f chromium

# Check window
xdotool search --classname chromium

# Check permissions
xhost
```

### **Service Dependencies:**

**Service fails to start:**
```bash
# Check dependencies
systemctl list-dependencies <service>

# Check if dependencies are running
systemctl is-active <dependency>

# Check service file
systemctl cat <service>
```

---

## 📚 REFERENCES

- **moOde Audio:** [moodeaudio.org](https://moodeaudio.org/)
- **MPD Documentation:** [musicpd.org](https://www.musicpd.org/)
- **Systemd Documentation:** [freedesktop.org](https://www.freedesktop.org/software/systemd/man/)
- **X11 Documentation:** [x.org](https://www.x.org/)

---

**Status:** Active reference document - update as new information is discovered

