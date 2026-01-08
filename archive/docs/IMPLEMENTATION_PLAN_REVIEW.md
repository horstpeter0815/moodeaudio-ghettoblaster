# IMPLEMENTATION PLAN - REVIEW

**Datum:** 2. Dezember 2025  
**Status:** BEREIT FÜR REVIEW  
**Nächster Schritt:** Gemeinsame Durchsicht vor Implementierung

---

## 📋 ZUSAMMENFASSUNG DER ENTSCHEIDUNGEN

### **BLEIBEN (9 Services):**
1. ✅ `mpd.service` - Audio-Core
2. ✅ `localdisplay.service` - Display
3. ✅ `nginx.service` - Web-UI
4. ✅ `php8.4-fpm.service` - Web-UI
5. ✅ `ft6236-delay.service` - Touchscreen (EINZIGER)
6. ✅ `peppymeter.service` - Visualizer
7. ✅ `peppymeter-screensaver.service` - Screensaver
8. ✅ `peppymeter-position.service` - Position-Fix
9. ✅ `peppymeter-window-fix.service` - Window-Fix

### **ENTFERNEN (6 Services):**
1. ❌ `touchscreen-fix.service` - Redundant
2. ❌ `touchscreen-bind.service` - Redundant
3. ❌ `waveshare-touchscreen-delay.service` - Redundant
4. ❌ `chromium-monitor.service` - Redundant
5. ❌ `samba-ad-dc.service` - Nicht für Audio
6. ❌ `display-rotate-fix.service` - Prüfen (wenn config.txt korrekt)

---

## ⚙️ KONFIGURATIONEN

### **PeppyMeter Screensaver:**
- **Aktuell:** 600 Sekunden (10 Minuten)
- **Neu:** 300 Sekunden (5 Minuten)
- **Verhalten:** Aktiviert nach 5 Min Inaktivität, deaktiviert bei Touch

---

## 🔧 IMPLEMENTIERUNGS-SCHRITTE

### **Schritt 1: PeppyMeter Screensaver konfigurieren**
- Timeout von 600 → 300 Sekunden ändern
- Script: `/usr/local/bin/peppymeter-screensaver.sh`

### **Schritt 2: Redundante Touchscreen-Services entfernen**
- `touchscreen-fix.service` deaktivieren & entfernen
- `touchscreen-bind.service` deaktivieren & entfernen
- `waveshare-touchscreen-delay.service` deaktivieren & entfernen

### **Schritt 3: Redundante/Unnötige Services entfernen**
- `chromium-monitor.service` deaktivieren & entfernen
- `samba-ad-dc.service` deaktivieren
- `display-rotate-fix.service` deaktivieren & entfernen

### **Schritt 4: Verifikation**
- Prüfen, dass nur gewünschte Services aktiv sind
- PeppyMeter Screensaver-Konfiguration prüfen

---

## 📊 ERGEBNIS

**Vorher:** 15 Services aktiv  
**Nachher:** 9 Services aktiv  
**Entfernt:** 6 Services

**Vorteile:**
- ✅ Weniger Ressourcen-Verbrauch
- ✅ Fokus auf High-End Audio
- ✅ Keine redundanten Services
- ✅ PeppyMeter Screensaver auf 5 Minuten

---

## ❓ FRAGEN VOR IMPLEMENTIERUNG

1. **display-rotate-fix.service:** Ist deine config.txt korrekt? (Dann können wir es sicher entfernen)
2. **set-mpd-volume.service:** Soll das Volume automatisch gesetzt werden? (Noch nicht entschieden)
3. **Reboot:** Soll nach der Implementierung ein Reboot durchgeführt werden?

---

## 🚀 NÄCHSTE SCHRITTE

1. **Review:** Gemeinsam durchgehen
2. **Plan anzeigen:** `./implement-service-cleanup.sh` (zeigt Plan)
3. **Implementieren:** `./implement-service-cleanup.sh execute` (führt aus)
4. **Verifikation:** Services prüfen
5. **Reboot:** Optional, um sicherzustellen

---

**Status:** BEREIT FÜR REVIEW  
**Script:** `implement-service-cleanup.sh`  
**Modus:** Plan (zeigt was gemacht wird) oder Execute (führt aus)

