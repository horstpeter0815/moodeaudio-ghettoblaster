# GHETTO OS - VINYL INTEGRATION PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**System:** Ghetto Blaster (Ghetto OS)  
**Zweck:** Vinyl-Player Integration über Web-Stream

---

## 🎯 ANFORDERUNGEN

**Hardware-Setup:**
- ✅ **Ghetto Blaster (Pi 5):** moOde Audio System
- ✅ **Vinyl Pi (Pi 4):** Raspberry Pi mit ADC (Analog-Digital-Converter)
- ✅ **Web-Stream:** Vinyl Pi sendet Audio-Stream über Netzwerk

**Funktionalität:**
- ✅ Web-Stream empfangen (vom Vinyl Pi)
- ✅ Audio abspielen (auf Ghetto Blaster)
- ✅ Grafische Auswahl (Vinyl-Player in UI)
- ✅ Visualisierung (PeppyMeter)

---

## 📋 SYSTEM-ARCHITEKTUR

```
┌─────────────────────────────────────────────────────────┐
│              VINYL PI (Pi 4)                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                │
│  │ Vinyl Player │───▶│ ADC (Analog   │                │
│  │ (Plattenspieler)│    │ Digital Conv.)│                │
│  └──────────────┘    └──────────────┘                │
│         │                    │                        │
│         │                    │                        │
│         └──────────┬──────────┘                        │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  Web-Stream Server   │                      │
│         │  (HTTP/HTTPS Stream)│                      │
│         └──────────────────────┘                      │
│                    │                                   │
│                    │ (Netzwerk)                        │
└────────────────────┼───────────────────────────────────┘
                     │
                     │
┌────────────────────┼───────────────────────────────────┐
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  Web-Stream Client   │                      │
│         │  (MPD Input)         │                      │
│         └──────────────────────┘                      │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  MPD (Music Player)   │                      │
│         └──────────────────────┘                      │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  Audio Output        │                      │
│         │  (HiFiBerry AMP100)  │                      │
│         └──────────────────────┘                      │
│                    │                                   │
│                    ▼                                   │
│         ┌──────────────────────┐                      │
│         │  PeppyMeter          │                      │
│         │  (Visualisierung)     │                      │
│         └──────────────────────┘                      │
│                                                         │
│              GHETTO BLASTER (Pi 5)                     │
│              GHETTO OS                                 │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 IMPLEMENTIERUNGS-OPTIONEN

### **Option 1: HTTP/HTTPS Stream (Empfohlen)**

**Vinyl Pi:**
- Web-Stream Server (z.B. Icecast, Shoutcast, oder custom)
- Stream URL: `http://vinyl-pi-ip:port/stream`

**Ghetto Blaster:**
- MPD HTTP-Input Plugin
- Stream als "Radio" in MPD
- Grafische Auswahl in Web-UI

**Vorteile:**
- ✅ Standard-Protokoll
- ✅ Einfach zu implementieren
- ✅ Funktioniert mit MPD

---

### **Option 2: MPD Stream Input**

**Vinyl Pi:**
- MPD mit HTTP-Output
- Stream über MPD-Protokoll

**Ghetto Blaster:**
- MPD als Stream-Client
- Direkte MPD-zu-MPD Verbindung

**Vorteile:**
- ✅ Native MPD-Integration
- ✅ Synchronisation möglich

**Nachteile:**
- ⚠️ Komplexer Setup

---

### **Option 3: WebRTC Stream**

**Vinyl Pi:**
- WebRTC Server
- Low-Latency Streaming

**Ghetto Blaster:**
- WebRTC Client
- Direkte Verbindung

**Vorteile:**
- ✅ Niedrige Latenz
- ✅ Gute Qualität

**Nachteile:**
- ⚠️ Komplexere Integration

---

## 📋 IMPLEMENTIERUNGS-PHASEN

### **PHASE 1: Web-Stream Empfang (MPD)**

**MPD Konfiguration:**
```ini
# /etc/mpd.conf
input {
    plugin "httpd"
    enabled "yes"
}

# Stream als Radio-Station
playlist {
    name "Vinyl Player"
    path "http://vinyl-pi-ip:8000/stream"
}
```

**Script: `/opt/ghetto-os/bin/add-vinyl-stream.sh`**
```bash
#!/bin/bash
# Fügt Vinyl-Stream zu MPD hinzu

VINYL_IP=${1:-"192.168.178.XXX"}
VINYL_PORT=${2:-"8000"}
STREAM_URL="http://$VINYL_IP:$VINYL_PORT/stream"

# Füge Stream zu MPD Playlist hinzu
mpc add "$STREAM_URL"
mpc save "Vinyl Player"
```

