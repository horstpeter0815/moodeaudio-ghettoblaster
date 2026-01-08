# Audio/Video Pipeline - Detaillierter Schritt-für-Schritt Plan

## Status-Legende:
- 🔴 **ROT** = Nicht gestartet / Fehlt
- 🟠 **ORANGE** = In Arbeit / Teilweise fertig
- 🟢 **GRÜN** = Fertig / Funktioniert

---

## PHASE 1: Hardware-Vorbereitung

### Schritt 1.1: Hardware-Identifikation
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Alle Audio/Video Hardware-Komponenten identifizieren
- **Details:**
  - Audio-Interface prüfen (HiFiBerry, USB-DAC, etc.)
  - Video-Interface prüfen (HDMI, DSI)
  - Alle Geräte auflisten: `lsusb`, `aplay -l`, `xrandr`
  - Device-Tree Overlays prüfen: `ls /boot/firmware/overlays/`
- **Befehle:**
  ```bash
  lsusb
  aplay -l
  xrandr
  ls /boot/firmware/overlays/ | grep -i audio
  ls /boot/firmware/overlays/ | grep -i video
  ```
- **Erwartetes Ergebnis:** Liste aller Audio/Video Geräte
- **Nächster Schritt:** 1.2

### Schritt 1.2: Hardware-Konfiguration
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Hardware in config.txt konfigurieren
- **Details:**
  - Audio-Overlay hinzufügen (z.B. `dtoverlay=hifiberry-dac`)
  - Video-Overlay prüfen (z.B. `dtoverlay=vc4-kms-v3d`)
  - I2C/SPI aktivieren falls nötig
  - GPIO-Pins konfigurieren falls nötig
- **Dateien:**
  - `/boot/firmware/config.txt`
- **Befehle:**
  ```bash
  sudo nano /boot/firmware/config.txt
  # Füge hinzu:
  # dtoverlay=hifiberry-dac
  # dtoverlay=vc4-kms-v3d
  ```
- **Erwartetes Ergebnis:** Hardware wird beim Boot erkannt
- **Nächster Schritt:** 1.3

### Schritt 1.3: Hardware-Verifikation nach Reboot
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Prüfen ob Hardware nach Reboot funktioniert
- **Details:**
  - Reboot durchführen
  - Audio-Geräte prüfen: `aplay -l`, `arecord -l`
  - Video-Geräte prüfen: `xrandr`, `dmesg | grep -i display`
  - Device-Tree prüfen: `ls /proc/device-tree/`
- **Befehle:**
  ```bash
  sudo reboot
  # Nach Reboot:
  aplay -l
  xrandr
  dmesg | grep -i audio
  dmesg | grep -i display
  ```
- **Erwartetes Ergebnis:** Alle Hardware wird erkannt
- **Nächster Schritt:** 2.1

---

## PHASE 2: Audio-Pipeline Setup

### Schritt 2.1: ALSA-Konfiguration
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** ALSA für Audio-Pipeline konfigurieren
- **Details:**
  - Standard-Audio-Gerät setzen
  - ALSA-Mixer konfigurieren
  - Sample-Rate und Format setzen
  - Buffer-Size optimieren
- **Dateien:**
  - `/etc/asound.conf` (systemweit)
  - `~/.asoundrc` (user-spezifisch)
- **Befehle:**
  ```bash
  # Prüfe verfügbare Geräte
  aplay -l
  arecord -l
  
  # Erstelle /etc/asound.conf
  sudo nano /etc/asound.conf
  # Konfiguration für Default-Gerät
  ```
- **Erwartetes Ergebnis:** ALSA verwendet korrektes Audio-Gerät
- **Nächster Schritt:** 2.2

### Schritt 2.2: PulseAudio Setup (optional)
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** PulseAudio für Audio-Mixing konfigurieren
- **Details:**
  - PulseAudio installieren (falls nicht vorhanden)
  - Default-Sink setzen
  - Sample-Rate konfigurieren
  - Module laden
