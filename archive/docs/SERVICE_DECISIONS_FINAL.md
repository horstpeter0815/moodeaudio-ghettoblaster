# SERVICE DECISIONS - FINAL

**Datum:** 2. Dezember 2025  
**Status:** DECISIONS MADE  
**Nächster Schritt:** Implementierung vorbereiten

---

## ✅ ENTSCHEIDUNGEN

### **MUSS BLEIBEN (4 Services):**
1. ✅ `mpd.service` - Audio-Core
2. ✅ `localdisplay.service` - Display
3. ✅ `nginx.service` - Web-UI
4. ✅ `php8.4-fpm.service` - Web-UI

### **EMPFOHLEN - BEHALTEN (1 Service):**
5. ✅ `ft6236-delay.service` - Touchscreen (EINZIGER Touchscreen-Service)

### **PEPPYMETER - BEHALTEN (4 Services):**
6. ✅ `peppymeter.service` - Audio-Visualizer
7. ✅ `peppymeter-screensaver.service` - Screensaver (nach 5 Min Inaktivität)
8. ✅ `peppymeter-position.service` - Position-Fix
9. ✅ `peppymeter-window-fix.service` - Window-Fix

**PeppyMeter Konfiguration:**
- ✅ Als Screensaver nach 5 Minuten Inaktivität
- ✅ Visualizer ist gewünscht

---

## ❌ ZU ENTFERNEN (6 Services):

### **Redundante Touchscreen-Services (3):**
1. ❌ `touchscreen-fix.service` - Redundant (ft6236-delay reicht)
2. ❌ `touchscreen-bind.service` - Redundant
3. ❌ `waveshare-touchscreen-delay.service` - Redundant

### **Redundante/Unnötige Services (3):**
4. ❌ `chromium-monitor.service` - Redundant (localdisplay hat Restart=always)
5. ❌ `samba-ad-dc.service` - Nicht für High-End Audio
6. ❌ `display-rotate-fix.service` - Prüfen (wenn config.txt korrekt)

### **Zu prüfen:**
7. ⚠️ `set-mpd-volume.service` - Entscheidung noch offen

---

## 📊 FINALE SERVICE-LISTE

**BLEIBEN (9 Services):**
1. `mpd.service`
2. `localdisplay.service`
3. `nginx.service`
4. `php8.4-fpm.service`
5. `ft6236-delay.service`
6. `peppymeter.service`
7. `peppymeter-screensaver.service`
8. `peppymeter-position.service`
9. `peppymeter-window-fix.service`

**ENTFERNEN (6 Services):**
1. `touchscreen-fix.service`
2. `touchscreen-bind.service`
3. `waveshare-touchscreen-delay.service`
4. `chromium-monitor.service`
5. `samba-ad-dc.service`
6. `display-rotate-fix.service` (wenn config.txt korrekt)

---

## ⚙️ PEPPYMETER SCREENSAVER KONFIGURATION

**Anforderung:**
- PeppyMeter als Screensaver
- Aktiviert nach 5 Minuten Inaktivität
- Deaktiviert bei Touch

**Aktuelle Konfiguration prüfen:**
- `/etc/systemd/system/peppymeter-screensaver.service`
- `/usr/local/bin/peppymeter-screensaver.sh`
- Inaktivitäts-Timeout: 5 Minuten (300 Sekunden)

---

## 🔧 NÄCHSTE SCHRITTE

1. **PeppyMeter Screensaver auf 5 Minuten konfigurieren**
2. **Redundante Services entfernen**
3. **Verifikation**

---

**Status:** BEREIT FÜR IMPLEMENTIERUNG  
**Warten auf:** Bestätigung vor Implementierung

