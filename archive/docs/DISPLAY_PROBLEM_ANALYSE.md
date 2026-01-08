# DISPLAY PROBLEM - ANALYSE UND PLANUNG

**Datum:** 1. Dezember 2025  
**Problem:** Beide Displays blinken und sind inaktiv

---

## 🔍 PROBLEM-ANALYSE

### **Aktueller Status:**
- ❌ Beide Displays blinken
- ❌ X Server startet nicht stabil
- ❌ Chromium startet nicht
- ⚠️ Service läuft, aber Display funktioniert nicht

### **Mögliche Ursachen:**

1. **X Server Konfiguration:**
   - Falsche Display-Ausgabe (HDMI-1 vs HDMI-A-1)
   - Fehlende Berechtigungen
   - Konflikt mit anderen Services

2. **.xinitrc Probleme:**
   - Chromium startet nicht
   - Falsche Display-Variable
   - Touchscreen-Konfiguration fehlt

3. **Service-Konfiguration:**
   - Falscher User
   - Falsche Dependencies
   - Restart-Loop

4. **Hardware:**
   - HDMI-Verbindung
   - Display-Kompatibilität
   - Touchscreen-Overlay

---

## 📋 PLANUNG: SYSTEMATISCHES VORGEHEN

### **SCHRITT 1: DIAGNOSE**
- [ ] X Server Logs prüfen (`/var/log/Xorg.0.log`)
- [ ] Service Logs prüfen (`journalctl -u localdisplay.service`)
- [ ] Display-Ausgabe prüfen (`xrandr`)
- [ ] Chromium-Logs prüfen
- [ ] Prozesse prüfen (`ps aux | grep -E 'Xorg|chromium|xinit'`)

### **SCHRITT 2: MINIMALE KONFIGURATION**
- [ ] Einfache .xinitrc (nur X Server, kein Chromium)
- [ ] Service ohne Restart-Loop
- [ ] Manueller Start testen

### **SCHRITT 3: CHROMIUM HINZUFÜGEN**
- [ ] Chromium einzeln starten
- [ ] Display-Variable prüfen
- [ ] Kiosk-Mode testen

### **SCHRITT 4: TOUCHSCREEN**
- [ ] Touchscreen-Overlay prüfen
- [ ] xinput-Konfiguration testen
- [ ] Matrix prüfen

### **SCHRITT 5: SERVICE OPTIMIERUNG**
- [ ] Dependencies prüfen
- [ ] Restart-Verhalten anpassen
- [ ] Timeouts setzen

---

## 🔧 MÖGLICHE LÖSUNGEN

### **OPTION 1: LIGHTDM VERWENDEN**
- LightDM als Display Manager
- Automatischer Login
- .xsession statt .xinitrc

### **OPTION 2: X SERVER MANUELL STARTEN**
- Kein Service
- Start-Script in .bashrc oder .profile
- Einfacher, aber weniger robust

### **OPTION 3: SYSTEMD USER SERVICE**
- Service als User (nicht root)
- Bessere Berechtigungen
- Automatischer Start

### **OPTION 4: VNC/REMOTE DESKTOP**
- VNC Server starten
- Remote-Zugriff
- Einfacher zu debuggen

---

## 📝 NÄCHSTE SCHRITTE

1. **Diagnose durchführen:**
   - Logs sammeln
   - Fehler identifizieren
   - Root Cause finden

2. **Minimale Lösung testen:**
   - Nur X Server
   - Kein Chromium
   - Stabile Basis schaffen

3. **Schrittweise erweitern:**
   - Chromium hinzufügen
   - Touchscreen konfigurieren
   - Service optimieren

---

## ⚠️ WICHTIGE FRAGEN

1. **Was genau blinkt?**
   - Schwarzer Bildschirm?
   - Chromium startet und crasht?
   - X Server startet nicht?

2. **Wann blinkt es?**
   - Beim Boot?
   - Nach Service-Start?
   - Kontinuierlich?

3. **Was funktioniert?**
   - X Server läuft?
   - Chromium startet?
   - Display erkannt?

---

**Status:** ⏸️ Planungsmodus - Warte auf weitere Anweisungen

