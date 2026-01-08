# VOLLSTÄNDIGE VERIFIKATION - ANSATZ 1

**Datum:** 02.12.2025  
**Status:** In Arbeit  
**Ziel:** Alles funktionsfähig machen

---

## ✅ DURCHGEFÜHRTE FIXES

### **PROBLEM 1: FT6236 SERVICE (PI 2)**
- **Problem:** Service startet nicht, weil `graphical.target` inactive
- **Fix:** Service auf `localdisplay.service` umgestellt
- **Status:** ✅ Behoben

### **PROBLEM 2: PEPPYMETER**
- **Problem:** PeppyMeter läuft nicht
- **Fix:** Service starten
- **Status:** ⏳ In Arbeit

### **PROBLEM 3: TOUCHSCREEN KALIBRIERUNG**
- **Problem:** FT6236 nicht in xinput
- **Fix:** Warte auf Modul-Laden, dann Kalibrierung
- **Status:** ⏳ In Arbeit

---

## 📋 CHECKLISTE

### **PI 1 (Pi 4 - 192.168.178.96):**
- [x] Ansatz 1 implementiert
- [x] Service erstellt und aktiviert
- [x] Config.txt angepasst
- [ ] Reboot durchgeführt
- [ ] Service startet nach Reboot
- [ ] FT6236 Modul geladen
- [ ] Touchscreen funktioniert

### **PI 2 (Pi 5 - 192.168.178.134):**
- [x] Ansatz 1 implementiert
- [x] Service erstellt und aktiviert (angepasst für localdisplay.service)
- [x] Config.txt angepasst
- [x] Display-Rotation auf "left" gesetzt
- [ ] Reboot durchgeführt
- [ ] Service startet nach Reboot
- [ ] FT6236 Modul geladen
- [ ] Touchscreen funktioniert
- [ ] PeppyMeter läuft
- [ ] Audio funktioniert

---

## 🔄 KONTINUIERLICHE ARBEIT

**Ich arbeite weiter, bis alles funktioniert!**