- **Befehle:**
  ```bash
  # Prüfe ob PulseAudio läuft
  pulseaudio --check
  
  # Setze Default-Sink
  pactl set-default-sink <sink-name>
  
  # Prüfe Sinks
  pactl list sinks
  ```
- **Erwartetes Ergebnis:** PulseAudio funktioniert
- **Nächster Schritt:** 2.3

### Schritt 2.3: MPD Audio-Konfiguration
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** MPD für Audio-Wiedergabe konfigurieren
- **Details:**
  - MPD config prüfen: `/etc/mpd.conf`
  - Audio-Output konfigurieren
  - Sample-Rate setzen
  - Buffer-Size optimieren
  - MPD Service prüfen
- **Dateien:**
  - `/etc/mpd.conf`
- **Befehle:**
  ```bash
  # Prüfe MPD Config
  sudo nano /etc/mpd.conf
  
  # Prüfe MPD Status
  sudo systemctl status mpd
  
  # Teste MPD
  mpc play
  mpc status
  ```
- **Erwartetes Ergebnis:** MPD spielt Audio ab
- **Nächster Schritt:** 2.4

### Schritt 2.4: Audio-Test
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Audio-Pipeline testen
- **Details:**
  - Test-Ton abspielen
  - Verschiedene Formate testen (PCM, FLAC, MP3)
  - Lautstärke testen
  - Latency messen
- **Befehle:**
  ```bash
  # Test-Ton
  speaker-test -t sine -f 1000 -l 1 -c 2
  
  # Test mit aplay
  aplay /usr/share/sounds/alsa/Front_Left.wav
  
  # Test mit MPD
  mpc play
  mpc volume 50
  ```
- **Erwartetes Ergebnis:** Audio funktioniert
- **Nächster Schritt:** 3.1

---

## PHASE 3: Video-Pipeline Setup

### Schritt 3.1: Display-Konfiguration
- 🟠 **Status:** In Arbeit
- **Beschreibung:** Display für Video-Pipeline konfigurieren
- **Details:**
  - Resolution setzen (1280x400)
  - Rotation konfigurieren
  - Framebuffer konfigurieren
  - Refresh-Rate optimieren
- **Dateien:**
  - `/boot/firmware/config.txt`
  - `/home/andre/.xinitrc`
- **Befehle:**
  ```bash
  # Prüfe Display
  xrandr
  
  # Setze Resolution und Rotation
  xrandr --output HDMI-A-2 --mode 1280x400 --rotate right
  xrandr --fb 1280x400
  ```
- **Erwartetes Ergebnis:** Display zeigt korrekte Resolution
- **Nächster Schritt:** 3.2

### Schritt 3.2: X11/Display-Server Konfiguration
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** X11 für Video-Pipeline konfigurieren
- **Details:**
  - X11 Config prüfen
  - Display-Manager konfigurieren
  - Window-Manager prüfen
  - Compositor konfigurieren (falls nötig)
- **Dateien:**
  - `/etc/X11/xorg.conf`
  - `/etc/X11/xorg.conf.d/`
- **Befehle:**
  ```bash
  # Prüfe X11
  echo $DISPLAY
  xdpyinfo
  
  # Prüfe Window-Manager
  wmctrl -m
  ```
- **Erwartetes Ergebnis:** X11 funktioniert korrekt
- **Nächster Schritt:** 3.3

### Schritt 3.3: Video-Player Setup
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Video-Player für Pipeline konfigurieren
- **Details:**
  - Video-Player installieren (z.B. mpv, vlc)
  - Codecs prüfen
  - Hardware-Acceleration konfigurieren
  - Output-Format setzen
- **Befehle:**
  ```bash
  # Installiere mpv
  sudo apt-get install mpv
  
  # Teste Video-Player
  mpv --vo=drm --hwdec=auto test.mp4
  ```
- **Erwartetes Ergebnis:** Video-Player funktioniert
- **Nächster Schritt:** 3.4

### Schritt 3.4: Video-Test
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Video-Pipeline testen
- **Details:**
  - Test-Video abspielen
  - Resolution prüfen
  - Framerate prüfen
  - Latency messen
- **Befehle:**
  ```bash
  # Test-Video
  mpv test.mp4
  
  # Prüfe Video-Info
  ffprobe test.mp4
  ```
