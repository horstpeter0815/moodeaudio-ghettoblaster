# CUSTOM BUILD COMPREHENSIVE REVIEW - GHETTOBLASTER

**Datum:** 2. Dezember 2025  
**Status:** PRE-BUILD REVIEW  
**System:** Ghettoblaster Custom Build

---

## 🎯 ZIEL DER ÜBERPRÜFUNG

**Vor dem Build sicherstellen:**
- ✅ Alle Komponenten korrekt erstellt
- ✅ Integration in moOde Source korrekt
- ✅ Build-Prozess verstanden
- ✅ Abhängigkeiten korrekt
- ✅ Potenzielle Probleme identifiziert
- ✅ Lösungen vorbereitet

---

## 📋 PHASE 1: KOMPONENTEN-REVIEW

### **1.1 Services Review**

#### **localdisplay.service**
- ✅ **Status:** Integriert
- ✅ **Abhängigkeiten:** `graphical.target`, `xserver-ready.service`
- ⚠️ **Potenzielle Probleme:**
  - User ist `andre` - muss beim Build erstellt werden
  - `.Xauthority` Pfad muss existieren
- ✅ **Lösung:** User `andre` muss in Build-Stage erstellt werden

#### **xserver-ready.service**
- ✅ **Status:** Integriert
- ✅ **Abhängigkeiten:** `graphical.target`
- ⚠️ **Potenzielle Probleme:**
  - Script muss ausführbar sein
  - X Server muss verfügbar sein
- ✅ **Lösung:** Script ist ausführbar, X Server wird von moOde installiert

#### **ft6236-delay.service**
- ✅ **Status:** Integriert
- ✅ **Abhängigkeiten:** `localdisplay.service`, `xserver-ready.service`
- ⚠️ **Potenzielle Probleme:**
  - `ft6236` Modul muss verfügbar sein
  - Overlay muss kompiliert sein
- ✅ **Lösung:** Overlay wird kompiliert, Modul wird geladen

#### **peppymeter.service**
- ✅ **Status:** Integriert
- ✅ **Abhängigkeiten:** `localdisplay.service`, `mpd.service`
- ⚠️ **Potenzielle Probleme:**
  - PeppyMeter muss installiert sein
  - Wrapper-Script muss existieren
- ⚠️ **FEHLT:** `peppymeter-wrapper.sh` nicht integriert!

---

### **1.2 Scripts Review**

#### **xserver-ready.sh**
- ✅ **Status:** Integriert, ausführbar
- ✅ **Funktionalität:** Prüft X Server Ready
- ⚠️ **Potenzielle Probleme:**
  - `xrandr` und `xdpyinfo` müssen verfügbar sein
- ✅ **Lösung:** Werden von moOde installiert

#### **start-chromium-clean.sh**
- ✅ **Status:** Integriert, ausführbar
- ✅ **Funktionalität:** Startet Chromium sauber
- ⚠️ **Potenzielle Probleme:**
  - Chromium muss installiert sein
  - `xdotool` muss verfügbar sein
  - User `andre` muss existieren
- ✅ **Lösung:** Chromium wird von moOde installiert, `xdotool` auch

#### **worker-php-patch.sh**
- ✅ **Status:** Integriert, ausführbar
- ✅ **Funktionalität:** Patched worker.php für display_rotate=3
- ⚠️ **Potenzielle Probleme:**
  - worker.php muss existieren
  - Patch muss zur richtigen Zeit angewendet werden
- ⚠️ **WICHTIG:** Patch muss nach moOde Installation angewendet werden!

---

### **1.3 Config Review**

#### **config.txt.overwrite**
- ✅ **Status:** Integriert
- ✅ **Wichtige Einstellungen:**
  - `display_rotate=3` ✅
  - `hdmi_cvt=1280 400 60 6 0 0 0` ✅
  - `dtoverlay=hifiberry-amp100,automute` ✅
- ⚠️ **Potenzielle Probleme:**
  - `[pi5]` Section existiert, aber Pi 5 spezifische Einstellungen fehlen
  - `dtoverlay=vc4-kms-v3d-pi5,noaudio` ist korrekt für Pi 5
- ⚠️ **WICHTIG:** `hdmi_group=0` und `hdmi_group=2` sind beide gesetzt - Konflikt!

---

### **1.4 Overlays Review**

#### **ghettoblaster-ft6236.dts**
- ✅ **Status:** Integriert
- ⚠️ **Potenzielle Probleme:**
  - Overlay muss zu `.dtbo` kompiliert werden
  - Kompatibilität mit Pi 5 prüfen (`brcm,bcm2712`)
- ✅ **Lösung:** Post-Build Script erstellt

#### **ghettoblaster-amp100.dts**
- ✅ **Status:** Integriert
- ⚠️ **Potenzielle Probleme:**
  - Overlay muss zu `.dtbo` kompiliert werden
  - Kompatibilität mit Pi 5 prüfen (`brcm,bcm2712`)
  - `hifiberry-amp100` Overlay existiert bereits - Custom Overlay nötig?
- ⚠️ **WICHTIG:** Standard `hifiberry-amp100` Overlay sollte funktionieren!

