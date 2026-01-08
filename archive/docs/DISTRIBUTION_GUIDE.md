# DISTRIBUTION GUIDE - moOde Audio Custom Build

**Datum:** 2. Dezember 2025  
**Version:** 1.0  
**Status:** READY FOR DISTRIBUTION

---

## 🎯 ÜBERSICHT

Dieses Guide beschreibt, wie das custom moOde Audio System für Freunde weitergegeben werden kann.

**System-Features:**
- ✅ moOde Audio Player (Series 10)
- ✅ Raspberry Pi 5 optimiert
- ✅ 1280x400 Landscape Display
- ✅ WaveShare FT6236 Touchscreen
- ✅ HiFiBerry AMP100 Audio
- ✅ PeppyMeter Integration
- ✅ Chromium Kiosk-Modus
- ✅ Boot-Screen-Nachricht
- ✅ Vollständig optimiert und stabil

---

## 📋 VORAUSSETZUNGEN

### **Hardware:**
- Raspberry Pi 5 (8GB empfohlen)
- SD-Karte (mindestens 32GB, Class 10)
- WaveShare 1280x400 Touchscreen Display
- HiFiBerry AMP100 Audio Board
- Netzteil (5V, mindestens 3A)

### **Software:**
- moOde Audio Image (Custom Build)
- Raspberry Pi Imager (zum Schreiben des Images)

---

## 🚀 INSTALLATION

### **Schritt 1: Image auf SD-Karte schreiben**

1. **SD-Karte vorbereiten:**
   - SD-Karte in Computer einstecken
   - Alle Daten sichern (wird gelöscht!)

2. **Raspberry Pi Imager öffnen:**
   - Download: https://www.raspberrypi.com/software/
   - Installieren und öffnen

3. **Image schreiben:**
   - "Choose OS" → "Use custom image"
   - Custom moOde Image auswählen
   - SD-Karte auswählen
   - "Write" klicken
   - Warten bis fertig (ca. 10-15 Minuten)

---

### **Schritt 2: Hardware anschließen**

1. **HiFiBerry AMP100:**
   - Auf Raspberry Pi 5 stecken (GPIO Header)
   - Sicherstellen, dass alle Pins korrekt sitzen

2. **Display:**
   - HDMI-Kabel an HDMI-2 Port anschließen
   - Touchscreen-Kabel an GPIO anschließen
   - Display mit Strom versorgen

3. **Netzteil:**
   - 5V, mindestens 3A Netzteil anschließen
   - SD-Karte einstecken

---

### **Schritt 3: Erster Start**

1. **System booten:**
   - Netzteil anschließen
   - Pi 5 startet automatisch
   - Boot-Screen-Nachricht sollte sichtbar sein

2. **Warten:**
   - Erster Boot dauert 2-3 Minuten
   - System konfiguriert sich automatisch

3. **Verifikation:**
   - Display zeigt moOde Web-UI
   - Touchscreen funktioniert
   - Audio funktioniert (Test-Sound abspielen)

---

## ⚙️ KONFIGURATION

### **Netzwerk (optional):**

**WLAN konfigurieren:**
1. Web-UI öffnen: `http://localhost` (lokal) oder `http://[IP-Adresse]` (vom Netzwerk)
2. System → Network → WiFi
3. Netzwerk auswählen und Passwort eingeben

**SSH aktivieren (optional):**
1. System → Configure → SSH
2. SSH aktivieren
3. Passwort setzen

---

### **Audio konfigurieren:**

**HiFiBerry AMP100:**
- System → Configure → Audio
- Audio device: "HiFiBerry AMP100"
- Volume: Anpassen nach Bedarf
- Auto-Mute: Aktiviert (verhindert Knacken beim Boot)

---

### **Display konfigurieren:**

**Touchscreen:**
- Sollte automatisch funktionieren
- Falls nicht: System → Configure → Display → Touchscreen

**Rotation:**
- Display ist auf Landscape (1280x400) vorkonfiguriert
- Änderung nicht empfohlen

---

## 🎵 NUTZUNG

### **Musik abspielen:**

1. **Lokale Musik:**
   - USB-Stick oder externe Festplatte anschließen
   - System → Library → Scan
   - Musik wird automatisch erkannt

2. **Web-Radio:**
   - System → Radio
   - Station auswählen oder URL eingeben

3. **Streaming:**
   - Spotify, AirPlay, etc. über System → Configure aktivieren

---

### **PeppyMeter (Audio-Visualizer):**

**Aktivieren:**
- System → Configure → PeppyMeter
- PeppyMeter aktivieren
- Als Screensaver (nach 10 Minuten Inaktivität)

**Deaktivieren:**
- Display berühren → Zurück zur Web-UI

---

## 🔧 TROUBLESHOOTING

### **Display zeigt nichts:**
- ✅ HDMI-Kabel prüfen
- ✅ Display-Stromversorgung prüfen
- ✅ SD-Karte neu schreiben

### **Touchscreen funktioniert nicht:**
- ✅ Touchscreen-Kabel prüfen
- ✅ System → Configure → Display → Touchscreen prüfen
- ✅ Reboot durchführen

### **Kein Audio:**
- ✅ HiFiBerry AMP100 korrekt angeschlossen?
- ✅ System → Configure → Audio → Device prüfen
- ✅ Lautstärke prüfen (nicht auf 0)
- ✅ Auto-Mute deaktivieren (falls nötig)

### **Chromium startet nicht:**
- ✅ System → Configure → Display → Local Display aktivieren
- ✅ Reboot durchführen
- ✅ Service-Status prüfen: `systemctl status localdisplay.service`

---

## 📝 SYSTEM-INFORMATIONEN

**Boot-Screen-Nachricht:**
```
╔══════════════════════════════════════════════════════════════╗
║          moOde Audio Player - Custom Build                  ║
║     Powered by Advanced AI Engineering                      ║
║     "Excellence is not a destination,                       ║
║      it's a continuous journey."                            ║
╚══════════════════════════════════════════════════════════════╝
```

**System-Services:**
- `localdisplay.service` - Display-Management
- `ft6236-delay.service` - Touchscreen
- `mpd.service` - Audio-Player
- `peppymeter.service` - Audio-Visualizer
- `chromium-monitor.service` - Browser-Monitoring

**Konfiguration:**
- Display: 1280x400 Landscape
- Audio: HiFiBerry AMP100
- Touchscreen: WaveShare FT6236
- Boot: Optimiert für Stabilität

---

## 🎁 WEITERGABE

**Für Freunde:**
1. Image auf SD-Karte schreiben
2. Hardware anschließen
3. System starten
4. Fertig!

**Keine zusätzliche Konfiguration nötig - alles ist vorkonfiguriert!**

---

## 📞 SUPPORT

**Bei Problemen:**
- moOde Forum: https://moodeaudio.org/forum
- Dokumentation: Siehe moOde Wiki
- System-Logs: `journalctl -u [service-name]`

---

## ✅ CHECKLISTE FÜR WEITERGABE

- [ ] Image auf SD-Karte geschrieben
- [ ] Hardware korrekt angeschlossen
- [ ] Erster Boot erfolgreich
- [ ] Display funktioniert
- [ ] Touchscreen funktioniert
- [ ] Audio funktioniert
- [ ] Boot-Screen-Nachricht sichtbar
- [ ] Web-UI erreichbar
- [ ] PeppyMeter funktioniert (optional)

---

**Status:** ✅ BEREIT FÜR WEITERGABE  
**Version:** 1.0  
**Datum:** 2. Dezember 2025

🚀 **VIEL ERFOLG MIT DEM SYSTEM!** 🚀

