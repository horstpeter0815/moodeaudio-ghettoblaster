# 🧪 Testing Checklist - Custom moOde Image

**Image:** `2025-12-07-moode-r1001-arm64-lite.img`  
**Ziel:** Raspberry Pi 5 (Ghetto Blaster)  
**Status:** ✅ READY FOR TESTING

---

## 🔥 VOR DEM TEST

### **1. Image brennen:**
- [ ] SD-Karte einstecken
- [ ] Image brennen (balenaEtcher oder dd)
- [ ] SD-Karte in Raspberry Pi 5 stecken

### **2. Hardware verbinden:**
- [ ] HiFiBerry AMP100 HAT
- [ ] Display (1280x400)
- [ ] Touchscreen (FT6236)
- [ ] Netzwerk (Ethernet oder WLAN)
- [ ] Stromversorgung

---

## 🧪 FEATURE-TESTS

### **1. Basis-System:**
- [ ] System bootet
- [ ] Web-UI erreichbar (`http://moode.local` oder IP)
- [ ] Login funktioniert
- [ ] Audio-Output erkannt (HiFiBerry AMP100)

### **2. Room Correction Wizard:**
- [ ] Wizard öffnet (Button "Run Wizard")
- [ ] 5-Step Wizard funktioniert
- [ ] Test-Tone Playback
- [ ] File Upload funktioniert
- [ ] Browser Recording funktioniert
- [ ] Frequency Response Graph zeichnet
- [ ] Filter Generation funktioniert
- [ ] Filter Application funktioniert
- [ ] A/B Test funktioniert

### **3. Flat EQ Preset:**
- [ ] Checkbox sichtbar in Audio Settings
- [ ] Toggle funktioniert (Ein/Aus)
- [ ] EQ wird angewendet
- [ ] Preset wird gespeichert

### **4. PeppyMeter Extended Displays:**
- [ ] PeppyMeter startet
- [ ] Power Meter anzeigt
- [ ] Double-Tap: Wechsel zu Temp/Stream Info
- [ ] Single-Tap: PeppyMeter Ein/Aus
- [ ] Touch Gestures funktionieren

### **5. Display & Touch:**
- [ ] Display zeigt korrekt (1280x400)
- [ ] Rotation korrekt (Portrait)
- [ ] Touchscreen funktioniert
- [ ] Chromium startet automatisch

### **6. Audio:**
- [ ] HiFiBerry AMP100 erkannt
- [ ] Audio-Output funktioniert
- [ ] Volume Control funktioniert
- [ ] PCM5122 Oversampling (falls verfügbar)

### **7. Services:**
- [ ] I2C Monitor läuft
- [ ] I2C Stabilize läuft
- [ ] Audio Optimize läuft
- [ ] PeppyMeter Extended Displays läuft

---

## 🐛 BEKANNTE ISSUES ZU PRÜFEN

### **1. Kernel-Fix:**
- [ ] Post-Install Script funktioniert
- [ ] Keine "linuxkit" Fehler

### **2. I2C:**
- [ ] I2C funktioniert stabil
- [ ] AMP100 Kommunikation OK

### **3. Display:**
- [ ] Keine Rotation-Probleme
- [ ] Touchscreen kalibriert

---

## 📊 TEST-ERGEBNISSE

### **Nach Tests dokumentieren:**
- [ ] Welche Features funktionieren
- [ ] Welche Features Probleme haben
- [ ] Performance (CPU, RAM)
- [ ] Audio-Qualität
- [ ] UI/UX Feedback

---

## 🚀 NACH DEM TEST

### **Wenn alles funktioniert:**
- ✅ System ist produktionsbereit
- ✅ Features dokumentieren
- ✅ User Guide erstellen

### **Wenn Probleme:**
- ⏳ Issues dokumentieren
- ⏳ Fixes vorbereiten
- ⏳ Re-Build falls nötig

---

**Status:** ✅ READY FOR TESTING  
**Nächster Schritt:** Image brennen & System testen