---

## 📋 PHASE 2: INTEGRATION-REVIEW

### **2.1 Build-Prozess Analyse**

**moOde Build-Prozess:**
1. Pi-gen wird initialisiert
2. RaspiOS Lite wird als Basis verwendet
3. moOde Packages werden installiert
4. `moode-source` wird kopiert (wann genau?)
5. Image wird exportiert

**⚠️ KRITISCH:** Wann wird `moode-source` kopiert? Muss vor Build-Stage passieren!

---

### **2.2 User `andre` Erstellung**

**Problem:** Services verwenden User `andre`, aber moOde verwendet standardmäßig User `pi`.

**Lösung:** User `andre` muss in Build-Stage erstellt werden.

**Wo:** In `stage3_02-moode-install-post_00-run-chroot.sh` oder neuer Stage.

---

### **2.3 PeppyMeter Installation**

**Problem:** `peppymeter.service` benötigt PeppyMeter, aber ist es im Build enthalten?

**Lösung:** PeppyMeter muss installiert werden oder Service muss angepasst werden.

---

### **2.4 Overlay-Kompilierung**

**Problem:** DTS-Dateien müssen zu DTBO kompiliert werden.

**Lösung:** Post-Build Script existiert, aber wann wird es ausgeführt?

**⚠️ WICHTIG:** Overlay-Kompilierung muss nach Build, aber vor Image-Export passieren!

---

## 📋 PHASE 3: POTENZIELLE PROBLEME

### **3.1 Kritische Probleme**

1. ⚠️ **User `andre` fehlt** - Services funktionieren nicht
2. ⚠️ **peppymeter-wrapper.sh fehlt** - Service startet nicht
3. ⚠️ **config.txt Konflikt** - `hdmi_group=0` und `hdmi_group=2` beide gesetzt
4. ⚠️ **worker.php Patch Timing** - Muss nach moOde Installation
5. ⚠️ **Overlay-Kompilierung Timing** - Muss vor Image-Export

### **3.2 Mittlere Probleme**

1. ⚠️ **AMP100 Overlay** - Custom Overlay nötig oder Standard verwenden?
2. ⚠️ **PeppyMeter Installation** - Ist es im Build enthalten?
3. ⚠️ **moode-source Kopierung** - Wann passiert das im Build?

### **3.3 Kleine Probleme**

1. ⚠️ **Log-Verzeichnisse** - Müssen erstellt werden
2. ⚠️ **Permissions** - Müssen korrekt gesetzt sein

---

## 📋 PHASE 4: LÖSUNGEN

### **4.1 User `andre` erstellen**

**Lösung:** Erstelle Build-Stage Script:
```bash
# In stage3_02-moode-install-post_00-run-chroot.sh oder neue Stage
useradd -m -s /bin/bash andre
usermod -aG audio,video,spi,i2c,gpio andre
```

### **4.2 peppymeter-wrapper.sh erstellen**

**Lösung:** Erstelle Wrapper-Script:
```bash
#!/bin/bash
# PeppyMeter Wrapper
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
/opt/peppymeter/peppymeter.py
```

### **4.3 config.txt Konflikt lösen**

**Lösung:** Entferne `hdmi_group=0` aus `[all]` Section, behalte nur `hdmi_group=2` für Custom Mode.

### **4.4 worker.php Patch Timing**

**Lösung:** Patch in Post-Install Stage anwenden, nach moOde Installation.

### **4.5 Overlay-Kompilierung**

**Lösung:** Overlay-Kompilierung in Post-Install Stage, vor Image-Export.

---

## 📋 PHASE 5: BUILD-STAGE PLAN

### **Stage 3.03: Ghettoblaster Custom Components**

**Was:**
1. User `andre` erstellen
2. Custom Scripts kopieren (bereits in moode-source)
3. Custom Services kopieren (bereits in moode-source)
4. Overlays kompilieren
5. worker.php patchen
6. PeppyMeter Wrapper erstellen

**Wann:** Nach moOde Installation, vor Image-Export

---

## ✅ REVIEW-ZUSAMMENFASSUNG

### **Was ist gut:**
- ✅ Komponenten sind erstellt
- ✅ Integration ist vorbereitet
- ✅ Build-Prozess ist verstanden

### **Was fehlt:**
- ⚠️ User `andre` Erstellung
- ⚠️ `peppymeter-wrapper.sh`
- ⚠️ Build-Stage für Custom Components
- ⚠️ config.txt Konflikt-Lösung
- ⚠️ Overlay-Kompilierung Timing

### **Nächste Schritte:**
1. ⏳ User `andre` Erstellung planen
2. ⏳ `peppymeter-wrapper.sh` erstellen
3. ⏳ Build-Stage für Custom Components erstellen
4. ⏳ config.txt Konflikt lösen
5. ⏳ Overlay-Kompilierung integrieren
6. ⏳ worker.php Patch Timing sicherstellen

---

**Status:** ⚠️ REVIEW ABGESCHLOSSEN - FEHLENDE KOMPONENTEN IDENTIFIZIERT  
**Nächster Schritt:** Fehlende Komponenten erstellen und integrieren

