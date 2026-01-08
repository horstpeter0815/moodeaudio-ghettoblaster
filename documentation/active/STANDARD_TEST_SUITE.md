# Standard-Test Suite - Audio/Video Pipeline

## ⚠️ WICHTIG:
**Diese Tests werden NUR ausgeführt, wenn alle Phasen vollständig ausgearbeitet sind!**

---

## Test 1: Hardware-Verifikation

### Status: 🔴 GESPERRT - Warte auf Phase 1

### Beschreibung:
Prüft ob alle Audio/Video Hardware korrekt erkannt wird.

### Voraussetzungen:
- ✅ Phase 1 vollständig abgeschlossen
- ✅ Alle Hardware-Komponenten identifiziert
- ✅ Hardware-Konfiguration abgeschlossen
- ✅ Hardware-Verifikation nach Reboot erfolgreich

### Test-Schritte:

#### 1.1 USB-Geräte prüfen
```bash
lsusb
```
**Erwartet:** Alle USB-Audio/Video Geräte werden angezeigt

#### 1.2 Audio-Geräte prüfen
```bash
aplay -l
arecord -l
```
**Erwartet:** Audio-Geräte werden erkannt und aufgelistet

#### 1.3 Video-Displays prüfen
```bash
xrandr
```
**Erwartet:** Display wird erkannt und zeigt korrekte Resolution

#### 1.4 Device-Tree prüfen
```bash
ls /proc/device-tree/
dmesg | grep -i audio
dmesg | grep -i display
```
**Erwartet:** Device-Tree Overlays werden geladen

### Erfolgskriterien:
- ✅ Alle USB-Geräte erkannt
- ✅ Audio-Geräte funktionieren
- ✅ Video-Display funktioniert
- ✅ Keine Fehler in dmesg

### Status nach Test:
- 🟢 **GRÜN** = Alle Hardware erkannt
- 🟠 **ORANGE** = Teilweise erkannt (Details dokumentieren)
- 🔴 **ROT** = Hardware nicht erkannt (Fehler beheben)

---

## Test 2: Audio-Pipeline

### Status: 🔴 GESPERRT - Warte auf Phase 2

### Beschreibung:
Testet komplette Audio-Pipeline von Input bis Output.

### Voraussetzungen:
- ✅ Phase 2 vollständig abgeschlossen
- ✅ ALSA konfiguriert
- ✅ MPD konfiguriert
- ✅ Audio-Test erfolgreich

### Test-Schritte:

#### 2.1 ALSA-Test
```bash
# Test-Ton
speaker-test -t sine -f 1000 -l 1 -c 2

# Test mit aplay
aplay /usr/share/sounds/alsa/Front_Left.wav
```
**Erwartet:** Audio wird ausgegeben

#### 2.2 MPD-Test
```bash
# MPD Status
mpc status

# Test-Wiedergabe
mpc play
mpc volume 50
```
**Erwartet:** MPD spielt Audio ab

#### 2.3 Audio-Formate testen
```bash
# Verschiedene Formate
mpc add file.flac
mpc add file.mp3
mpc add file.wav
mpc play
```
**Erwartet:** Alle Formate werden abgespielt

#### 2.4 Latency messen
```bash
# Audio-Latency
arecord -D hw:0,0 -f cd -t wav -d 1 test.wav
```
**Erwartet:** Latency < 50ms

### Erfolgskriterien:
- ✅ ALSA funktioniert
- ✅ MPD funktioniert
- ✅ Alle Formate werden unterstützt
- ✅ Latency akzeptabel

### Status nach Test:
- 🟢 **GRÜN** = Audio-Pipeline funktioniert perfekt
- 🟠 **ORANGE** = Funktioniert mit Einschränkungen
- 🔴 **ROT** = Audio-Pipeline funktioniert nicht

---

## Test 3: Video-Pipeline

### Status: 🔴 GESPERRT - Warte auf Phase 3

### Beschreibung:
Testet komplette Video-Pipeline von Display bis Output.

### Voraussetzungen:
- ✅ Phase 3 vollständig abgeschlossen
- ✅ Display konfiguriert
- ✅ X11 funktioniert
- ✅ Video-Player installiert

### Test-Schritte:

#### 3.1 Display-Test
```bash
# Display-Status
xrandr --output HDMI-A-2 --query

# Resolution prüfen
xdpyinfo | grep dimensions
```
**Erwartet:** Display zeigt korrekte Resolution (1280x400)

#### 3.2 Video-Player-Test
```bash
# Test-Video abspielen
mpv test.mp4

# Hardware-Acceleration testen
mpv --vo=drm --hwdec=auto test.mp4
```
**Erwartet:** Video wird korrekt abgespielt

#### 3.3 Video-Formate testen
```bash
# Verschiedene Formate
mpv test.mp4
mpv test.mkv
mpv test.avi
```
**Erwartet:** Alle Formate werden unterstützt

#### 3.4 Framerate prüfen
```bash
# Video-Info
ffprobe test.mp4 | grep fps
```
**Erwartet:** Framerate wird korrekt erkannt

### Erfolgskriterien:
- ✅ Display funktioniert
- ✅ Video-Player funktioniert
- ✅ Alle Formate werden unterstützt
- ✅ Framerate korrekt

### Status nach Test:
- 🟢 **GRÜN** = Video-Pipeline funktioniert perfekt
- 🟠 **ORANGE** = Funktioniert mit Einschränkungen
- 🔴 **ROT** = Video-Pipeline funktioniert nicht

---

