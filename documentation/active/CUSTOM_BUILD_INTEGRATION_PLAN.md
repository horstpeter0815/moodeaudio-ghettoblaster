# CUSTOM BUILD INTEGRATION PLAN - GHETTOBLASTER

**Datum:** 2. Dezember 2025  
**Status:** IN PROGRESS  
**System:** Ghettoblaster Custom Build

---

## 🎯 ZIEL

**Custom moOde Image mit:**
- ✅ Integrierten Custom Komponenten
- ✅ Keine Workarounds
- ✅ Saubere Service-Abhängigkeiten
- ✅ Permanente Lösungen
- ✅ Zukunftssicher und erweiterbar

---

## 📋 CUSTOM KOMPONENTEN (ERSTELLT)

### **1. Overlays**
- ✅ `ghettoblaster-ft6236.dts` - Touchscreen Overlay
- ✅ `ghettoblaster-amp100.dts` - AMP100 Overlay für Pi 5

### **2. Services**
- ✅ `localdisplay.service` - Display mit X Server Ready Check
- ✅ `xserver-ready.service` - X Server Ready Check
- ✅ `ft6236-delay.service` - Touchscreen nach Display
- ✅ `peppymeter.service` - PeppyMeter Visualizer

### **3. Scripts**
- ✅ `xserver-ready.sh` - X Server Ready Check
- ✅ `start-chromium-clean.sh` - Sauberes Chromium Startup
- ✅ `worker-php-patch.sh` - worker.php Patch für display_rotate=3

### **4. Config Templates**
- ✅ `config.txt.template` - Boot-Konfiguration
- ✅ `cmdline.txt.template` - Kernel-Parameter

---

## 🔧 INTEGRATION IN MOODE BUILD

### **PHASE 1: MOODE SOURCE ANALYSIEREN**

**Zu analysieren:**
- moOde Build-Prozess (Pi-gen)
- Service-Integration-Mechanismus
- Overlay-Integration-Mechanismus
- Config.txt Management

**Wichtige Verzeichnisse:**
- `moode-source/etc/systemd/system/` - Custom Services
- `moode-source/lib/systemd/system/` - System Services
- `moode-source/boot/firmware/config.txt.overwrite` - Config Template

---

### **PHASE 2: CUSTOM KOMPONENTEN INTEGRIEREN**

**Services integrieren:**
1. Kopiere Custom Services nach `moode-source/etc/systemd/system/`
2. Stelle sicher dass Abhängigkeiten korrekt sind
3. Teste Service-Start

**Overlays integrieren:**
1. Kompiliere DTS zu DTBO
2. Integriere in Build-Prozess
3. Füge zu config.txt hinzu

**Scripts integrieren:**
1. Kopiere Scripts nach `moode-source/usr/local/bin/`
2. Setze Permissions
3. Teste Funktionalität

**Config Templates:**
1. Ersetze `config.txt.overwrite` mit Custom Template
2. Ersetze cmdline.txt Template
3. Stelle sicher dass display_rotate=3 gesetzt ist

---

### **PHASE 3: WORKER.PHP PATCH INTEGRIEREN**

**Methode 1: Post-Build Script**
- Patch wird nach Build angewendet
- Einfach, aber nicht im Source

**Methode 2: Source-Patch**
- Patch direkt in `moode-source/var/www/daemon/worker.php`
- Permanenter, aber Source-Änderung

**Empfehlung:** Methode 2 (Source-Patch)

---

## 📊 BUILD-PROZESS

### **1. moOde Source vorbereiten**
```bash
cd moode-source
# Custom Services kopieren
cp ../custom-components/services/* etc/systemd/system/
# Custom Scripts kopieren
cp ../custom-components/scripts/* usr/local/bin/
# Config Template ersetzen
cp ../custom-components/configs/config.txt.template boot/firmware/config.txt.overwrite
# worker.php patchen
../custom-components/scripts/worker-php-patch.sh
```

### **2. Build starten**
```bash
cd imgbuild
./build.sh
```

### **3. Image testen**
- Image auf SD-Karte schreiben
- Boot-Test auf Pi 5
- Funktionalitätstest
- Stabilitätstest (3x Reboot)

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
- ✅ display_rotate=3 bleibt erhalten

---

**Status:** KOMPONENTEN ERSTELLT  
**Nächster Schritt:** moOde Source analysieren und integrieren

