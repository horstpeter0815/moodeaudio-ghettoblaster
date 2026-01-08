# THE ONE WORKING CONFIGURATION

**This is the ONLY configuration that actually worked.**

Based on: `WORKING_CONFIGURATION_PI5.md` - which says "FUNKTIONIERT PERFEKT!"

---

## cmdline.txt

```
console=serial0,115200 console=tty1 root=PARTUUID=CHANGE_ME rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
```

**CRITICAL:** `video=HDMI-A-2:400x1280M@60,rotate=90`

---

## config.txt

**IMPORTANT:** This must be MERGED with moOde's existing config.txt, not replace it!

### Add to [pi5] section:
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
display_rotate=0
```

### Add to [all] section (if not already present):
```ini
[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 480 60 6 0 0 0
hdmi_force_hotplug=1
hdmi_drive=2
```

**NOTE:** `hdmi_cvt=1280 480` (480, not 400!) - This is what the working config had.

---

## Why This One?

1. **WORKING_CONFIGURATION_PI5.md** is the most detailed
2. It says "FUNKTIONIERT PERFEKT!" (works perfectly)
3. It has complete documentation of what worked
4. It explains WHY each setting is needed
5. It was tested and confirmed working

---

## Other "Working" Configs (IGNORE THESE):

- FINAL_WORKING_CONFIGURATION.md - Different cmdline (1280x400, not 400x1280)
- FINAL_WORKING_SOLUTION.md - Uses hdmi_timings instead of hdmi_cvt
- PI5_WORKING_CONFIG.txt - Says "funktionierte VOR Peppy" (worked BEFORE, not current)

---

## Apply This Config

Use: `APPLY_THE_ONE_WORKING_CONFIG.sh`

