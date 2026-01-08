# Finale Konfiguration basierend auf Waveshare Bullseye Image

## ✅ ANGEPASSTE KONFIGURATION:

### /boot/firmware/config.txt (oder /boot/config.txt):
```
display_auto_detect=1
disable_fw_kms_setup=1
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
dtparam=i2c_arm=on
```

**WICHTIG:**
- ❌ KEIN `rotation=90` in dtoverlay
- ❌ KEIN `dtparam=i2c_vc=on`
- ✅ `display_auto_detect=1` (aktiviert)
- ✅ `disable_fw_kms_setup=1` (wichtig für DSI)

### /boot/firmware/cmdline.txt (oder /boot/cmdline.txt):
```
... rootwait video=DSI-1:1280x400@60 ...
```

**WICHTIG:**
- ✅ `video=DSI-1:1280x400@60` (landscape, keine Rotation)
- ❌ KEIN `rotate=90`
- ❌ KEIN `fbcon=rotate:1`

## 🔍 UNTERSCHIEDE: Bullseye vs. Bookworm/Trixie

**Bullseye (Waveshare Image):**
- Verwendet `display_auto_detect=1` erfolgreich
- Keine Rotation in config.txt oder cmdline.txt
- Landscape-Modus (1280x400)
- `disable_fw_kms_setup=1` ist kritisch

**Bookworm/Trixie (aktuelles System):**
- Gleiche Konfiguration sollte funktionieren
- Aber: Rotation muss separat über Display-Manager erfolgen

## 🎯 DIP-SWITCH EINSTELLUNG:
- **I2C0** (wie konfiguriert) = `/dev/i2c-10` (DSI I2C Bus)

## 📝 NÄCHSTE SCHRITTE:
1. Reboot durchführen
2. Display sollte mit 1280x400 (landscape) funktionieren
3. Rotation kann später über Display-Manager angepasst werden

