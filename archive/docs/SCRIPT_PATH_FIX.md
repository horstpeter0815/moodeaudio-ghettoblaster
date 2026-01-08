# 🔴 KRITISCHES PROBLEM: SCRIPT-PFADE

**Datum:** 2025-12-07  
**Problem:** Scripts werden im falschen Verzeichnis ausgeführt

---

## 🔴 PROBLEM

**Fehler:**
```bash
./BUILD_NOW_GUARANTEED.sh
zsh: no such file or directory: ./BUILD_NOW_GUARANTEED.sh
```

**Ursache:**
- Script liegt im Projekt-Verzeichnis
- User ist im Home-Verzeichnis (`~`)
- Relativer Pfad funktioniert nicht

---

## ✅ LÖSUNG

### **1. Script im Home-Verzeichnis:**
```bash
~/BUILD_NOW.sh
```

**Funktioniert von überall aus!**

### **2. Oder absoluter Pfad:**
```bash
"/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/BUILD_NOW_GUARANTEED.sh"
```

### **3. Oder cd ins Projekt-Verzeichnis:**
```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
./BUILD_NOW_GUARANTEED.sh
```

---

## 📋 ALLE WICHTIGEN SCRIPTS

### **Im Home-Verzeichnis (von überall ausführbar):**
- `~/BUILD_NOW.sh` - Build starten
- `~/BURN_NOW.sh` - Image brennen (falls vorhanden)

### **Im Projekt-Verzeichnis:**
- `./BUILD_NOW_GUARANTEED.sh` - Build mit Guaranteed Fixes
- `./INTEGRATE_CUSTOM_COMPONENTS.sh` - Komponenten integrieren
- `./SETUP_PI_DEBUGGER.sh` - Debugger installieren

---

## 🎯 REGEL

**WICHTIG:**
- Scripts im Projekt-Verzeichnis: `cd` ins Projekt-Verzeichnis ZUERST
- Oder: Scripts im Home-Verzeichnis verwenden (`~/BUILD_NOW.sh`)

---

**Status:** ✅ PROBLEM ERKANNT UND GELÖST  
**Lösung:** Script im Home-Verzeichnis erstellt

