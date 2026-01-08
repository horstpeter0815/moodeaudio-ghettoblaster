# Moode Audio Installation Plan - HiFiBerryOS → Moode Audio

## Ziel
HiFiBerryOS System herunterfahren und Moode Audio installieren.

## Vorbereitung

### 1. HiFiBerryOS herunterfahren
- IP-Adresse finden (FIND_HIFIBERRYOS.sh)
- System sauber herunterfahren
- SD-Karte entfernen

### 2. Moode Audio Image vorbereiten
- Neueste Moode Audio Version herunterladen
- Image auf SD-Karte schreiben
- WLAN konfigurieren (falls nötig)

### 3. Installation
- SD-Karte in Pi einstecken
- Booten
- Erste Konfiguration durchführen
- Display konfigurieren (1280x400)
- Touchscreen konfigurieren

## Moode Audio Installation Steps

### Schritt 1: Image herunterladen
```bash
# Neueste Moode Audio Version von moodeaudio.org
# z.B. moode-r900.img.zip
```

### Schritt 2: Image auf SD-Karte schreiben
```bash
# Auf Mac:
diskutil list  # Finde SD-Karte
diskutil unmountDisk /dev/diskX
sudo dd if=moode-r900.img of=/dev/rdiskX bs=1m
```

### Schritt 3: WLAN konfigurieren (optional)
```bash
# Mount boot partition
# Erstelle wpa_supplicant.conf in boot partition
```

### Schritt 4: Booten
- SD-Karte in Pi einstecken
- Booten
- Warten auf erste Konfiguration

### Schritt 5: Display konfigurieren
- Verwende Fallback-Lösung (FALLBACK_SOLUTION.md)
- config.txt anpassen
- xinitrc konfigurieren
- Touchscreen konfigurieren

## Nach Installation

### 1. Display Setup
- config.txt: [pi5] Sektion mit hdmi_mode=87, hdmi_group=2
- xinitrc: Rotation-Befehl hinzufügen
- Touchscreen: Matrix setzen

### 2. System testen
- Display funktioniert
- Touchscreen funktioniert
- Moode UI läuft
- Audio funktioniert

### 3. Peppy Meter installieren
- Peppy Meter Plugin installieren
- Konfigurieren für 1280x400
- Testen

## Wichtige Dateien

### /boot/firmware/config.txt
```ini
[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_mode=87
hdmi_group=2
```

### /home/andre/.xinitrc
```bash
xrandr --output HDMI-A-2 --mode 1280x400 --rotate right
chromium-browser --kiosk http://localhost
```

### /etc/X11/xorg.conf.d/99-touchscreen.conf
```
Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
```

## Scripts

- `FIND_HIFIBERRYOS.sh` - Findet HiFiBerryOS IP
- `HIFIBERRYOS_TO_MOODE.sh` - Fährt HiFiBerryOS herunter
- `FIX_ROTATION.sh` - Fixiert Rotation nach Installation
- `CLEANUP_SYSTEM.sh` - Räumt System auf

## Status

- [ ] HiFiBerryOS IP gefunden
- [ ] HiFiBerryOS heruntergefahren
- [ ] Moode Audio Image heruntergeladen
- [ ] Image auf SD-Karte geschrieben
- [ ] Moode Audio gebootet
- [ ] Display konfiguriert
- [ ] Touchscreen konfiguriert
- [ ] System getestet

