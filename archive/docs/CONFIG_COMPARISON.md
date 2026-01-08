# Config Comparison - Aktuell vs. Waveshare Support

**Date:** 2025-11-25 20:00

---

## Aktuelle Config (auf Pi)

**WICHTIGE SETTINGS:**
- `display_auto_detect=0` ❌
- `disable_fw_kms_setup=0` ❌
- `hdmi_force_hotplug=0` ❌
- `hdmi_ignore_hotplug=1` ❌
- `dtparam=audio=off` ❌
- `dtoverlay=vc4-kms-v3d` am Ende ✓
- `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch` am Ende ✓

---

## Waveshare Support Config (von User)

**WICHTIGE SETTINGS:**
- `display_auto_detect=1` ✓
- `disable_fw_kms_setup=1` ✓
- `hdmi_force_hotplug=1` ✓
- `hdmi_ignore_hotplug` NICHT gesetzt ✓
- `dtparam=audio=on` ✓
- `dtoverlay=vc4-kms-v3d` (in [all] am Anfang UND am Ende) ✓
- `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch` am Ende ✓

---

## KRITISCHE UNTERSCHIEDE

### 1. display_auto_detect
- **Aktuell:** `0` (disabled)
- **Waveshare:** `1` (enabled) ✓

### 2. disable_fw_kms_setup
- **Aktuell:** `0` (firmware KMS enabled)
- **Waveshare:** `1` (firmware KMS disabled) ✓

### 3. hdmi_force_hotplug
- **Aktuell:** `0` (disabled)
- **Waveshare:** `1` (enabled) ✓

### 4. hdmi_ignore_hotplug
- **Aktuell:** `1` (ignore HDMI)
- **Waveshare:** NICHT gesetzt (default = 0) ✓

### 5. dtparam=audio
- **Aktuell:** `off`
- **Waveshare:** `on` ✓

### 6. vc4-kms-v3d Position
- **Aktuell:** Nur am Ende
- **Waveshare:** In [all] am Anfang UND am Ende ✓

---

## ACTION REQUIRED

**Config muss angepasst werden zu Waveshare Support Config!**
