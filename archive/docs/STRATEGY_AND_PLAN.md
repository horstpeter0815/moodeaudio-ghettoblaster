# Strategie und Plan - Waveshare 7.9" DSI LCD

**Datum:** 2025-11-25 20:15  
**Status:** Systematische Problemlösung

---

## Aktueller Status

### Was funktioniert:
- ✅ Panel wird erkannt (`10-0045` auf I2C Bus 10)
- ✅ Driver lädt (`panel-waveshare-dsi`)
- ✅ vc4 initialisiert (`Initialized vc4 0.0.0`)
- ✅ Config nach Waveshare Support angepasst

### Was NICHT funktioniert:
- ❌ DSI-1 wird nicht erkannt (kein `card1-DSI-1`)
- ❌ Kein Framebuffer (`/dev/fb0` existiert nicht)
- ❌ I2C-Fehler: `-5` (EIO) - Bus aktiv, Panel antwortet nicht
- ❌ LED blinkt → Panel wartet auf DSI-Daten

### Root Cause:
**Mit echtem KMS (`vc4-kms-v3d`) wird DSI-1 nicht erkannt!**

---

## Meine Strategie (Nächste Stunden)

### Phase 1: Hardware-Konfiguration klären (JETZT)

**Was ich brauche:**
1. **DIP-Switch Position:** I2C0 oder I2C1? (Du sagtest I2C1)
2. **4-Pin Connector:** Verbunden? (Ja, Pin 2,3,5,6)
3. **DSI-Kabel:** Welches DSI-Interface? (DSI0 oder DSI1?)

**Aktuelle Config:**
- `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,dsi0` (für DSI0)
- Aber: DIP-Switches auf I2C1, 4-Pin Connector verbunden

**Entscheidung nötig:**
- **Option A:** Bei DSI1 bleiben + `i2c1` Parameter (GPIO I2C)
- **Option B:** Zu DSI0 wechseln + DIP-Switches umstellen (DSI-I2C)

**Meine Empfehlung:** Option A (DSI1 + i2c1) weil Hardware bereits so konfiguriert ist.

---

### Phase 2: Config finalisieren (nach deiner Entscheidung)

**Was ich mache:**
1. Config anpassen basierend auf deiner Hardware-Entscheidung
2. Alle Settings nach Waveshare Support Config setzen
3. Test-Config erstellen

**Config sollte sein:**
```
[all]
dtoverlay=vc4-kms-v3d
display_auto_detect=1
disable_fw_kms_setup=1
hdmi_force_hotplug=1
dtparam=audio=on
...
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c1  # ODER dsi0
```

---

### Phase 3: Systematisches Testen (nach Config-Änderung)

**Test-Plan:**
1. **Boot-Test:** System bootet ohne Crash?
2. **DSI-Erkennung:** Wird DSI-1 oder DSI-0 erkannt?
3. **CRTC-Check:** Wird CRTC erstellt? (keine "Bogus possible_crtcs" Fehler)
4. **Framebuffer:** Wird `/dev/fb0` erstellt?
5. **I2C-Status:** I2C-Fehler reduziert?
6. **LED-Status:** Blinkt LED noch oder leuchtet stabil?
7. **Display:** Zeigt Display etwas?

**Test-Commands vorbereitet:**
```bash
# DSI-Status
ls -la /sys/class/drm/ | grep DSI
cat /sys/class/drm/card1-DSI-1/status 2>&1

# CRTC-Check
dmesg | grep -E 'Bogus|possible_crtc|No compatible format'

# Framebuffer
ls -la /dev/fb*

# I2C-Status
dmesg | grep -E 'i2c write|panel-waveshare' | tail -10

# Panel-Device
ls -la /sys/bus/i2c/devices/ | grep 0045
```

---

### Phase 4: Problem-Analyse (wenn Tests fehlschlagen)

**Wenn DSI nicht erkannt wird:**
1. Prüfe ob Overlay geladen wird: `dmesg | grep waveshare`
2. Prüfe vc4-Status: `lsmod | grep vc4`
3. Prüfe Device Tree: `ls /proc/device-tree/ | grep dsi`
4. Analysiere dmesg für Fehler

**Wenn CRTC fehlt:**
1. Prüfe ob fkms vs. echtes KMS Problem
2. Recherchiere fkms DSI-Support
3. Prüfe ob Overlay CRTC definiert

**Wenn I2C weiterhin fehlschlägt:**
1. Prüfe Hardware-Verbindung
2. Teste I2C-Bus direkt: `i2cdetect -y 1`
3. Prüfe DIP-Switch-Position
4. Analysiere I2C-Fehler-Typ (-5 vs -110)

---

### Phase 5: Alternative Lösungen (wenn Standard nicht funktioniert)

**Optionen:**
1. **Waveshare Installation Script:** `WS_xinchDSI_MAIN.sh` verwenden
2. **Custom Overlay:** Overlay patchen für fkms-Kompatibilität
3. **Firmware-Version:** Spezifische Firmware-Version testen
4. **Kernel-Module:** Driver manuell laden/konfigurieren

---

## Was ich BRAUCHE von dir

### JETZT (vor nächstem Test):
1. **Hardware-Entscheidung:**
   - DSI1 + i2c1 (GPIO I2C) → DIP-Switches bleiben auf I2C1
   - ODER DSI0 + dsi0 (DSI-I2C) → DIP-Switches auf I2C0 umstellen

2. **LED-Status nach Boot:**
   - Blinkt noch?
   - Oder leuchtet stabil?

3. **Display-Status:**
   - Zeigt irgendwas? (Licht, Farbe, Text)
   - Oder komplett dunkel?

### Nach jedem Test:
- **LED-Status:** Blinkt oder stabil?
- **Display:** Zeigt etwas?
- **System:** Bootet ohne Crash?

---

## Meine Arbeitsweise

### Strukturiert:
1. **Plan erstellen** (dieses Dokument)
2. **Config anpassen** basierend auf Plan
3. **Test durchführen** mit vorbereiteten Commands
4. **Ergebnisse analysieren** systematisch
5. **Nächsten Schritt planen** basierend auf Ergebnissen

### NICHT chaotisch:
- Ich reagiere nicht nur auf deine Anweisungen
- Ich habe einen Plan und folge ihm
- Ich dokumentiere alles
- Ich teste systematisch

---

## Nächste Schritte (in Reihenfolge)

1. **DU:** Hardware-Entscheidung (DSI1+i2c1 oder DSI0+dsi0)
2. **ICH:** Config entsprechend anpassen
3. **ICH:** Reboot und Tests durchführen
4. **DU:** LED/Display-Status melden
5. **ICH:** Ergebnisse analysieren
6. **ICH:** Nächsten Schritt planen

---

## Dokumentation

**Alle Findings werden dokumentiert in:**
- `CONFIG_COMPARISON.md` - Config-Vergleiche
- `CRTC_PROBLEM_ANALYSIS.md` - CRTC-Problem-Analyse
- `TONIGHT_RESEARCH_FINDINGS.md` - Recherche-Ergebnisse
- `STRATEGY_AND_PLAN.md` - Dieser Plan

---

**Status:** Warte auf deine Hardware-Entscheidung, dann setze ich Plan um.

