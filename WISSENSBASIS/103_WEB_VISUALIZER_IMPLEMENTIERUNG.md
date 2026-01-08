# WEB-BASIERTER AUDIO VISUALIZER FÜR HIFIBERRYOS

**Datum:** 02.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4  
**Zweck:** PeppyMeter-Alternative als Web-basierter Visualizer

---

## ÜBERSICHT

Da PeppyMeter (pygame + X11) nicht direkt auf HiFiBerryOS (Buildroot, Wayland) installierbar ist, wurde ein Web-basierter Audio-Visualizer implementiert, der im cog-Browser läuft.

---

## ARCHITEKTUR

### **Komponenten:**

1. **Python Audio-Analyse-Service** (`audio-visualizer-service.py`)
   - Liest Audio von ALSA (pyalsaaudio)
   - FFT-Analyse (64 Bands)
   - WebSocket-Server (geventwebsocket)
   - HTTP-Server für HTML-Interface

2. **HTML/JavaScript Visualizer** (eingebettet in Python-Service)
   - Canvas-basierte Visualisierung
   - PeppyMeter-Style (Gold-Gradient)
   - WebSocket-Client für Echtzeit-Daten

3. **Systemd Services:**
   - `audio-visualizer.service` - Audio-Analyse + WebSocket
   - `cog-visualizer.service` - Browser für Visualizer-Modus

4. **Umschalt-Skripte:**
   - `visualizer-on.sh` - Wechselt zu Visualizer-Modus
   - `visualizer-off.sh` - Wechselt zurück zu normalem Interface

---

## DATEIEN

### **1. /opt/hifiberry/bin/audio-visualizer-service.py**

**Funktionen:**
- ALSA Audio-Capture (pyalsaaudio)
- FFT-Analyse mit numpy
- WebSocket-Server (geventwebsocket)
- HTTP-Server für HTML-Interface

**Ports:**
- HTTP: 8081
- WebSocket: 8081/ws

**Abhängigkeiten:**
- `pyalsaaudio` ✅ (verfügbar)
- `numpy` ✅ (verfügbar)
- `geventwebsocket` ✅ (verfügbar)

### **2. /etc/systemd/system/audio-visualizer.service**

```ini
[Unit]
Description=Audio Visualizer Service (WebSocket + HTTP)
After=sound.target
After=network.target
Wants=sound.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/hifiberry/bin/audio-visualizer-service.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### **3. /etc/systemd/system/cog-visualizer.service**

```ini
[Unit]
Description=Local web browser - Visualizer Mode
Requires=weston.service
After=weston.service
After=audio-visualizer.service
Conflicts=cog.service

[Service]
Type=simple
Environment=COG_PLATFORM_FDO_VIEW_FULLSCREEN=1
Environment=WAYLAND_DISPLAY=wayland-1
Environment=XDG_RUNTIME_DIR=/var/run/weston
ExecStartPre=/opt/hifiberry/bin/bootmsg "Starting visualizer browser"
ExecStart=cog --webprocess-failure=restart -P wl http://localhost:8081/visualizer.html
StandardOutput=journal
Restart=always
RestartSec=20
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
```

### **4. /opt/hifiberry/bin/visualizer-on.sh**

```bash
#!/bin/bash
# Visualizer EINschalten
systemctl stop cog.service 2>/dev/null
systemctl start audio-visualizer.service
sleep 2
systemctl start cog-visualizer.service
```

### **5. /opt/hifiberry/bin/visualizer-off.sh**

```bash
#!/bin/bash
# Visualizer AUSschalten
systemctl stop cog-visualizer.service
systemctl start cog.service
```

---

## VERWENDUNG

### **Visualizer EINschalten:**

```bash
/opt/hifiberry/bin/visualizer-on.sh
```

oder:

```bash
systemctl stop cog.service
systemctl start audio-visualizer.service
systemctl start cog-visualizer.service
```

### **Visualizer AUSschalten:**

```bash
/opt/hifiberry/bin/visualizer-off.sh
```

oder:

```bash
systemctl stop cog-visualizer.service
systemctl start cog.service
```

### **Status prüfen:**

```bash
systemctl status audio-visualizer.service
systemctl status cog-visualizer.service
```

### **Logs ansehen:**

```bash
journalctl -u audio-visualizer.service -f
journalctl -u cog-visualizer.service -f
```

---

## TECHNISCHE DETAILS

### **Audio-Capture:**

- **Device:** `hw:0,0` (HiFiBerry DAC+ Pro)
- **Format:** S16_LE (16-bit signed little-endian)
- **Sample Rate:** 44100 Hz
- **Channels:** 2 (Stereo)
- **Chunk Size:** 2048 Samples

### **FFT-Analyse:**

- **FFT Size:** 4096
- **Bands:** 64 (logarithmische Verteilung 20Hz-20kHz)
- **Update Rate:** ~100 FPS

### **Visualisierung:**

- **Canvas:** 1280x400 Pixel
- **Bars:** 64 (PeppyMeter-Style)
- **Gradient:** Gold → Orange → Red
- **Smoothing:** 0.7 Faktor

---

## PROBLEME & LÖSUNGEN

### **Problem: Keine Audio-Daten**

**Lösung:**
- Prüfe ALSA-Device: `aplay -l`
- Prüfe Mixer: `amixer -c 0`
- Prüfe ob Audio läuft: `systemctl status mpd.service`

### **Problem: WebSocket-Verbindung fehlgeschlagen**

**Lösung:**
- Prüfe Service: `systemctl status audio-visualizer.service`
- Prüfe Port: `netstat -tlnp | grep 8081`
- Prüfe Logs: `journalctl -u audio-visualizer.service -n 50`

### **Problem: Browser zeigt keine Visualisierung**

**Lösung:**
- Prüfe cog-Service: `systemctl status cog-visualizer.service`
- Prüfe URL: `http://localhost:8081/visualizer.html`
- Prüfe Weston: `systemctl status weston.service`

---

## NÄCHSTE SCHRITTE

1. ✅ Audio-Analyse implementiert
2. ✅ WebSocket-Server implementiert
3. ✅ HTML-Interface implementiert
4. ✅ Systemd Services erstellt
5. ✅ Umschalt-Skripte erstellt
6. ⏳ Testen auf Pi 4
7. ⏳ Performance-Optimierung
8. ⏳ UI-Verbesserungen (optional)

---

## REFERENZEN

- **PeppyMeter:** https://github.com/project-owner/peppymeter
- **geventwebsocket:** https://github.com/jgelens/gevent-websocket
- **pyalsaaudio:** https://github.com/larsimmisch/pyalsaaudio
- **HiFiBerryOS:** https://github.com/hifiberry/hifiberry-os

---

**Status:** ✅ Implementiert, ⏳ Testing

