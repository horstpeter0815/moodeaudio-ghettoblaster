# 🎬 COMPLETE VIDEO CHAIN MAPPING

**Date:** $(date +"%Y-%m-%d %H:%M:%S")  
**Purpose:** Complete mapping of video chain from boot to display, capturing EVERY rotation point

---

## 📋 Video Chain Overview

The video chain flows through these layers:
1. **Boot Configuration** (config.txt, cmdline.txt)
2. **Kernel/Firmware** (Framebuffer, DRM/KMS)
3. **X11 Server** (Xorg)
4. **Display Manager** (.xinitrc, Moode logic)
5. **Applications** (Chromium, PeppyMeter)
6. **Hardware** (HDMI output, physical display)

---

**config.txt Display Settings:**
```ini
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_enable_4kp60=0
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100,automute
dtoverlay=vc4-kms-v3d
max_framebuffers=2
display_auto_detect=1
hdmi_drive=2
hdmi_blanking=1
hdmi_force_edid_audio=1
hdmi_force_hotplug=1
hdmi_group=0
```

**Rotation Point 1:** config.txt → NO display_rotate (default: 0)

**DRM/KMS Overlay:** vc4-kms-v3d
- **Location:** /boot/firmware/config.txt
- **Effect:** Enables DRM/KMS driver for display

**cmdline.txt:**
```
console=null console=tty1 root=PARTUUID=585bdb7b-02 rootfstype=ext4 fsck.repair=yes rootwait fbcon=rotate:1
```

**Rotation Point 3:** cmdline.txt → fbcon=rotate
- **Location:** /boot/firmware/cmdline.txt
- **Parameter:** fbcon=rotate:1
- **Effect:** Console framebuffer rotation
- **Values:** 0=none, 1=90°, 2=180°, 3=270°

**Framebuffer State:**
```

mode "400x1280"
    geometry 400 1280 400 1280 16
    timings 0 0 0 0 0 0 0
    rgba 5/11,6/5,5/0,0/0
endmode
```

**Rotation Point 4:** Framebuffer → Geometry 400x1280
- **Location:** Kernel framebuffer (/dev/fb0)
- **Current:** 400x1280
- **Effect:** Base resolution before X11

**Runtime Kernel Cmdline:**
```
reboot=w coherent_pool=1M 8250.nr_uarts=1 pci=pcie_bus_safe cgroup_disable=memory numa_policy=interleave nvme.max_host_mem_size_mb=0  numa=fake=8 system_heap.max_order=0 smsc95xx.macaddr=88:A2:9E:2C:8E:55 vc_mem.mem_base=0x3fc00000 vc_mem.mem_size=0x40000000  console=null console=tty1 root=PARTUUID=585bdb7b-02 rootfstype=ext4 fsck.repair=yes rootwait fbcon=rotate:1
```

**X11 Display State:**
- **Dimensions:** 1280x400
- **Location:** X Server (DISPLAY=:0)

**Rotation Point 5:** xrandr → HDMI-1
- **Location:** X11 xrandr (runtime)
- **Output:** HDMI-1
- **Mode:** 1280x400
- **Rotation:** left
- **Effect:** X11 display rotation (applied by .xinitrc or scripts)

**Full xrandr Output:**
```
Screen 0: minimum 320 x 200, current 1280 x 400, maximum 8192 x 8192
HDMI-1 connected primary 1280x400+0+0 left (normal left inverted right x axis y axis) 0mm x 0mm
   400x1280      59.51*+
   1280x720     100.00  
HDMI-2 disconnected (normal left inverted right x axis y axis)
```

**.xinitrc Rotation Logic:**
```bash
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")
DSI_PORT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_port'")
DSI_SCN_ROTATE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_rotate'")
PI_MODEL=$(/var/www/util/pirev.py | awk -F"\t" '{print $2}' | cut -c 1)

# Get screen res (use W,H for chromium)
fgrep "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt
if [ $? -ne 0 ]; then
	if [ $DSI_SCN_TYPE = 'none' ]; then
		# HDMI screen
	    SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
	else
		# DSI screen
		SCREEN_RES=$(kmsprint --modes | awk '$1 == "0" {print $2}' | cut -d"@" -f1 | awk -F"x" '{print $1","$2}')
	fi
else
    SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')
fi

# Set screen rotation
if [ $DSI_SCN_TYPE = 'none' ]; then
	# HDMI screens (default is landscape)
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output HDMI-1 --rotate left
    fi
elif [ $DSI_SCN_TYPE = '2' ] || [ $DSI_SCN_TYPE = 'other' ]; then
	# DSI screens (use size WxH for --mode)
	SCREEN_RES_DSI=$(echo $SCREEN_RES | awk -F"," '{print $1"x"$2}')
	# 1X ports use DSI-1 | 2X ports use DSI-1-1 or DSI-1-2
	[[ $PI_MODEL = "5" ]] && DSI_PORT_NAME="DSI-1-$DSI_PORT" || DSI_PORT_NAME="DSI-$DSI_PORT"
    if [ $DSI_SCN_ROTATE = "0" ]; then
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate normal --mode $SCREEN_RES_DSI
    elif [ $DSI_SCN_ROTATE = "90" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate right --mode $SCREEN_RES_DSI
    elif [ $DSI_SCN_ROTATE = "180" ]; then
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate inverted --mode $SCREEN_RES_DSI
    elif [ $DSI_SCN_ROTATE = "270" ]; then
```

