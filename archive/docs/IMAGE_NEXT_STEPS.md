# 📦 IMAGE - NÄCHSTE SCHRITTE

**Datum:** 2025-12-07  
**Status:** Image verfügbar, bereit für nächste Schritte

---

## ✅ AKTUELLER STATUS

### **Image verfügbar:**
- 📦 **ZIP:** `image_2025-12-07-moode-r1001-arm64-lite.zip` (1.4 GB)
- 📅 **Erstellt:** 7. Dezember 2025, 09:14
- 💾 **Enthält:** `2025-12-07-moode-r1001-arm64-lite.img` (5.2 GB)
- 📋 **Info:** `2025-12-07-moode-r1001-arm64-lite.info` (Package-Liste)

### **Docker:**
- ✅ Container läuft (`moode-builder`)
- ⚠️ Kein aktiver Build-Prozess

---

## 🎯 NÄCHSTE SCHRITTE

### **Option 1: Image extrahieren und testen** (Empfohlen)
```bash
# 1. Image extrahieren
cd imgbuild/deploy
unzip image_2025-12-07-moode-r1001-arm64-lite.zip

# 2. Image auf SD-Karte brennen
# (SD-Karte einstecken, dann:)
~/BURN_NOW.sh
# Oder manuell:
# sudo dd if=2025-12-07-moode-r1001-arm64-lite.img of=/dev/rdiskX bs=1m status=progress

# 3. Pi testen
# - SD-Karte in Pi einstecken
# - Boot testen
# - Display testen (Landscape, Browser)
# - Audio testen (HiFiBerry AMP100)
# - SSH testen (andre/0815)
```

### **Option 2: Neuer Build starten** (Wenn Änderungen nötig)
```bash
# 1. Custom Components integrieren
bash INTEGRATE_CUSTOM_COMPONENTS.sh

# 2. Build starten
docker-compose -f docker-compose.build.yml exec moode-builder bash /build/build.sh
# Oder:
~/START_BUILD_WHEN_READY.sh
```

---

## 🔍 WAS ENTHÄLT DAS IMAGE?

### **Basierend auf .info Datei:**
- ✅ moOde Audio r1001
- ✅ Debian Trixie (arm64)
- ✅ Alle Custom Components:
  - `fix-ssh-sudoers.service` (permanente SSH/Sudoers-Lösung)
  - `localdisplay.service` (Chromium Browser)
  - `disable-console.service` (Console deaktiviert)
  - Alle Custom Scripts
- ✅ User `andre` mit Password `0815`
- ✅ Hostname `GhettoBlaster`
- ✅ Display Rotation `0` (Landscape)
- ✅ WLAN konfiguriert ("Martin Router King")

---

## 📋 PRÜF-LISTE NACH BURN

### **Nach dem Brennen auf SD-Karte:**

1. **Boot:**
   - [ ] Pi bootet erfolgreich
   - [ ] Keine Fehler im Boot-Prozess

2. **Display:**
   - [ ] Display zeigt Landscape (nicht Portrait)
   - [ ] Browser startet automatisch
   - [ ] Browser zeigt moOde Web-UI
   - [ ] Keine Console auf Display

3. **Netzwerk:**
   - [ ] WLAN verbunden ("Martin Router King")
   - [ ] SSH aktiv (Port 22)
   - [ ] Web-UI erreichbar (http://GhettoBlaster.local oder IP)

4. **Login:**
   - [ ] SSH-Login funktioniert (`andre` / `0815`)
   - [ ] `sudo` funktioniert ohne Passwort
   - [ ] Hostname ist `GhettoBlaster`

5. **Audio:**
   - [ ] HiFiBerry AMP100 erkannt
   - [ ] Audio funktioniert
   - [ ] Touchscreen funktioniert (FT6236)

---

## 🚀 EMPFOHLENE REIHENFOLGE

### **1. Image extrahieren:**
```bash
cd imgbuild/deploy
unzip image_2025-12-07-moode-r1001-arm64-lite.zip
```

### **2. SD-Karte brennen:**
```bash
# SD-Karte einstecken
diskutil list  # SD-Karte identifizieren (z.B. /dev/disk4)

# Image brennen
~/BURN_NOW.sh
# Oder manuell mit korrektem Device
```

### **3. Pi testen:**
- SD-Karte in Pi einstecken
- Pi booten
- Alle Punkte der Prüf-Liste durchgehen

### **4. Bei Problemen:**
- Logs prüfen (`/var/log/chromium-clean.log`)
- SSH-Verbindung testen
- Services prüfen (`systemctl status localdisplay.service`)
- Neuer Build mit Fixes

---

## 💡 HINWEISE

### **Image ist aktuell:**
- ✅ Erstellt heute (7. Dezember 2025)
- ✅ Enthält alle neuesten Fixes
- ✅ `fix-ssh-sudoers.service` aktiviert
- ✅ Display Rotation korrekt (`display_rotate=0`)

### **Wenn neuer Build nötig:**
- Änderungen in `custom-components/` machen
- `INTEGRATE_CUSTOM_COMPONENTS.sh` ausführen
- Build starten (dauert ~1-2 Stunden)

---

**Status:** ✅ IMAGE BEREIT FÜR TEST  
**Nächster Schritt:** Image extrahieren und auf SD-Karte brennen

