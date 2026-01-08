# Alternative HDMI Configuration Methods

**Multiple approaches to try if standard method doesn't work**

---

## APPROACH 1: Minimal config.txt (Forum Method)

### Based on: `FORUM_EXACT_SOLUTION.md`

**Theory:** Forum user (popeye65) uses minimal config, only video parameter

**config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
hdmi_force_hotplug=1
# NO hdmi_cvt, hdmi_group, hdmi_mode
```

**cmdline.txt:**
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

**xinitrc:**
- Let Moode handle rotation
- Set `hdmi_scn_orient='portrait'` in Moode
- Moode rotates to landscape automatically

**Pros:** Simple, forum-proven  
**Cons:** Still uses rotation workaround

---

## APPROACH 2: Direct Landscape with hdmi_cvt

### Current Attempt

**config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_force_hotplug=1
display_rotate=0
```

**cmdline.txt:**
```
# NO video parameter
```

**Expected:** Direct Landscape start  
**Test:** Remove video parameter, see if hdmi_cvt works

---

## APPROACH 3: KMS Mode Setting

### Let KMS Handle Everything

**config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
dtoverlay=vc4-kms-v3d
hdmi_force_hotplug=1
# NO hdmi_cvt, hdmi_group, hdmi_mode
```

**cmdline.txt:**
```
# NO video parameter
```

**xinitrc:**
```bash
# Set mode via xrandr
DISPLAY=:0 xrandr --output HDMI-2 --mode 1280x400
```

**Pros:** KMS handles resolution  
**Cons:** Requires xrandr command

---

## APPROACH 4: Framebuffer Direct

### Configure Framebuffer Directly

**config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
dtoverlay=vc4-kms-v3d
hdmi_force_hotplug=1
```

**Systemd Service:** `framebuffer-setup.service`
```ini
[Unit]
Description=Set Framebuffer Resolution
After=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/bin/fbset -fb /dev/fb0 -g 1280 400 1280 400 32
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
```

**Pros:** Direct control  
**Cons:** More complex setup

---

## APPROACH 5: EDID Override

### Create Custom EDID

**Create:** `/boot/firmware/edid/1280x400.bin`

**config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
dtoverlay=vc4-kms-v3d
hdmi_edid_file=1
hdmi_edid_filename=edid/1280x400.bin
```

**Pros:** Most compatible  
**Cons:** Requires EDID file creation

---

## APPROACH 6: X11 Configuration

### Configure in X11

**Create:** `/etc/X11/xorg.conf.d/99-hdmi.conf`
```
Section "Monitor"
    Identifier "HDMI-2"
    Modeline "1280x400" 25.2 1280 1328 1360 1440 400 402 405 420
    Option "PreferredMode" "1280x400"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "HDMI-2"
    SubSection "Display"
        Modes "1280x400"
    EndSubSection
EndSection
```

**Pros:** X11 handles it  
**Cons:** Requires X11 config

---

## TESTING ORDER

### Test in this order:

1. **Approach 2** - Direct Landscape with hdmi_cvt (remove video param)
2. **Approach 3** - KMS mode setting (xrandr)
3. **Approach 1** - Forum method (minimal, proven)
4. **Approach 4** - Framebuffer direct
5. **Approach 5** - EDID override
6. **Approach 6** - X11 configuration

---

## COMBINATION APPROACHES

### Hybrid: config.txt + xrandr

**config.txt:**
```ini
hdmi_cvt 1280 400 60 6 0 0 0
```

**xinitrc:**
```bash
# Force mode if needed
DISPLAY=:0 xrandr --output HDMI-2 --mode 1280x400 --rate 60
```

### Hybrid: video param + no rotation

**cmdline.txt:**
```
video=HDMI-A-2:1280x400M@60
```

**config.txt:**
```ini
display_rotate=0
```

---

## DIAGNOSTIC COMMANDS

### Check what's actually happening:

```bash
# Check current mode
xrandr

# Check framebuffer
fbset -s

# Check KMS
cat /sys/class/drm/card*/modes

# Check EDID
cat /sys/class/drm/card*/edid

# Check kernel messages
dmesg | grep -i hdmi
dmesg | grep -i drm
```

---

## RECOMMENDATION

**Start with Approach 2:**
- Remove video parameter
- Keep hdmi_cvt
- Test if direct Landscape works

**If that fails, try Approach 3:**
- Let KMS handle it
- Use xrandr to set mode

**If still fails, use Approach 1:**
- Forum-proven method
- Accept rotation workaround
- But optimize it

---

**Multiple approaches ready to test!**