**Rotation Point 6:** .xinitrc → fix-display-orientation-before-peppy.sh
- **Location:** /home/andre/.xinitrc
- **Script:** /usr/local/bin/fix-display-orientation-before-peppy.sh
- **Effect:** Explicit rotation fix before PeppyMeter starts

**Rotation Point 7:** .xinitrc → Moode rotation logic
- **Location:** /home/andre/.xinitrc
- **Logic:** Checks hdmi_scn_orient from Moode database
- **Effect:** Conditional rotation based on Moode setting

**Moode Database Display Settings:**
```
hdmi_scn_orient|landscape
peppy_display|1
local_display_url|http://localhost/
local_display|1
peppy_scn_blank_active|0
peppy_display_type|meter
dsi_scn_type|none
dsi_scn_rotate|0
scnsaver_whenplaying|No
scnsaver_timeout|Never
scnsaver_style|Gradient (Linear)
wake_display|0
volume_db_display|1
scnsaver_mode|Cover art
scnsaver_layout|Default
scnsaver_xmeta|Yes
```

**Rotation Point 8:** Moode Database → hdmi_scn_orient
- **Location:** /var/local/www/db/moode-sqlite3.db
- **Setting:** hdmi_scn_orient=landscape
- **Effect:** Controls .xinitrc rotation logic

**PeppyMeter Configuration:**
- **Config File:** /opt/peppymeter/1280x400/meters.txt
- **Meter Type:** linear
- **Left Meter Position:** X=50, Y=150
- **Screen Size:** Determined from folder name (1280x400)
- **Note:** PeppyMeter uses folder name for screen size, not X11 query

**PeppyMeter Window:**
- **Geometry:**   -geometry 1280x400+0+0

**Pygame Display Info:**
- **Dimensions:** pygame 2.6.1 (SDL 2.32.4, Python 3.13.5)
Hello from the pygame community. https://www.pygame.org/contribute.html
1280x400
- **Note:** Pygame queries X11 for display size


---

## 🔄 COMPLETE ROTATION CHAIN

The video signal flows through these rotation points:

1. **config.txt** → `display_rotate=X` (boot-level framebuffer rotation)
2. **cmdline.txt** → `video=...rotate=...` (kernel-level video rotation)
3. **cmdline.txt** → `fbcon=rotate:X` (console framebuffer rotation)
4. **Framebuffer** → Native geometry (after boot rotation)
5. **X11 xrandr** → Runtime rotation (applied by .xinitrc)
6. **.xinitrc** → fix-display-orientation script (explicit rotation fix)
7. **.xinitrc** → Moode rotation logic (conditional rotation)
8. **Moode Database** → `hdmi_scn_orient` (controls .xinitrc logic)
9. **Applications** → Use X11 dimensions (PeppyMeter uses folder name)

---

## ⚠️ CURRENT STATE ANALYSIS

**Problem Identified:**
- Display hardware reports: **400x1280** (portrait)
- Physical display should be: **1280x400** (landscape)
- Moode setting: **landscape**
- X11 reports: **1280x400** (correctly rotated)
- Framebuffer reports: **400x1280** (not rotated)

**Root Cause:**
The display hardware EDID reports portrait mode, but the physical display is landscape.
Rotation must be applied at multiple points to ensure consistency.

---

## ✅ RECOMMENDATIONS

1. **Ensure rotation at boot level** (config.txt or cmdline.txt)
2. **Apply rotation in .xinitrc** BEFORE applications start
3. **Verify Moode database** setting matches reality
4. **Check all rotation points** are consistent
5. **Use fix-display-orientation script** to ensure correct orientation

---

**Mapping Complete:** $(date +"%Y-%m-%d %H:%M:%S")

