# Display Comparison Test - Anleitung

**Datum:** 2025-11-25  
**Zweck:** Vergleich zwischen 7.9" Display und anderem Waveshare Display

---

## Aktuelle Konfiguration (7.9" Display)

**Config.txt:**
```
dtoverlay=vc4-fkms-v3d
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,i2c1
```

**Cmdline.txt:**
```
console=serial0,115200 console=tty1 root=PARTUUID=06127ec8-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE
```

---

## Vorgehen

### Schritt 1: Aktuellen Status dokumentieren (7.9" Display)

**Tests durchführen:**
```bash
/tmp/test_display_comparison.sh > /tmp/test_results_7.9inch.txt
```

**Oder manuell:**
- DSI-1 Status prüfen
- CRTC-Fehler zählen
- Framebuffer prüfen
- I2C-Status prüfen
- LED-Status notieren

---

### Schritt 2: Pi herunterfahren

```bash
sudo shutdown -h now
```

---

### Schritt 3: Display wechseln

1. **7.9" Display abziehen:**
   - DSI-Kabel entfernen
   - 4-Pin Connector entfernen
   - Power abziehen

2. **Anderes Waveshare Display anschließen:**
   - DSI-Kabel verbinden
   - 4-Pin Connector verbinden (falls vorhanden)
   - Power anschließen

3. **DIP-Switches prüfen:**
   - Welche Position? (I2C0 oder I2C1?)
   - Falls anders als I2C1: Config anpassen!

---

### Schritt 4: Pi booten

**Nach Boot:**
- Warte bis System vollständig gebootet ist
- Prüfe LED-Status
- Prüfe Display-Status

---

### Schritt 5: Tests durchführen (anderes Display)

**Test-Script ausführen:**
```bash
/tmp/test_display_comparison.sh > /tmp/test_results_other_display.txt
```

**Oder manuell die gleichen Tests wie vorher.**

---

### Schritt 6: Ergebnisse vergleichen

**Vergleiche:**
- Werden die GLEICHEN Fehler angezeigt?
- Wird DSI-1 erkannt?
- Gibt es CRTC-Fehler?
- Funktioniert I2C?
- LED-Status gleich?

**Wenn GLEICHE Fehler:**
→ **Konfigurations-Problem**, nicht Hardware-Defekt

**Wenn ANDERE/KEINE Fehler:**
→ **Hardware-Problem** mit 7.9" Display

---

## Wichtige Fragen

1. **Welches andere Display?** (Modell, Größe)
2. **DIP-Switches Position?** (I2C0 oder I2C1?)
3. **4-Pin Connector vorhanden?** (oder nur DSI-Kabel?)
4. **Config anpassen nötig?** (Display-Größe, DSI-Interface)

---

## Test-Script

**Location:** `/tmp/test_display_comparison.sh`

**Ausführen:**
```bash
bash /tmp/test_display_comparison.sh
```

**Output speichern:**
```bash
bash /tmp/test_display_comparison.sh > test_results.txt
```

---

## Nach dem Test

**Wenn du zurückkommst:**
1. Test-Ergebnisse mitteilen
2. LED-Status melden
3. Display-Status melden
4. Welches Display getestet wurde

**Dann analysiere ich die Ergebnisse und plane nächste Schritte.**

