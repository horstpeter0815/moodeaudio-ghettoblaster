# QUICK-FIX CHECKLIST - DATEI WIRD ÜBERSCHRIEBEN

**Wenn eine Datei beim Build überschrieben wird:**

## ⚡ SOFORT-CHECKS (5 Minuten)

### **1. Export-Image Scripts prüfen**
```bash
cd imgbuild/pi-gen-64
cat export-image/prerun.sh | grep -A 5 -B 5 "rsync\|cp\|mv"
```
**→ Wenn hier rsync ohne --exclude: GEFUNDEN!**

### **2. Alle rsync-Befehle finden**
```bash
grep -r "rsync" --include="*.sh" imgbuild/pi-gen-64/export-image/
```
**→ Jeden rsync-Befehl prüfen!**

### **3. Prerun-Scripts prüfen**
```bash
find imgbuild/pi-gen-64 -name "prerun.sh" -exec grep -l "rsync\|cp\|mv" {} \;
```
**→ Diese laufen ZUERST und können alles überschreiben!**

---

## 🔍 VOLLSTÄNDIGE SUCHE (15 Minuten)

### **Schritt 1: Alle Kopier-Operationen**
```bash
cd imgbuild/pi-gen-64
find . -type f -name "*.sh" -exec grep -l "rsync\|cp.*config\|mv.*config" {} \;
```

### **Schritt 2: Export-Image analysieren**
```bash
cat export-image/prerun.sh
cat export-image/05-finalise/01-run.sh
```

### **Schritt 3: Build-Ablauf verstehen**
```bash
grep -n "run_stage\|EXPORT" build.sh | head -20
```

---

## ✅ FIX-STRATEGIE

1. **Finde die Kopier-Operation**
2. **Füge --exclude hinzu** (bei rsync)
3. **ODER kopiere danach die richtige Datei**
4. **Teste den Fix**

---

## 🎯 DIE 3 KRITISCHEN STELLEN

1. **export-image/prerun.sh** - Kopiert ALLES mit rsync
2. **stage1/00-boot-files/00-run.sh** - Installiert Standard-Dateien
3. **export-image/05-finalise/01-run.sh** - Finalisiert das Image

**IMMER diese 3 prüfen!**

