# Pi 5 #1 Config aktualisiert

## Durchgeführte Änderungen

1. ✅ Config.txt Backup erstellt
2. ✅ Config.txt mit DSI0/I2C0 Setup aktualisiert:
   - `dtoverlay=vc4-fkms-v3d` (FKMS statt True KMS)
   - `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0`
   - `disable_fw_kms_setup=0` (aktiviert)
   - `fbcon=map=1` (Framebuffer aktiviert)

## Status

- ✅ Config.txt angepasst
- ⏳ **Warte auf zweiten Pi 5**
- ⏳ Dann synchroner Reboot beider Pi 5

## Nächste Schritte

1. Zweiten Pi 5 booten lassen
2. IP-Adresse des zweiten Pi 5 finden
3. Config.txt auf zweitem Pi 5 identisch anpassen
4. Beide gleichzeitig rebooten
5. Synchroner Test

---

**Status:** Pi 5 #1 bereit. Warte auf Pi 5 #2...

