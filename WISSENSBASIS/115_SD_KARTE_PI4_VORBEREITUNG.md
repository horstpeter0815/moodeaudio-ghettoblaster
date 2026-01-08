# SD-KARTE PI 4 VORBEREITUNG

**Datum:** 03.12.2025  
**Status:** ⏳ Warte auf gebrannte SD-Karte

---

## VORGANG

### **1. SD-Karte brennen (Benutzer):**
- ✅ Pi Imager verwenden
- ✅ moOde Audio für Pi 4 auswählen
- ✅ Auf SD-Karte brennen

### **2. SD-Karte prüfen & konfigurieren (Ich):**
- ⏳ Script: `check-and-configure-sd-pi4.sh`
- ⏳ Prüft SD-Karte
- ⏳ Konfiguriert für Pi 4
- ⏳ Display Rotation setzen
- ⏳ VC4 Overlay anpassen

---

## SCRIPT

**check-and-configure-sd-pi4.sh:**
- Prüft ob SD-Karte gemountet ist
- Erstellt Backup von config.txt
- Entfernt Pi 5 spezifische Overlays
- Fügt Pi 4 Konfiguration hinzu:
  - `display_rotate=3`
  - `dtoverlay=vc4-kms-v3d,audio=off`

---

## NACH DEM BRENNEN

**Ausführen:**
```bash
./check-and-configure-sd-pi4.sh
```

**Das Script:**
1. Wartet auf SD-Karte
2. Prüft System
3. Konfiguriert automatisch
4. Erstellt Backup

---

**Status:** ⏳ Warte auf gebrannte SD-Karte...

