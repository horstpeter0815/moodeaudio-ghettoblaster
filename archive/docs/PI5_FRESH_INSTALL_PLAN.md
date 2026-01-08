# Plan für frische Moode Installation - Raspberry Pi 5

## Hardware

- **Raspberry Pi 5** (BCM2712)
- **Waveshare 7.9" DSI LCD** (1280x400)
- **DIP Switches:** I2C1 (auf Panel)
- **DSI-Kabel:** Verbunden
- **4-Pin GPIO:** Pins 2,3,5,6 (5V, GND, SDA, SCL)

## Wichtige Unterschiede Pi 4 vs Pi 5

- **Pi 5:** BCM2712 Chip
- **Pi 5:** Andere Device Tree Overlays
- **Pi 5:** `[pi5]` Sektion in config.txt statt `[pi4]`
- **Pi 5:** Möglicherweise andere KMS-Treiber

## Schritt 1: Hardware-Verifikation

```bash
# Prüfe I2C-Busse
i2cdetect -y 0
i2cdetect -y 1
i2cdetect -y 10

# Erwartet: Panel bei 0x45, Touchscreen bei 0x14 (auf I2C1)
```

## Schritt 2: Config.txt Setup für Pi 5

```ini
[cm4]
otg_mode=1

[pi5]
# Pi 5 spezifische Einstellungen
hdmi_enable_4kp60=0

[all]
# Basis-KMS (FKMS für DSI-Support auf Pi 5)
dtoverlay=vc4-fkms-v3d

# Waveshare Panel Overlay
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c1,dsi1

# I2C aktivieren
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000

# HDMI deaktivieren
hdmi_ignore_hotplug=1
display_auto_detect=0
hdmi_force_hotplug=0
hdmi_blanking=1

# Framebuffer aktivieren
fbcon=map=1

# Wichtig: Firmware-KMS Setup aktivieren
disable_fw_kms_setup=0

# Allgemeine Einstellungen
arm_64bit=1
arm_boost=1
disable_splash=1
disable_overscan=1
```

## Schritt 3: Framebuffer prüfen

```bash
# Nach Reboot prüfen
cat /sys/class/graphics/fb0/virtual_size
# Sollte sein: 1280,400 (oder zumindest ein Framebuffer vorhanden)

cat /sys/class/graphics/fb0/bits_per_pixel
# Sollte sein: 16, 24 oder 32

ls -la /dev/fb*
# Sollte /dev/fb0 vorhanden sein
```

## Schritt 4: Tools installieren

```bash
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev fbset i2c-tools
pip3 install --user pygame numpy
```

## Schritt 5: Framebuffer-Display-Manager

**Datei:** `/home/andre/fb_display.py`

- Direkter mmap-Zugriff auf `/dev/fb0`
- Keine SDL/Pygame-Abhängigkeiten für Basis-Funktionalität
- Einfache Pixel-Zeichnung
- Touchscreen-Support (später)

## Schritt 6: Systemd Service

**Datei:** `/etc/systemd/system/fb_display.service`

- Startet automatisch nach Boot
- Läuft als User `andre`
- Restart bei Fehler

## Schritt 7: Touchscreen (später)

- Touchscreen-Device finden: `/dev/input/event*`
- Python evdev für Touch-Events
- Koordinaten-Mapping (1280x400)

## Pi 5 spezifische Hinweise

1. **Kernel:** Pi 5 läuft mit Kernel 6.x (meist 6.1+)
2. **Device Tree:** Pi 5 verwendet andere Overlays
3. **KMS:** `vc4-fkms-v3d` sollte funktionieren
4. **Framebuffer:** Sollte identisch zu Pi 4 funktionieren

## Erwartetes Ergebnis

1. ✅ Framebuffer `/dev/fb0` vorhanden
2. ✅ Display zeigt Test-Pattern
3. ✅ Display-Manager läuft stabil
4. ✅ Touchscreen funktioniert (später)

## Unterschiede zur vorherigen Installation

- **Pi 5 statt Pi 4** - Andere Hardware, ähnlicher Ansatz
- **Fokus auf Framebuffer** statt DRM/KMS
- **Kein Kernel-Patch** nötig
- **Einfacher Display-Manager** mit direktem mmap-Zugriff
- **Frische Installation** ohne alte Config-Probleme

---

**Status:** Bereit für frische Pi 5 Installation. Framebuffer-Ansatz sollte funktionieren.

