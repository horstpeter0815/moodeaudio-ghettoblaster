# Was ich genau mache

## Aktuelle Situation

### Pi 5 #1 (192.168.178.134) - "ghettoPi4"
- ✅ **SSH erreichbar**
- ✅ **Config wiederhergestellt:**
  - `dtoverlay=vc4-kms-v3d-pi5,noaudio` (Pi 5 spezifisch!)
  - `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0`
  - `disable_fw_kms_setup=0`
  - `fbcon=map=1`
- ⚠️ **cmdline.txt prüfen** - fehlt möglicherweise `fbcon=map=1`

### Pi 5 #2 (192.168.178.123)
- ❌ **SSH "Permission denied"** - möglicherweise:
  - Falsche IP?
  - Anderes Passwort?
  - Noch nicht gebootet?

## Was ich gerade mache:

1. ✅ **Pi 5 #1 Config wiederhergestellt** (funktionierende Config vor Peppy)
2. ⏳ **cmdline.txt prüfen** - ob `fbcon=map=1` vorhanden ist
3. ⏳ **Pi 5 #2 finden** - IP prüfen oder warten bis gebootet
4. ⏳ **Beide Pis synchron konfigurieren** - identische funktionierende Config

## Funktionierende Config (basierend auf PI4_VS_PI5_CONFIG_DIFFERENCES.md):

**config.txt:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio

[all]
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0
disable_fw_kms_setup=0
fbcon=map=1
```

**cmdline.txt:**
- Sollte `fbcon=map=1` enthalten (falls nicht, hinzufügen)

---

**Status:** Pi 5 #1 Config wiederhergestellt. Prüfe cmdline.txt und finde Pi 5 #2.

