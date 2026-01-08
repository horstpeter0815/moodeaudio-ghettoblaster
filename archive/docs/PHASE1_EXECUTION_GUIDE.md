# Phase 1 Ausführung - Anleitung

## Problem: Shell funktioniert nicht
Die lokale Shell hat ein technisches Problem (`spawn /bin/zsh ENOENT`). Daher müssen die Befehle manuell ausgeführt werden.

---

## Phase 1, Schritt 1.1: Hardware-Identifikation

### Option 1: Script direkt auf Pi ausführen

1. **Script auf Pi kopieren:**
   ```bash
   scp phase1_step1_hardware_scan.sh andre@192.168.178.178:/tmp/
   # Passwort: 0815
   ```

2. **Auf Pi einloggen:**
   ```bash
   ssh andre@192.168.178.178
   # Passwort: 0815
   ```

3. **Script ausführen:**
   ```bash
   chmod +x /tmp/phase1_step1_hardware_scan.sh
   bash /tmp/phase1_step1_hardware_scan.sh
   ```

4. **Ergebnisse abrufen:**
   ```bash
   cat /tmp/phase1_step1_results.txt
   ```

### Option 2: Python-Script lokal ausführen

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
python3 execute_phase1_step1.py
```

### Option 3: Manuelle Befehle

Direkt auf dem Pi (via SSH) ausführen:

```bash
# 1. USB-Geräte
lsusb

# 2. Audio-Geräte (Playback)
aplay -l

# 3. Audio-Geräte (Capture)
arecord -l

# 4. Video-Displays
export DISPLAY=:0
xrandr

# 5. Device-Tree Overlays (Audio)
ls /boot/firmware/overlays/ | grep -E "audio|hifiberry|dac|amp"

# 6. Device-Tree Overlays (Video)
ls /boot/firmware/overlays/ | grep -E "video|display|dsi|hdmi|vc4"

# 7. Geladene Overlays
dmesg | grep -i "overlay\|dtoverlay" | tail -10

# 8. Audio-Hardware
dmesg | grep -i "audio\|alsa\|hifiberry\|dac" | tail -10

# 9. Video-Hardware
dmesg | grep -i "display\|hdmi\|dsi\|vc4\|drm" | tail -10

# 10. System-Info
uname -a
cat /etc/os-release

# 11. I2C-Geräte
i2cdetect -y 1

# 12. config.txt Einträge
grep -E "dtoverlay|dtparam" /boot/firmware/config.txt
```

---

## Nächste Schritte

Nach erfolgreicher Hardware-Identifikation:
- Ergebnisse in `PHASE1_STEP1_RESULTS.md` dokumentieren
- Phase 1.2 starten: Hardware-Konfiguration

---

**Status:** 🔴 Warte auf Ausführung

