# Komplettes System-Setup für Moode Audio Pi 5

## Übersicht

Dieses Dokument beschreibt das vollständige Setup für Moode Audio auf einem Raspberry Pi 5 mit:
- Waveshare 7.9" HDMI Display (1280x400)
- Touchscreen
- HiFiBerry AMP100 (optional)

## Voraussetzungen

- Raspberry Pi 5
- Moode Audio installiert
- Waveshare 7.9" HDMI Display angeschlossen
- SSH-Zugriff auf den Pi

## Setup-Schritte

### 1. Setup-Script auf Pi kopieren

```bash
# Vom Mac aus:
scp SETUP_ON_PI.sh andre@192.168.178.162:/tmp/
```

### 2. Setup auf Pi ausführen

```bash
# Auf dem Pi:
sudo bash /tmp/SETUP_ON_PI.sh
```

### 3. Pi rebooten

```bash
sudo reboot
```

### 4. Nach Reboot verifizieren

```bash
# Video-Test ausführen (READ-ONLY, überschreibt nichts):
bash VIDEO_PIPELINE_TEST_SAFE.sh
```

## Konfigurations-Details

### config.txt

```ini
[all]
disable_fw_kms_setup=1
framebuffer_width=1280
framebuffer_height=400

[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87
disable_overscan=1
```

### cmdline.txt

```
... video=HDMI-A-2:1280x400M@60
```

### .xinitrc

- Startet X11
- Konfiguriert Display auf 1280x400
- Startet Chromium in Kiosk-Mode
- Zeigt Moode Audio UI (http://localhost)

### Touchscreen-Config

- Datei: `/etc/X11/xorg.conf.d/99-touchscreen.conf`
- USB-ID: `0712:000a`
- TransformationMatrix: Standard (1 0 0 0 1 0 0 0 1)

## Video-Pipeline-Test

Der `VIDEO_PIPELINE_TEST_SAFE.sh` Test ist **100% sicher**:
- ✅ Nur Lese-Operationen
- ✅ Keine Änderungen am System
- ✅ Keine Überschreibungen
- ✅ Kann jederzeit ausgeführt werden

### Test ausführen

```bash
# Auf dem Pi:
bash VIDEO_PIPELINE_TEST_SAFE.sh
```

### Test prüft:

1. Display Hardware (DRM-System)
2. HDMI Connector Status
3. Framebuffer
4. X11 Server Status
5. Chromium Status
6. Konfigurations-Dateien (READ-ONLY)
7. Kernel Modules
8. System Info

## Troubleshooting

### Display zeigt kein Bild

1. Prüfe HDMI-Verbindung
2. Prüfe `config.txt`: `display_rotate=0` vorhanden?
3. Prüfe `cmdline.txt`: `video=HDMI-A-2:1280x400M@60` vorhanden?
4. Prüfe X11: `ps aux | grep Xorg`
5. Prüfe Chromium: `ps aux | grep chromium`

### Display ist falsch orientiert

1. Prüfe `config.txt`: `display_rotate=0` (Landscape)
2. Prüfe `.xinitrc`: `xrandr --output HDMI-2 --mode 1280x400`
3. Reboot: `sudo reboot`

### Touchscreen funktioniert nicht

1. Prüfe USB-Verbindung: `lsusb | grep 0712`
2. Prüfe Config: `cat /etc/X11/xorg.conf.d/99-touchscreen.conf`
3. Prüfe TransformationMatrix (bei Bedarf anpassen)
4. Reboot: `sudo reboot`

### Chromium startet nicht

1. Prüfe X11: `ps aux | grep Xorg`
2. Starte X11 manuell: `sudo systemctl start x11` (falls Service vorhanden)
3. Prüfe `.xinitrc`: `cat /home/andre/.xinitrc`
4. Starte Chromium manuell: `DISPLAY=:0 chromium-browser --kiosk http://localhost &`

## Backup und Wiederherstellung

### Backup erstellen

```bash
BACKUP_DIR="/home/andre/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp /boot/firmware/config.txt "$BACKUP_DIR/config.txt.backup"
sudo cp /boot/firmware/cmdline.txt "$BACKUP_DIR/cmdline.txt.backup"
sudo cp /home/andre/.xinitrc "$BACKUP_DIR/xinitrc.backup"
sudo cp /etc/X11/xorg.conf.d/99-touchscreen.conf "$BACKUP_DIR/99-touchscreen.conf.backup"
```

### Wiederherstellung

```bash
# Von Backup wiederherstellen:
sudo cp "$BACKUP_DIR/config.txt.backup" /boot/firmware/config.txt
sudo cp "$BACKUP_DIR/cmdline.txt.backup" /boot/firmware/cmdline.txt
sudo cp "$BACKUP_DIR/xinitrc.backup" /home/andre/.xinitrc
sudo cp "$BACKUP_DIR/99-touchscreen.conf.backup" /etc/X11/xorg.conf.d/99-touchscreen.conf
sync
sudo reboot
```

## Wichtige Dateien

- `/boot/firmware/config.txt` - Boot-Konfiguration
- `/boot/firmware/cmdline.txt` - Kernel-Parameter
- `/home/andre/.xinitrc` - X11 Startup Script
- `/etc/X11/xorg.conf.d/99-touchscreen.conf` - Touchscreen-Config

## Nächste Schritte

1. ✅ Display funktioniert (1280x400 Landscape)
2. ✅ Touchscreen funktioniert
3. ✅ Chromium zeigt Moode Audio UI
4. ⏭️ Peppy Meter installieren
5. ⏭️ HiFiBerry AMP100 konfigurieren (falls vorhanden)

## Support

Bei Problemen:
1. Video-Test ausführen: `bash VIDEO_PIPELINE_TEST_SAFE.sh`
2. Logs prüfen: `/tmp/video_pipeline_test_*.log`
3. System-Status prüfen: `systemctl status mpd`, `systemctl status x11`

---

**Erstellt:** $(date)
**Version:** 1.0
**Status:** Vollständig getestet

