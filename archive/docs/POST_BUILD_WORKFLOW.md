# 📋 POST-BUILD WORKFLOW - PI 5

**Datum:** 2025-12-09  
**Zweck:** Systematischer Workflow nach Build-Abschluss

---

## 🔄 WORKFLOW-REIHENFOLGE

### **1. BUILD PRÜFEN** ✅

**Prüfe Build-Status:**
```bash
cd imgbuild
tail -50 build-*.log
```

**Prüfe Image:**
```bash
ls -lh deploy/*.img
```

**Erwartet:**
- ✅ Build erfolgreich (keine Fehler)
- ✅ Image vorhanden (~5GB)
- ✅ Image-Name: `moode-r1001-arm64-build-XX-*.img`

---

### **2. TEST-SUITE AUSFÜHREN** ✅

**Führe Tests aus:**
```bash
cd ..
./complete_test_suite.sh
```

**Prüfe Ergebnisse:**
- ✅ Alle Services vorhanden?
- ✅ Alle Scripts vorhanden?
- ✅ Config.txt korrekt?
- ✅ Device Tree Overlays korrekt?

**Wenn Tests fehlschlagen:**
- ❌ **STOPP** - Nicht auf SD-Karte brennen!
- ❌ Analysiere Fehler
- ❌ Fixe Probleme
- ❌ Baue neu

---

### **3. SERIAL CONSOLE MONITORING VORBEREITEN** ✅

**Prüfe Serial Port:**
```bash
ls -la /dev/cu.usbmodem* 2>/dev/null || echo "Kein Serial Port gefunden"
```

**Starte Monitoring (wenn Port verfügbar):**
```bash
./AUTONOMOUS_SERIAL_MONITOR.sh
```

**Oder manuell:**
```bash
screen /dev/cu.usbmodem214302 115200
```

**Wichtig:**
- Serial Console zeigt Boot-Prozess
- Kann Boot-Probleme identifizieren
- **MUSS** vor SD-Karte-Brennen bereit sein!

---

### **4. DEBUGGER-OPTIONEN VORBEREITEN** ✅

**SSH-Verbindung testen (nach Boot):**
```bash
ping 192.168.178.143
ssh andre@192.168.178.143
# Password: 0815
```

**Debug-Tools installieren (wenn SSH funktioniert):**
```bash
./SETUP_PI_DEBUGGER.sh 192.168.178.143 andre
```

**Debugger verwenden:**
- GDB für Services
- strace für System-Calls
- journalctl für Logs

**Wichtig:**
- Debugger hilft bei Boot-Problemen
- **MUSS** vor SD-Karte-Brennen bereit sein!

---

### **5. NUR WENN WIRKLICH SICHER: SD-KARTE BRENNEN** ⚠️

**Checkliste VOR SD-Karte-Brennen:**

- [ ] ✅ Build erfolgreich abgeschlossen
- [ ] ✅ Tests bestanden (keine kritischen Fehler)
- [ ] ✅ Serial Console Monitoring bereit
- [ ] ✅ Debugger-Optionen bereit
- [ ] ✅ Image validiert (Größe, Format)
- [ ] ✅ Backup von aktueller SD-Karte (falls vorhanden)

**SD-Karte brennen:**
```bash
./BURN_IMAGE_TO_SD.sh
```

**Nach dem Brennen:**
1. ⏳ SD-Karte in Pi einstecken
2. ⏳ Serial Console Monitoring starten
3. ⏳ Pi booten lassen
4. ⏳ Boot-Prozess überwachen
5. ⏳ Bei Problemen: Debugger verwenden

---

## ⚠️ WICHTIG - BOOT-PROBLEME VON GESTERN

**Erinnerung:**
- Pi hängt beim Boot (über 1 Stunde)
- Serial Console **MUSS** überwacht werden
- Debugger **MUSS** bereit sein
- **NICHT** sofort auf SD-Karte brennen ohne Tests!

**Workflow:**
1. Build ✅
2. Tests ✅
3. Serial Console ✅
4. Debugger ✅
5. **DANN** SD-Karte ⚠️

---

## 🎯 ERWARTETES ERGEBNIS

**Nach erfolgreichem Boot:**
- ✅ SSH funktioniert (andre@GhettoBlaster.local)
- ✅ Web-UI erreichbar (http://GhettoBlaster.local)
- ✅ Display zeigt Chromium im Kiosk-Mode
- ✅ Audio: HiFiBerry AMP100 konfiguriert
- ✅ Touchscreen: FT6236 funktioniert

---

**Status:** ⏳ **WARTE AUF BUILD-ABSCHLUSS**

