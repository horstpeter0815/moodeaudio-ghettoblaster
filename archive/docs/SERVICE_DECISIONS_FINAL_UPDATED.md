# SERVICE DECISIONS - FINAL (UPDATED)

**Datum:** 2. Dezember 2025  
**Status:** DECISIONS MADE - UNSICHERE SERVICES BEHALTEN

---

## ✅ FINALE ENTSCHEIDUNGEN

### **BLEIBEN (12 Services):**

**Essentielle (4):**
1. ✅ `mpd.service` - Audio-Core
2. ✅ `localdisplay.service` - Display
3. ✅ `nginx.service` - Web-UI
4. ✅ `php8.4-fpm.service` - Web-UI

**Touchscreen (1):**
5. ✅ `ft6236-delay.service` - Touchscreen

**PeppyMeter (4):**
6. ✅ `peppymeter.service` - Visualizer
7. ✅ `peppymeter-screensaver.service` - Screensaver (5 Min)
8. ✅ `peppymeter-position.service` - Position-Fix
9. ✅ `peppymeter-window-fix.service` - Window-Fix

**Unsichere - BEHALTEN (2):**
10. ✅ `display-rotate-fix.service` - BEHALTEN (können später entfernen)
11. ✅ `set-mpd-volume.service` - BEHALTEN (können später entfernen)

**Remote Access (1):**
12. ✅ `rpi-connect.service` / `rpi-connect-lite` - BEHALTEN (Remote-Zugriff)

---

### **ENTFERNEN (4 Services):**

1. ❌ `touchscreen-fix.service` - Redundant
2. ❌ `touchscreen-bind.service` - Redundant
3. ❌ `waveshare-touchscreen-delay.service` - Redundant
4. ❌ `chromium-monitor.service` - Redundant
5. ❌ `samba-ad-dc.service` - Nicht für Audio

---

## 📊 ERGEBNIS

**Vorher:** 15 Services  
**Nachher:** 12 Services (4 essentielle + 1 Touchscreen + 4 PeppyMeter + 2 unsichere + 1 Remote Access)  
**Entfernt:** 4 Services (nur redundante)

**Strategie:** Konservativ - behalten wenn unsicher, können später entfernen

---

**Status:** BEREIT FÜR TEST-SCRIPT ENTWICKLUNG

