# PI-GEN DURCHSUCHUNG - ALLE FUNDE

## 🔴 KRITISCHER FUND: export-image/prerun.sh

**Datei:** `imgbuild/pi-gen-64/export-image/prerun.sh`  
**Zeile 72-73:**

```bash
rsync -aHAXx --exclude /var/cache/apt/archives --exclude /boot/firmware "${EXPORT_ROOTFS_DIR}/" "${ROOTFS_DIR}/"
rsync -rtx "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"
```

**Problem:**
- `rsync` kopiert ALLES von `EXPORT_ROOTFS_DIR` nach `ROOTFS_DIR`
- Das schließt `boot/firmware/` ein
- Wenn `EXPORT_ROOTFS_DIR/boot/firmware/config.txt` noch die Standard-`config.txt` von Stage 1 ist, wird unsere custom `config.txt` überschrieben!

**Fix angewendet:**
1. `rsync --exclude config.txt` - verhindert Überschreibung
2. Danach: `config.txt.overwrite` kopieren - ersetzt `config.txt` definitiv

---

## ✅ BEREITS GEFIXT:

### 1. stage1/00-boot-files/00-run.sh
- Installiert Standard `config.txt` in Stage 1
- **Status:** OK - wird später überschrieben

### 2. stage3/03-ghettoblaster-custom/00-run.sh
- Kopiert `config.txt.overwrite` → `config.txt`
- **Status:** ✅ FIXED - ersetzt config.txt

### 3. stage3/03-ghettoblaster-custom/00-deploy.sh
- Kopiert `config.txt.overwrite` → `config.txt`
- **Status:** ✅ FIXED - ersetzt config.txt

### 4. export-image/prerun.sh
- **KRITISCH:** rsync überschreibt config.txt
- **Status:** ✅ FIXED - exclude config.txt + danach kopieren

---

## 📋 ALLE SHELL-SCRIPTS DURCHSUCHT:

### Stage Scripts:
- ✅ `stage1/00-boot-files/00-run.sh` - installiert Standard config.txt
- ✅ `stage3/03-ghettoblaster-custom/00-run.sh` - kopiert config.txt.overwrite
- ✅ `stage3/03-ghettoblaster-custom/00-deploy.sh` - kopiert config.txt.overwrite

### Export Scripts:
- ✅ `export-image/prerun.sh` - **KRITISCH** - rsync überschreibt config.txt → **FIXED**
- ✅ `export-image/05-finalise/01-run.sh` - kopiert nur issue.txt, nicht config.txt

### Build Scripts:
- ✅ `build.sh` - ruft Stages auf
- ✅ `scripts/common` - keine config.txt Operationen

---

## 🎯 ZUSAMMENFASSUNG:

**Problem:** `export-image/prerun.sh` überschreibt `config.txt` mit Standard-Version  
**Fix:** `rsync --exclude config.txt` + danach `config.txt.overwrite` kopieren  
**Status:** ✅ FIXED

**BEIM NÄCHSTEN BUILD:** config.txt wird NICHT mehr überschrieben!