## Test 4: Audio/Video Synchronisation

### Status: 🔴 GESPERRT - Warte auf Phase 4

### Beschreibung:
Testet Synchronisation zwischen Audio und Video.

### Voraussetzungen:
- ✅ Phase 4 vollständig abgeschlossen
- ✅ Timing konfiguriert
- ✅ Pipeline integriert
- ✅ Synchronisation konfiguriert

### Test-Schritte:

#### 4.1 Synchronisation-Test
```bash
# Test-Video mit Audio
mpv --audio-delay=0 test_video.mp4

# Manuell prüfen ob Audio/Video synchron sind
```
**Erwartet:** Audio und Video sind synchron

#### 4.2 Offset-Test
```bash
# Verschiedene Offsets testen
mpv --audio-delay=-100 test_video.mp4
mpv --audio-delay=0 test_video.mp4
mpv --audio-delay=100 test_video.mp4
```
**Erwartet:** Optimaler Offset wird gefunden

#### 4.3 Langzeit-Test
```bash
# Langes Video abspielen
mpv --audio-delay=0 long_video.mp4
# 10 Minuten laufen lassen
```
**Erwartet:** Synchronisation bleibt über Zeit stabil

### Erfolgskriterien:
- ✅ Audio/Video sind synchron
- ✅ Offset < 50ms
- ✅ Synchronisation bleibt stabil

### Status nach Test:
- 🟢 **GRÜN** = Synchronisation perfekt
- 🟠 **ORANGE** = Synchronisation akzeptabel
- 🔴 **ROT** = Synchronisation funktioniert nicht

---

## Test 5: Performance

### Status: 🔴 GESPERRT - Warte auf Phase 5

### Beschreibung:
Testet Performance unter Last.

### Voraussetzungen:
- ✅ Phase 5 vollständig abgeschlossen
- ✅ CPU optimiert
- ✅ Memory optimiert
- ✅ I/O optimiert

### Test-Schritte:

#### 5.1 CPU-Performance
```bash
# CPU-Auslastung während Playback
htop
# Während mpv test_video.mp4 läuft
```
**Erwartet:** CPU-Auslastung < 80%

#### 5.2 Memory-Performance
```bash
# Memory-Usage
free -h
# Während Playback
```
**Erwartet:** Memory-Usage < 80%

#### 5.3 I/O-Performance
```bash
# I/O-Statistiken
iostat -x 1
# Während Playback
```
**Erwartet:** I/O-Latency akzeptabel

#### 5.4 Stress-Test
```bash
# Stress-Test
stress --cpu 4 --timeout 60s &
mpv test_video.mp4
```
**Erwartet:** Pipeline bleibt stabil unter Last

### Erfolgskriterien:
- ✅ CPU-Auslastung akzeptabel
- ✅ Memory-Usage akzeptabel
- ✅ I/O-Performance akzeptabel
- ✅ Pipeline bleibt stabil unter Last

### Status nach Test:
- 🟢 **GRÜN** = Performance optimal
- 🟠 **ORANGE** = Performance akzeptabel
- 🔴 **ROT** = Performance unzureichend

---

## Test 6: Kompletter Pipeline-Test

### Status: 🔴 GESPERRT - Warte auf alle Phasen

### Beschreibung:
Testet komplette Audio/Video Pipeline end-to-end.

### Voraussetzungen:
- ✅ Alle Phasen vollständig abgeschlossen
- ✅ Alle vorherigen Tests erfolgreich

### Test-Schritte:

#### 6.1 Kompletter Test
```bash
# Audio + Video gleichzeitig
mpv --audio-delay=0 test_video.mp4

# Verschiedene Formate
mpv test1.mp4
mpv test2.mkv
mpv test3.avi
```
**Erwartet:** Alle Tests erfolgreich

#### 6.2 Langzeit-Test
```bash
# 1 Stunde laufen lassen
mpv --loop=inf long_video.mp4
```
**Erwartet:** Pipeline bleibt stabil

#### 6.3 Verschiedene Workloads
```bash
# Verschiedene Video-Formate
# Verschiedene Audio-Formate
# Verschiedene Resolutions
```
**Erwartet:** Alle Workloads funktionieren

### Erfolgskriterien:
- ✅ Komplette Pipeline funktioniert
- ✅ Alle Formate werden unterstützt
- ✅ Pipeline bleibt stabil
- ✅ Performance akzeptabel

### Status nach Test:
- 🟢 **GRÜN** = Pipeline funktioniert perfekt
- 🟠 **ORANGE** = Pipeline funktioniert mit Einschränkungen
- 🔴 **ROT** = Pipeline funktioniert nicht

---

## Test-Ausführung:

### WICHTIG:
**Tests werden NUR ausgeführt, wenn:**
1. Alle Phasen vollständig ausgearbeitet sind
2. Alle Voraussetzungen erfüllt sind
3. Explizite Erlaubnis gegeben wurde

### Test-Reihenfolge:
1. Test 1: Hardware-Verifikation
2. Test 2: Audio-Pipeline
3. Test 3: Video-Pipeline
4. Test 4: Audio/Video Synchronisation
5. Test 5: Performance
6. Test 6: Kompletter Pipeline-Test

### Nach jedem Test:
- Status aktualisieren (🟢/🟠/🔴)
- Ergebnisse dokumentieren
- Probleme dokumentieren
- Nächsten Test vorbereiten

---

**Erstellt:** $(date)
**Status:** Tests definiert, aber GESPERRT bis alle Phasen fertig sind