- **Erwartetes Ergebnis:** Video funktioniert
- **Nächster Schritt:** 4.1

---

## PHASE 4: Audio/Video Synchronisation

### Schritt 4.1: Timing-Konfiguration
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Audio/Video Timing synchronisieren
- **Details:**
  - Audio-Latency messen
  - Video-Latency messen
  - Offset berechnen
  - Synchronisation konfigurieren
- **Befehle:**
  ```bash
  # Audio-Latency
  arecord -D hw:0,0 -f cd -t wav -d 1 test.wav
  
  # Video-Latency
  # Mit Video-Player testen
  ```
- **Erwartetes Ergebnis:** Timing ist synchronisiert
- **Nächster Schritt:** 4.2

### Schritt 4.2: Pipeline-Integration
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Audio und Video in Pipeline integrieren
- **Details:**
  - GStreamer Pipeline erstellen (falls verwendet)
  - FFmpeg Pipeline erstellen (falls verwendet)
  - Synchronisation testen
  - Buffer-Management konfigurieren
- **Befehle:**
  ```bash
  # GStreamer Test
  gst-launch-1.0 videotestsrc ! autovideosink
  
  # FFmpeg Test
  ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4
  ```
- **Erwartetes Ergebnis:** Audio/Video sind synchron
- **Nächster Schritt:** 4.3

### Schritt 4.3: Synchronisation-Test
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Audio/Video Synchronisation testen
- **Details:**
  - Test-Video mit Audio abspielen
  - Synchronisation prüfen
  - Offset anpassen falls nötig
  - Performance messen
- **Befehle:**
  ```bash
  # Test mit mpv
  mpv --audio-delay=0 test.mp4
  
  # Prüfe Synchronisation
  # Manuell prüfen ob Audio/Video synchron sind
  ```
- **Erwartetes Ergebnis:** Audio/Video sind perfekt synchron
- **Nächster Schritt:** 5.1

---

## PHASE 5: Performance-Optimierung

### Schritt 5.1: CPU-Optimierung
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** CPU für Audio/Video optimieren
- **Details:**
  - CPU-Governor setzen (performance)
  - CPU-Frequenz prüfen
  - CPU-Auslastung messen
  - Prozesse optimieren
- **Befehle:**
  ```bash
  # CPU-Governor
  echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  
  # CPU-Frequenz
  cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
  ```
- **Erwartetes Ergebnis:** CPU läuft optimal
- **Nächster Schritt:** 5.2

### Schritt 5.2: Memory-Optimierung
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Memory für Pipeline optimieren
- **Details:**
  - Memory-Usage prüfen
  - Swap konfigurieren
  - Buffer-Sizes optimieren
  - Memory-Limits setzen
- **Befehle:**
  ```bash
  # Memory-Usage
  free -h
  
  # Swap
  swapon --show
  ```
- **Erwartetes Ergebnis:** Memory ist optimiert
- **Nächster Schritt:** 5.3

### Schritt 5.3: I/O-Optimierung
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** I/O für Pipeline optimieren
- **Details:**
  - Disk-I/O prüfen
  - Network-I/O prüfen (falls Streaming)
  - Buffer-Sizes optimieren
  - I/O-Scheduler setzen
- **Befehle:**
  ```bash
  # I/O-Statistiken
  iostat -x 1
  
  # I/O-Scheduler
  cat /sys/block/mmcblk0/queue/scheduler
  ```
- **Erwartetes Ergebnis:** I/O ist optimiert
- **Nächster Schritt:** 6.1

---

## PHASE 6: Monitoring & Logging

### Schritt 6.1: Monitoring-Setup
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Monitoring für Pipeline einrichten
- **Details:**
  - CPU-Monitoring
  - Memory-Monitoring
  - Audio-Monitoring (Levels, Latency)
  - Video-Monitoring (FPS, Resolution)
- **Befehle:**
  ```bash
  # System-Monitoring
  htop
  
  # Audio-Monitoring
  alsamixer
  ```
