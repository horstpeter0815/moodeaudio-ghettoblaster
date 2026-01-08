# Edge Conditions - Test-Variablen

## Edge Condition 1: Operating System & Kernel

### Operating System:
- **Aktuell:** Moode Audio
- **Alternativen:** 
  - RaspiOS Full
  - RaspiOS Lite
  - HiFiBerryOS

### Linux Kernel:
- **Aktuell:** Linux 6.x
- **Version prüfen:** `uname -r`
- **Wichtig:** Kernel-Version kann Hardware-Support beeinflussen

---

## Edge Condition 2: Display Interface

### Display-Typ:
- **Aktuell:** HDMI
- **Alternative:** DSI

### HDMI Konfiguration:
- Resolution: 1280x400
- Rotation: Landscape (right)
- Interface: HDMI-A-2

### DSI Konfiguration (falls verwendet):
- Resolution: 1280x400
- Interface: DSI-1

---

## Edge Condition 3: Hardware

### Audio-Hardware:
- **Mögliche Optionen:**
  - HiFiBerry AMP100
  - HiFiBerry DAC+
  - BeoCreate
  - USB-DAC
  - Onboard Audio

### Video-Hardware:
- **Aktuell:** Waveshare 7.9" HDMI LCD
- **Alternative:** Waveshare 7.9" DSI LCD

### Weitere Hardware:
- Touchscreen: Waveshare USB HID (0712:000a)
- Pi-Model: Raspberry Pi 5

---

## Edge Condition 4: Raspberry Pi Model

### Pi-Model:
- **Aktuell:** Raspberry Pi 5
- **Alternativen:**
  - Raspberry Pi 4
  - Raspberry Pi 3
  - Raspberry Pi Zero 2 W

### Wichtig:
- Pi 5 verwendet andere Boot-Pfade (`/boot/firmware/` statt `/boot/`)
- Pi 5 hat andere Display-Treiber (True KMS)
- Pi 5 hat bessere Performance

---

## Edge Conditions im Cockpit:

Die Edge Conditions werden oben links im Cockpit angezeigt und zeigen:
1. **OS & Kernel:** Welches Betriebssystem und Kernel-Version
2. **Display:** HDMI oder DSI
3. **Hardware:** Welche Audio/Video Hardware verwendet wird
4. **Pi-Model:** Welcher Raspberry Pi verwendet wird

---

## Status-Update:

Edge Conditions werden dynamisch aktualisiert basierend auf:
- System-Erkennung
- Konfigurations-Dateien
- Hardware-Erkennung

---

**Erstellt:** $(date)

