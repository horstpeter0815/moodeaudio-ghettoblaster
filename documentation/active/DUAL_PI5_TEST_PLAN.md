# Dual Raspberry Pi 5 Test Plan

## Setup

- **2x Raspberry Pi 5** - identisches Setup
- **2x Moode Audio** - frisch installiert, identisch
- **2x Waveshare 7.9" DSI LCD** - identisch
- **Keine Soundkarte** - nur Pi + Display
- **27W Power Supply** - für beide

## Hardware-Konfiguration

- **DSI Port:** DSI0 (Primary DSI) ✅
- **DIP Switches:** I2C0 (auf Display)
- **GPIO:** 5V und GND von GPIO-Pins
- **DSI-Kabel:** Verbunden an DSI0

## Test-Strategie

**Synchroner Test auf beiden Geräten:**
- Gleiche Commands gleichzeitig
- Vergleich der Ergebnisse
- Hardware-Defekte ausschließen

## Schritt 1: IP-Adressen erfragen

```bash
# Beide Pi 5 booten lassen
# IP-Adressen herausfinden
# Beispiel: 192.168.178.123 und 192.168.178.124
```

## Schritt 2: Initiale Hardware-Verifikation

**Synchron auf beiden:**
- I2C-Bus 0 prüfen (I2C0)
- I2C-Bus 1 prüfen
- Framebuffer prüfen
- Kernel-Version prüfen

## Schritt 3: Config.txt Setup

**Für beide identisch:**
```ini
[pi5]
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-fkms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c0,dsi0
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
hdmi_ignore_hotplug=1
display_auto_detect=0
hdmi_force_hotplug=0
hdmi_blanking=1
fbcon=map=1
disable_fw_kms_setup=0
arm_64bit=1
arm_boost=1
disable_splash=1
disable_overscan=1
```

## Schritt 4: Synchroner Reboot

**Beide gleichzeitig rebooten**

## Schritt 5: Synchroner Status-Check

**Nach Reboot auf beiden prüfen:**
- dmesg | grep -i dsi
- dmesg | grep -i panel
- cat /sys/class/graphics/fb0/virtual_size
- cat /sys/class/drm/card*/DSI-*/status
- i2cdetect -y 0

## Schritt 6: Framebuffer-Test

**Synchron auf beiden:**
- Display-Manager starten
- Test-Pattern anzeigen
- Ergebnisse vergleichen

## Erwartetes Ergebnis

**Wenn beide identisch:**
- ✅ Gleiche I2C-Ergebnisse
- ✅ Gleiche Framebuffer-Größe
- ✅ Gleiche dmesg-Ausgaben
- ✅ Beide Displays zeigen Bild

**Wenn unterschiedlich:**
- ❌ Hardware-Defekt möglich
- ❌ Weitere Diagnose nötig

---

**Bereit für synchronen Dual-Pi5-Test!**

