# KRITISCHE FUNDE - LEKTION FÜR ZUKUNFTIGE ANALYSEN

**Datum:** 2025-12-21  
**Problem:** config.txt wird beim Build überschrieben  
**Zeitverlust:** 1 ganzer Tag  
**Ursache:** `export-image/prerun.sh` rsync überschreibt config.txt

---

## 🎯 DAS PROBLEM

**Symptom:** config.txt wird nach jedem Build zurückgesetzt  
**Root Cause:** `export-image/prerun.sh` Zeile 72-73 kopiert ALLES mit rsync, inklusive boot/firmware/config.txt

---

## ✅ WAS ICH HÄTTE SOFORT TUN SOLLEN

### **1. SYSTEMATISCHE SUCHE NACH ALLEN KOPIER-OPERATIONEN**

**Bei jedem Problem mit überschriebenen Dateien:**

```bash
# 1. Suche ALLE rsync, cp, mv, install Befehle
find . -type f -name "*.sh" -exec grep -l "rsync\|cp.*config\|mv.*config\|install.*config" {} \;

# 2. Suche ALLE Stellen, die boot/firmware betreffen
find . -type f -name "*.sh" -exec grep -l "boot/firmware\|boot.*firmware" {} \;

# 3. Suche ALLE export-image Scripts (KRITISCH!)
find . -path "*/export-image/*" -name "*.sh"

# 4. Prüfe ALLE prerun.sh Scripts (laufen VOR den Stages!)
find . -name "prerun.sh"
```

### **2. EXPORT-IMAGE STAGE IMMER ZUERST PRÜFEN**

**Warum:** Export-Image läuft NACH allen Stages und kann alles überschreiben!

**Kritische Dateien:**
- `export-image/prerun.sh` - **KRITISCH!** Kopiert alles mit rsync
- `export-image/05-finalise/01-run.sh` - Finalisiert das Image
- Alle anderen export-image Scripts

**Checkliste:**
- [ ] `export-image/prerun.sh` gelesen?
- [ ] rsync-Befehle geprüft?
- [ ] Werden Dateien von EXPORT_ROOTFS_DIR kopiert?
- [ ] Werden boot/firmware Dateien kopiert?
- [ ] Gibt es --exclude für kritische Dateien?

### **3. BUILD-PROZESS VERSTEHEN**

**Reihenfolge:**
1. **Stages 0-5:** Bauen das System auf
2. **export-image/prerun.sh:** Kopiert ALLES von EXPORT_ROOTFS_DIR nach neuem ROOTFS_DIR
3. **export-image/05-finalise:** Finalisiert das Image

**Kritisch:** Was in Stage 3 kopiert wird, kann in export-image/prerun.sh überschrieben werden!

---

## 🔍 DIE RICHTIGE SUCHSTRATEGIE

### **Schritt 1: Alle Kopier-Operationen finden**
```bash
grep -r "rsync\|cp.*config\|mv.*config\|install.*config" --include="*.sh" .
```

### **Schritt 2: Export-Image Scripts prüfen**
```bash
find . -path "*/export-image/*" -name "*.sh" -exec cat {} \;
```

### **Schritt 3: Prerun-Scripts prüfen (laufen ZUERST!)**
```bash
find . -name "prerun.sh" -exec cat {} \;
```

### **Schritt 4: Build-Ablauf verstehen**
```bash
# Welche Stages gibt es?
ls -d stage*/

# Welche export-Scripts gibt es?
ls -d export-*/

# In welcher Reihenfolge werden sie ausgeführt?
grep -r "run_stage\|EXPORT" build.sh
```

---

## 📋 CHECKLISTE FÜR ZUKÜNFTIGE PROBLEME

### **Wenn eine Datei überschrieben wird:**

- [ ] **1. Alle rsync-Befehle gefunden?**
  ```bash
  grep -r "rsync" --include="*.sh" .
  ```

- [ ] **2. Export-Image Scripts geprüft?**
  ```bash
  find . -path "*/export-image/*" -name "*.sh"
  ```

- [ ] **3. Prerun-Scripts geprüft?**
  ```bash
  find . -name "prerun.sh"
  ```

- [ ] **4. Build-Ablauf verstanden?**
  - Welche Stages gibt es?
  - In welcher Reihenfolge laufen sie?
  - Was passiert in export-image?

- [ ] **5. Alle Kopier-Operationen gefunden?**
  ```bash
  grep -r "cp\|mv\|install\|rsync" --include="*.sh" . | grep -i "config\|boot\|firmware"
  ```

- [ ] **6. Gibt es --exclude für kritische Dateien?**
  ```bash
  grep -r "rsync.*exclude" --include="*.sh" .
  ```

---

## 🎓 DIE LEKTION

**1. Systematisch suchen, nicht zufällig!**
- Nicht nur nach "config.txt" suchen
- Sondern nach ALLEN Kopier-Operationen
- Besonders rsync, cp, mv, install

**2. Export-Image IMMER zuerst prüfen!**
- Export-Image läuft NACH allen Stages
- Kann alles überschreiben, was vorher gemacht wurde
- prerun.sh ist besonders kritisch!

**3. Build-Ablauf verstehen!**
- Welche Reihenfolge?
- Was passiert wann?
- Wo kann etwas überschrieben werden?

**4. Vollständig suchen, nicht aufhören!**
- Nicht nach dem ersten Fund aufhören
- ALLE Scripts durchsuchen
- ALLE Kopier-Operationen finden

---

## ✅ DER FIX

**Problem:** `export-image/prerun.sh` Zeile 72-73:
```bash
rsync -rtx "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"
```

**Fix:**
```bash
rsync -rtx --exclude config.txt "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"
# Danach: config.txt.overwrite kopieren
```

---

## 🚨 WICHTIG FÜR ZUKUNFT

**Bei jedem Problem mit überschriebenen Dateien:**

1. **SOFORT:** Alle export-image Scripts prüfen
2. **SOFORT:** Alle rsync-Befehle finden
3. **SOFORT:** Build-Ablauf verstehen
4. **NIEMALS:** Nach dem ersten Fund aufhören
5. **IMMER:** Systematisch und vollständig suchen

**Zeit sparen = Systematisch suchen!**