- **Erwartetes Ergebnis:** Monitoring funktioniert
- **Nächster Schritt:** 6.2

### Schritt 6.2: Logging-Setup
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Logging für Pipeline einrichten
- **Details:**
  - Audio-Logs
  - Video-Logs
  - System-Logs
  - Error-Logs
- **Dateien:**
  - `/var/log/syslog`
  - `/var/log/mpd.log`
- **Befehle:**
  ```bash
  # Logs prüfen
  journalctl -u mpd
  dmesg | grep -i audio
  ```
- **Erwartetes Ergebnis:** Logging funktioniert
- **Nächster Schritt:** 7.1

---

## PHASE 7: Finale Tests

### Schritt 7.1: Kompletter Pipeline-Test
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Komplette Audio/Video Pipeline testen
- **Details:**
  - Audio + Video gleichzeitig
  - Verschiedene Formate testen
  - Performance testen
  - Stabilität testen (lange Laufzeit)
- **Befehle:**
  ```bash
  # Kompletter Test
  mpv --audio-delay=0 test_video.mp4
  ```
- **Erwartetes Ergebnis:** Pipeline funktioniert perfekt
- **Nächster Schritt:** 7.2

### Schritt 7.2: Stress-Test
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Pipeline unter Last testen
- **Details:**
  - Hohe CPU-Last
  - Hohe Memory-Last
  - Lange Laufzeit
  - Verschiedene Workloads
- **Befehle:**
  ```bash
  # Stress-Test
  stress --cpu 4 --timeout 60s &
  mpv test_video.mp4
  ```
- **Erwartetes Ergebnis:** Pipeline bleibt stabil
- **Nächster Schritt:** 7.3

### Schritt 7.3: Dokumentation
- 🔴 **Status:** Nicht gestartet
- **Beschreibung:** Pipeline dokumentieren
- **Details:**
  - Konfiguration dokumentieren
  - Probleme dokumentieren
  - Lösungen dokumentieren
  - Performance-Metriken dokumentieren
- **Erwartetes Ergebnis:** Vollständige Dokumentation
- **Nächster Schritt:** FERTIG

---

## Status-Übersicht:

### Phase 1: Hardware-Vorbereitung
- 🔴 Schritt 1.1: Hardware-Identifikation
- 🔴 Schritt 1.2: Hardware-Konfiguration
- 🔴 Schritt 1.3: Hardware-Verifikation

### Phase 2: Audio-Pipeline
- 🔴 Schritt 2.1: ALSA-Konfiguration
- 🔴 Schritt 2.2: PulseAudio Setup
- 🔴 Schritt 2.3: MPD Audio-Konfiguration
- 🔴 Schritt 2.4: Audio-Test

### Phase 3: Video-Pipeline
- 🟠 Schritt 3.1: Display-Konfiguration (in Arbeit)
- 🔴 Schritt 3.2: X11/Display-Server
- 🔴 Schritt 3.3: Video-Player Setup
- 🔴 Schritt 3.4: Video-Test

### Phase 4: Synchronisation
- 🔴 Schritt 4.1: Timing-Konfiguration
- 🔴 Schritt 4.2: Pipeline-Integration
- 🔴 Schritt 4.3: Synchronisation-Test

### Phase 5: Performance
- 🔴 Schritt 5.1: CPU-Optimierung
- 🔴 Schritt 5.2: Memory-Optimierung
- 🔴 Schritt 5.3: I/O-Optimierung

### Phase 6: Monitoring
- 🔴 Schritt 6.1: Monitoring-Setup
- 🔴 Schritt 6.2: Logging-Setup

### Phase 7: Tests
- 🔴 Schritt 7.1: Kompletter Pipeline-Test
- 🔴 Schritt 7.2: Stress-Test
- 🔴 Schritt 7.3: Dokumentation

---

## Nächste Schritte:

1. Beginne mit Phase 1, Schritt 1.1
2. Arbeite Schritt für Schritt durch
3. Aktualisiere Status nach jedem Schritt
4. Dokumentiere Ergebnisse

---

**Erstellt:** $(date)
**Status:** Plan erstellt, bereit zum Start