---

### **PHASE 2: Grafische Auswahl (Web-UI)**

**Web-UI Integration:**
- Button "Vinyl Player" in moOde Web-UI
- Dropdown für verfügbare Streams
- Start/Stop-Funktion

**Optionen:**
1. **moOde Web-UI erweitern** (PHP/JavaScript)
2. **Eigene Web-Seite** (HTML/JavaScript)
3. **API-Endpoint** (REST API)

---

### **PHASE 3: Visualisierung**

**PeppyMeter Integration:**
- ✅ Bereits vorhanden
- ✅ Funktioniert mit MPD FIFO
- ✅ Zeigt Audio-Visualisierung

**Erweiterungen:**
- Vinyl-Player Status anzeigen
- Stream-Qualität anzeigen
- Verbindungsstatus

---

## 🔧 TECHNISCHE DETAILS

### **MPD HTTP-Input:**

**Installation:**
```bash
# MPD HTTP-Input Plugin installieren
apt-get install mpd-httpd
```

**Konfiguration:**
```ini
# /etc/mpd.conf
input {
    plugin "httpd"
    enabled "yes"
    port "6600"
}

# Stream hinzufügen
playlist {
    name "Vinyl Player"
    path "http://vinyl-pi-ip:8000/stream"
}
```

---

### **Stream-Format:**

**Empfohlene Formate:**
- ✅ MP3 (kompatibel, einfach)
- ✅ OGG Vorbis (bessere Qualität)
- ✅ FLAC (lossless, höhere Bandbreite)

**Stream-Parameter:**
- Bitrate: 320 kbps (MP3) oder 192 kbps (OGG)
- Sample Rate: 44.1 kHz oder 48 kHz
- Channels: Stereo

---

### **Netzwerk-Konfiguration:**

**Vinyl Pi:**
- Statische IP: `192.168.178.XXX`
- Port: `8000` (HTTP) oder `8080` (HTTPS)
- Firewall: Port öffnen

**Ghetto Blaster:**
- Netzwerk-Zugriff auf Vinyl Pi
- DNS-Auflösung (optional)

---

## 📊 DATEN-FLUSS

```
Vinyl Player
    ↓
ADC (Analog-Digital-Converter)
    ↓
Vinyl Pi (Web-Stream Server)
    ↓
HTTP/HTTPS Stream
    ↓
Netzwerk
    ↓
Ghetto Blaster (MPD HTTP-Input)
    ↓
MPD (Music Player Daemon)
    ↓
Audio Output (HiFiBerry AMP100)
    ↓
PeppyMeter (Visualisierung)
```

---

## ✅ IMPLEMENTIERUNGS-SCHRITTE

### **1. MPD HTTP-Input konfigurieren**
- HTTP-Input Plugin aktivieren
- Stream-URL hinzufügen
- Testen

### **2. Web-UI erweitern**
- Vinyl-Player Button
- Stream-Auswahl
- Start/Stop-Funktion

### **3. Visualisierung**
- PeppyMeter für Vinyl-Stream
- Status-Anzeige
- Qualitäts-Indikator

### **4. Automatisierung**
- Auto-Connect bei Start
- Stream-Status prüfen
- Fehlerbehandlung

---

## 📝 VINYL PI SETUP (Später)

**Hardware:**
- Raspberry Pi 4
- ADC (Analog-Digital-Converter)
- Vinyl Player (Plattenspieler)

**Software:**
- Web-Stream Server
- ADC-Treiber
- Audio-Encoding

**Integration:**
- Netzwerk-Konfiguration
- Stream-URL
- Authentifizierung (optional)

---

## ✅ VORTEILE

**Web-Stream:**
- ✅ Standard-Protokoll
- ✅ Einfach zu implementieren
- ✅ Flexibel (verschiedene Formate)

**Grafische Auswahl:**
- ✅ Benutzerfreundlich
- ✅ Intuitive Bedienung
- ✅ Status-Anzeige

**Visualisierung:**
- ✅ PeppyMeter bereits vorhanden
- ✅ Audio-Visualisierung
- ✅ Status-Anzeige

---

## 📝 NÄCHSTE SCHRITTE

1. **MPD HTTP-Input konfigurieren**
2. **Stream-Test durchführen**
3. **Web-UI erweitern**
4. **Visualisierung testen**
5. **Dokumentation erstellen**

---

**Status:** PLAN ERSTELLT  
**System:** Ghetto Blaster (Ghetto OS)  
**Nächster Schritt:** MPD HTTP-Input konfigurieren

