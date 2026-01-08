# SERVICE ANALYSIS - HIGH-END AUDIO OPTIMIZATION

**Datum:** 2. Dezember 2025  
**Status:** ANALYSIS  
**Zweck:** Identifiziere nicht benötigte Services für High-End Audio

---

## 🎯 HARDWARE-SETUP

**Aktuelle Hardware:**
- Raspberry Pi 5
- HiFiBerry AMP100 (Audio)
- WaveShare 1280x400 Touchscreen Display
- moOde Audio Player

**Audio-Ziel:** High-End Audio Quality

---

## 📋 SERVICE-KATEGORIEN

### **1. ESSENTIELLE SERVICES (MÜSSEN BLEIBEN)**

#### **Audio-Core:**
- ✅ `mpd.service` - **MUSS BLEIBEN**
  - Music Player Daemon - Kern des Audio-Systems
  - Direkt für High-End Audio verantwortlich
  - **Status:** ESSENTIELL

#### **Display-Core:**
- ✅ `localdisplay.service` - **MUSS BLEIBEN**
  - Startet X Server und Display
  - Notwendig für Web-UI und Touchscreen
  - **Status:** ESSENTIELL

- ✅ `nginx.service` - **MUSS BLEIBEN**
  - Web-Server für moOde Web-UI
  - Notwendig für Konfiguration und Steuerung
  - **Status:** ESSENTIELL

- ✅ `php8.4-fpm.service` - **MUSS BLEIBEN**
  - PHP für moOde Web-UI
  - Notwendig für Web-Interface
  - **Status:** ESSENTIELL

---

### **2. TOUCHSCREEN SERVICES (OPTIONAL - ABER EMPFOHLEN)**

- ⚠️ `ft6236-delay.service` - **EMPFOHLEN**
  - Touchscreen-Initialisierung
  - Für Touch-Bedienung notwendig
  - **Status:** EMPFOHLEN (wenn Touchscreen genutzt wird)

- ⚠️ `touchscreen-fix.service` - **PRÜFEN**
  - Touchscreen-Fix
  - Möglicherweise redundant mit ft6236-delay
  - **Status:** PRÜFEN - Kann redundant sein

- ⚠️ `touchscreen-bind.service` - **PRÜFEN**
  - Touchscreen-Binding
  - Möglicherweise redundant
  - **Status:** PRÜFEN - Kann redundant sein

- ⚠️ `waveshare-touchscreen-delay.service` - **PRÜFEN**
  - WaveShare Touchscreen Delay
  - Möglicherweise redundant mit ft6236-delay
  - **Status:** PRÜFEN - Kann redundant sein

**Empfehlung:** Nur EINEN Touchscreen-Service behalten (ft6236-delay.service)

---

### **3. PEPPYMETER SERVICES (OPTIONAL)**

- ⚠️ `peppymeter.service` - **OPTIONAL**
  - Audio-Visualizer
  - Nicht notwendig für Audio-Qualität
  - **Status:** OPTIONAL - Kann entfernt werden, wenn nicht gewünscht

- ⚠️ `peppymeter-screensaver.service` - **OPTIONAL**
  - PeppyMeter als Screensaver
  - Abhängig von peppymeter.service
  - **Status:** OPTIONAL - Kann entfernt werden

- ⚠️ `peppymeter-position.service` - **OPTIONAL**
  - PeppyMeter Position-Fix
  - Abhängig von peppymeter.service
  - **Status:** OPTIONAL - Kann entfernt werden

- ⚠️ `peppymeter-window-fix.service` - **OPTIONAL**
  - PeppyMeter Window-Fix
  - Abhängig von peppymeter.service
  - **Status:** OPTIONAL - Kann entfernt werden

**Empfehlung:** Alle PeppyMeter-Services können entfernt werden, wenn Visualizer nicht gewünscht

---

### **4. CHROMIUM SERVICES (OPTIONAL)**

- ⚠️ `chromium-monitor.service` - **OPTIONAL**
  - Überwacht Chromium und startet neu
  - Kann durch systemd Restart-Policy ersetzt werden
  - **Status:** OPTIONAL - Kann entfernt werden (localdisplay hat bereits Restart=always)

**Empfehlung:** Kann entfernt werden, wenn localdisplay.service Restart=always hat

---

### **5. AUDIO-RELATED SERVICES (PRÜFEN)**

- ⚠️ `set-mpd-volume.service` - **PRÜFEN**
  - Setzt MPD Volume
  - Möglicherweise nicht notwendig
  - **Status:** PRÜFEN - Kann entfernt werden, wenn Volume manuell gesetzt wird

---

### **6. DISPLAY-RELATED SERVICES (PRÜFEN)**

- ⚠️ `display-rotate-fix.service` - **PRÜFEN**
  - Fix für Display-Rotation
  - Möglicherweise nicht notwendig, wenn config.txt korrekt ist
  - **Status:** PRÜFEN - Kann entfernt werden, wenn config.txt korrekt ist

