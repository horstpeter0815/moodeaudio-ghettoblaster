# Komplette Dokumentation - Ghetto Pi 5 (Moode Audio)

## System-Übersicht

- **IP:** 192.168.178.178
- **OS:** Moode Audio
- **Display:** Waveshare 7.9" HDMI (1280x400 Landscape)
- **Status:** Vollständig konfiguriert und funktionsfähig

---

## Display-Konfiguration

### config.txt - [pi5] Sektion

```ini
[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_mode=87
hdmi_group=2
```

**Datei:** `/boot/firmware/config.txt`

### cmdline.txt

```
console=serial0,115200 console=tty1 root=PARTUUID=738a4d67-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles
```

**Datei:** `/boot/firmware/cmdline.txt`

### xinitrc - Display Rotation

```bash
sleep 1
xrandr --output HDMI-A-2 --mode <MODE> --rotate right
xrandr --fb 1280x400
chromium-browser --kiosk --window-size=1280,400 http://localhost
```

**Datei:** `/home/andre/.xinitrc`

**Wichtig:** Rotation wird via xrandr gemacht (stabiler als Boot-Parameter)

### Touchscreen-Konfiguration

```ini
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
EndSection
```

**Datei:** `/etc/X11/xorg.conf.d/99-touchscreen.conf`

**Matrix für right rotation:** `0 1 0 -1 0 1 0 0 1`

---

## Peppy Meter

### Installation

- **Verzeichnis:** `/opt/peppymeter/`
- **Haupt-Script:** `/opt/peppymeter/peppymeter.py`
- **Config:** `/opt/peppymeter/config.ini`
- **Service:** `peppymeter.service`

### Konfiguration

```ini
[display]
width = 1280
height = 400
fullscreen = true

[audio]
device = default
rate = 44100
channels = 2

[visualizer]
type = spectrum
bars = 64
```

### Service-Befehle

```bash
sudo systemctl start peppymeter    # Starten
sudo systemctl stop peppymeter      # Stoppen
sudo systemctl enable peppymeter    # Auto-Start aktivieren
sudo systemctl status peppymeter    # Status prüfen
```

---

## Wichtige Erkenntnisse

### 1. Moode Audio verwendet `/boot/firmware/` statt `/boot/`
- config.txt: `/boot/firmware/config.txt`
- cmdline.txt: `/boot/firmware/cmdline.txt`

### 2. Keine custom hdmi_timings verwenden
- Verursacht Flackern
- EDID-Modus ist stabiler
- `disable_fw_kms_setup=1` setzen

### 3. Rotation via xrandr ist stabiler
- Rotation im Boot-Parameter kann Probleme verursachen
- xrandr Rotation in xinitrc ist zuverlässiger
- Touchscreen Matrix muss zur Rotation passen

### 4. Display-Konfiguration
- Modus: 1280x400 oder 400x1280 (je nach verfügbar)
- Rotation: `--rotate right` für Landscape
- Framebuffer: `--fb 1280x400` setzen

### 5. Touchscreen
- USB HID Device: `0712:000a`
- TransformationMatrix für Rotation anpassen
- Device-ID prüfen: `xinput list`

---

## Troubleshooting

### Display flackert
- **Lösung:** Keine custom hdmi_timings verwenden
- EDID-Modus verwenden
- `disable_fw_kms_setup=1` setzen

### Rotation funktioniert nicht
- **Lösung:** xinitrc Rotation-Befehl prüfen
- Touchscreen Matrix anpassen
- Reihenfolge: Modus setzen → Rotation anwenden → Framebuffer setzen

### Touchscreen Koordinaten falsch
- **Lösung:** TransformationMatrix für Rotation anpassen
- Device-ID prüfen: `xinput list`
- Manuell testen: `xinput test <device-id>`

### Peppy Meter startet nicht
- **Lösung:** Service-Status prüfen: `sudo systemctl status peppymeter`
- Display prüfen: `export DISPLAY=:0`
- ALSA prüfen: `aplay -l`

---

## Scripts

### Rotation-Fix
- `EXECUTE_ROTATION_FIX.sh` - Fixiert Rotation
- `fix_rotation_direct.py` - Python-Version

### Peppy Meter
- `INSTALL_PEPPY_METER.sh` - Installations-Script

### System-Cleanup
- `CLEANUP_SYSTEM.sh` - Räumt System auf

---

## Finale Konfiguration

### Wichtige Dateien:

1. `/boot/firmware/config.txt` - Boot-Konfiguration
2. `/boot/firmware/cmdline.txt` - Kernel-Parameter
3. `/home/andre/.xinitrc` - X11 Startup
4. `/etc/X11/xorg.conf.d/99-touchscreen.conf` - Touchscreen
5. `/opt/peppymeter/peppymeter.py` - Peppy Meter
6. `/opt/peppymeter/config.ini` - Peppy Meter Config
7. `/etc/systemd/system/peppymeter.service` - Peppy Meter Service

### Status: ✅ Vollständig konfiguriert

Alle Komponenten sind installiert und konfiguriert:
- ✅ Display (1280x400 Landscape)
- ✅ Rotation (via xrandr)
- ✅ Touchscreen (korrekte Matrix)
- ✅ Peppy Meter (installiert und konfiguriert)

---

**Letzte Aktualisierung:** $(date)

