# SD-KARTE PI 4 KONFIGURIERT

**Datum:** 03.12.2025  
**SD-Karte:** /dev/disk4  
**Status:** ✅ Konfiguriert für Pi 4

---

## DURCHGEFÜHRTE KONFIGURATION

### **Entfernt (Pi 5 spezifisch):**
- ❌ `dtoverlay=hifiberry-amp100-pi5` (entfernt)

### **Hinzugefügt:**
- ✅ `display_rotate=3` (Landscape 270°)

### **Bereits vorhanden:**
- ✅ `dtoverlay=vc4-kms-v3d` (Display)
- ✅ `dtoverlay=ft6236` (Touchscreen)
- ✅ `dtoverlay=dwc2,dr_mode=host` (USB)

---

## BACKUP

**Erstellt:** `config.txt.backup-20251203_020633`

---

## NÄCHSTE SCHRITTE

1. ✅ SD-Karte konfiguriert
2. ⏳ SD-Karte in Pi 4 einstecken
3. ⏳ Pi 4 booten
4. ⏳ System prüfen
5. ⏳ HiFiBerry Overlay anpassen (falls AMP100 verwendet wird)

---

## HINWEIS

**HiFiBerry AMP100 für Pi 4:**
- Falls AMP100 verwendet wird, muss Overlay angepasst werden:
- `dtoverlay=hifiberry-amp100` (ohne -pi5)
- Oder: `dtoverlay=hifiberry-amp100-pi4-dsp-reset` (falls verfügbar)

---

**Status:** ✅ Konfiguriert, bereit für Pi 4