---

### **7. NETWORK/SHARING SERVICES (NICHT FÜR AUDIO)**

- ❌ `samba-ad-dc.service` - **KANN ENTFERNT WERDEN**
  - Samba File-Sharing
  - Nicht notwendig für High-End Audio
  - **Status:** KANN ENTFERNT WERDEN (wenn kein File-Sharing benötigt)

---

### **8. BLUETOOTH SERVICES (NICHT FÜR HIGH-END AUDIO)**

- ❌ `bluealsa-aplay@.service` - **KANN ENTFERNT WERDEN**
  - Bluetooth Audio
  - Nicht für High-End Audio (Bluetooth ist verlustbehaftet)
  - **Status:** KANN ENTFERNT WERDEN (wenn kein Bluetooth benötigt)

- ❌ `bluealsa.overwrite.service` - **KANN ENTFERNT WERDEN**
  - Bluetooth Audio Overwrite
  - Nicht für High-End Audio
  - **Status:** KANN ENTFERNT WERDEN

- ❌ `bt-agent.service` - **KANN ENTFERNT WERDEN**
  - Bluetooth Agent
  - Nicht für High-End Audio
  - **Status:** KANN ENTFERNT WERDEN

---

### **9. STREAMING SERVICES (OPTIONAL)**

**Diese Services sind NICHT auf dem System aktiviert, aber verfügbar:**

- ❌ `squeezelite.service` - **KANN ENTFERNT WERDEN**
  - Logitech Squeezebox
  - Nicht notwendig, wenn nicht genutzt
  - **Status:** KANN ENTFERNT WERDEN (wenn nicht genutzt)

- ❌ `shairport-sync.service` - **KANN ENTFERNT WERDEN**
  - AirPlay
  - Nicht für High-End Audio (verlustbehaftet)
  - **Status:** KANN ENTFERNT WERDEN (wenn kein AirPlay benötigt)

- ❌ `roonbridge.service` - **KANN ENTFERNT WERDEN**
  - Roon Bridge
  - Nicht notwendig, wenn nicht genutzt
  - **Status:** KANN ENTFERNT WERDEN (wenn nicht genutzt)

- ❌ `spotifyd.service` - **KANN ENTFERNT WERDEN**
  - Spotify Connect
  - Nicht für High-End Audio (verlustbehaftet)
  - **Status:** KANN ENTFERNT WERDEN (wenn kein Spotify benötigt)

- ❌ `plexamp.service` - **KANN ENTFERNT WERDEN**
  - PlexAmp
  - Nicht notwendig, wenn nicht genutzt
  - **Status:** KANN ENTFERNT WERDEN (wenn nicht genutzt)

---

## 📊 EMPFEHLUNGEN FÜR HIGH-END AUDIO

### **MUSS BLEIBEN:**
1. ✅ `mpd.service` - Audio-Core
2. ✅ `localdisplay.service` - Display
3. ✅ `nginx.service` - Web-UI
4. ✅ `php8.4-fpm.service` - Web-UI

### **EMPFOHLEN (wenn Hardware vorhanden):**
5. ⚠️ `ft6236-delay.service` - Touchscreen (wenn Touchscreen genutzt)

### **KANN ENTFERNT WERDEN:**
- ❌ Alle PeppyMeter-Services (wenn Visualizer nicht gewünscht)
- ❌ `chromium-monitor.service` (redundant)
- ❌ `samba-ad-dc.service` (wenn kein File-Sharing)
- ❌ Alle Bluetooth-Services (nicht für High-End Audio)
- ❌ Redundante Touchscreen-Services (nur einen behalten)
- ❌ `display-rotate-fix.service` (wenn config.txt korrekt)
- ❌ `set-mpd-volume.service` (wenn Volume manuell gesetzt)

---

## 🎯 VORGESCHLAGENE BEREINIGUNG

### **Phase 1: Redundante Services entfernen**
1. Touchscreen: Nur `ft6236-delay.service` behalten
2. PeppyMeter: Alle entfernen (wenn nicht gewünscht)
3. Chromium: `chromium-monitor.service` entfernen

### **Phase 2: Nicht-Audio Services entfernen**
1. Samba entfernen
2. Bluetooth entfernen (wenn nicht benötigt)

### **Phase 3: Optimierung**
1. `display-rotate-fix.service` entfernen (wenn config.txt korrekt)
2. `set-mpd-volume.service` entfernen (wenn nicht benötigt)

---

## ✅ FINALE SERVICE-LISTE (MINIMAL FÜR HIGH-END AUDIO)

**Essentielle Services:**
1. `mpd.service`
2. `localdisplay.service`
3. `nginx.service`
4. `php8.4-fpm.service`
5. `ft6236-delay.service` (wenn Touchscreen)

**Das war's!** Alles andere ist optional.

---

**Status:** BEREIT FÜR DISKUSSION  
**Nächster Schritt:** Mit Benutzer durchgehen und Entscheidungen treffen

