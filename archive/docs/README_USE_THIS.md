# READ THIS FIRST

## THE WORKING CONFIGURATION

**File:** `THE_DEFINITIVE_WORKING_CONFIG.md`

**This is the ONLY configuration that works. Use this file.**

---

## Quick Reference

### cmdline.txt
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

### config.txt [pi5] section
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
display_rotate=0
```

### config.txt [all] section
```ini
hdmi_cvt=1280 480 60 6 0 0 0
```

---

## Scripts

**To apply this config:**
- `sd_card_config/APPLY_THE_ONE_WORKING_CONFIG.sh`

**To restore from backup:**
- `sd_card_config/RESTORE_WORKING_NOW.sh`

---

## Connection Info

**Pi hostname:** ghettopi4.local  
**User:** andre  
**Password:** 0815

**To connect:**
- `sd_card_config/CONNECT_PI_FINAL.sh`

---

**IGNORE ALL OTHER "WORKING" CONFIG FILES. USE ONLY THE_DEFINITIVE_WORKING_CONFIG.md**

