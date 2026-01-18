# SETUPPIGEN.SH ANALYSE

**Datei:** `imgbuild/pi-gen-utils/setuppigen.sh`  
**Zweck:** Kopiert Dateien von `moode-cfg/` nach `pi-gen-64/` vor dem Build

---

## 🔍 WAS ES TUT

### **1. Dateinamen-Konvertierung:**
- `moode-cfg/` verwendet `_` statt `/` in Dateinamen
- Beispiel: `stage3_03-ghettoblaster-custom_00-run.sh` → `stage3/03-ghettoblaster-custom/00-run.sh`

### **2. Backup-Erstellung:**
- Erstellt Backups in `moode-cfg/bak/` vor dem Überschreiben
- Original-Dateien werden gesichert

### **3. Dateien kopieren:**
- Kopiert alle `stage*` und `export*` Dateien von `moode-cfg/` nach `pi-gen-64/`
- Kopiert `config` nach `pi-gen-64/config`

---

## 📋 WIRD AUFGERUFEN VON

**`imgbuild/build.sh` Zeile 89:**
```bash
cd "$PI_GEN_CONFIG_DIR"  # moode-cfg/
rm -rf "$PI_GEN/stage3/00-install-packages" || true
"$PI_GEN_UTILS/setuppigen.sh" "$PI_GEN"  # Kopiert Dateien
```

---

## ✅ BETRIFFT config.txt?

**NEIN - setuppigen.sh betrifft config.txt NICHT direkt!**

**Was es tut:**
- Kopiert Scripts von `moode-cfg/` nach `pi-gen-64/`
- Diese Scripts kopieren dann später `config.txt.overwrite` → `config.txt`

**Relevante Dateien in moode-cfg/:**
- `stage3_03-ghettoblaster-custom_00-run.sh` - Kopiert config.txt.overwrite
- `stage3_03-ghettoblaster-custom_00-deploy.sh` - Kopiert config.txt.overwrite

**→ setuppigen.sh ist nur ein "Kopier-Script", keine config.txt-Operation!**

---

## 🔄 WORKFLOW

1. **build.sh** ruft `setuppigen.sh` auf
2. **setuppigen.sh** kopiert Scripts von `moode-cfg/` → `pi-gen-64/`
3. **pi-gen build.sh** führt die kopierten Scripts aus
4. Diese Scripts kopieren dann `config.txt.overwrite` → `config.txt`

---

## 📊 ZUSAMMENFASSUNG

**setuppigen.sh:**
- ✅ Kopiert Scripts (nicht config.txt direkt)
- ✅ Erstellt Backups
- ✅ Konvertiert Dateinamen (`_` → `/`)
- ❌ Betrifft config.txt NICHT direkt

**config.txt wird kopiert von:**
- `stage3/03-ghettoblaster-custom/00-run.sh` (kopiert von setuppigen.sh)
- `stage3/03-ghettoblaster-custom/00-deploy.sh` (kopiert von setuppigen.sh)
- `export-image/prerun.sh` (bereits in pi-gen-64, nicht von setuppigen.sh)

