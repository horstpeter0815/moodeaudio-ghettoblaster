# CUSTOM BUILD FINAL PLAN - GHETTOBLASTER

**Datum:** 2. Dezember 2025  
**Status:** READY FOR BUILD  
**System:** Ghettoblaster Custom Build

---

## ✅ VORBEREITUNG ABGESCHLOSSEN

### **1. Custom Komponenten erstellt:**
- ✅ Overlays (FT6236, AMP100)
- ✅ Services (4 Services)
- ✅ Scripts (3 Scripts)
- ✅ Config Templates

### **2. moOde Source integriert:**
- ✅ Services in `lib/systemd/system/`
- ✅ Scripts in `usr/local/bin/`
- ✅ Config Template in `boot/firmware/config.txt.overwrite`
- ✅ Overlays vorbereitet

---

## 🔧 BUILD-PROZESS

### **PHASE 1: BUILD-VORBEREITUNG**

**Status:** ✅ ABGESCHLOSSEN
- ✅ imgbuild Repository geklont
- ✅ Custom Komponenten erstellt
- ✅ moOde Source integriert

---

### **PHASE 2: BUILD-KONFIGURATION**

**Zu tun:**
1. ⏳ Pi-gen Konfiguration prüfen
2. ⏳ Build-Parameter anpassen
3. ⏳ Dependencies prüfen

---

### **PHASE 3: BUILD AUSFÜHREN**

**Build-Befehl:**
```bash
cd imgbuild
./build.sh
```

**Build-Zeit:** 8-12 Stunden

**Zu überwachen:**
- Build-Logs
- Fehler
- Fortschritt

---

### **PHASE 4: TESTING**

**Nach Build:**
1. Image auf SD-Karte schreiben
2. Boot-Test auf Pi 5
3. Funktionalitätstest
4. Stabilitätstest (3x Reboot)

---

## 📋 INTEGRIERTE KOMPONENTEN

### **Services:**
- `localdisplay.service` - Display mit X Server Ready Check
- `xserver-ready.service` - X Server Ready Check
- `ft6236-delay.service` - Touchscreen nach Display
- `peppymeter.service` - PeppyMeter Visualizer

### **Scripts:**
- `xserver-ready.sh` - X Server Ready Check
- `start-chromium-clean.sh` - Sauberes Chromium Startup
- `worker-php-patch.sh` - worker.php Patch

### **Config:**
- `config.txt.overwrite` - Custom Boot-Konfiguration
  - `display_rotate=3`
  - `hdmi_cvt=1280 400 60 6 0 0 0`
  - `dtoverlay=hifiberry-amp100,automute`

---

## ✅ SUCCESS CRITERIA

**Custom Build ist erfolgreich, wenn:**
- ✅ Image baut ohne Fehler
- ✅ Pi 5 bootet erfolgreich
- ✅ Display zeigt 1280x400 Landscape
- ✅ Touchscreen funktioniert
- ✅ Audio (AMP100) funktioniert
- ✅ Chromium startet automatisch
- ✅ PeppyMeter funktioniert
- ✅ 3x Reboot ohne Probleme
- ✅ Keine Workarounds nötig

---

**Status:** ✅ BEREIT FÜR BUILD  
**Nächster Schritt:** Build starten

