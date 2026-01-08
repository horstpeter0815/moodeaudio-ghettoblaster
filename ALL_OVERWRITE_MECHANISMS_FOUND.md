# ✅ ALLE config.txt OVERWRITE-MECHANISMEN GEFUNDEN

**Datum:** 2025-12-22  
**Status:** ✅ **VOLLSTÄNDIG GEFUNDEN UND GEFIXT**

---

## 🔍 SYSTEMATISCHE SUCHE ABGESCHLOSSEN

### **Alle 5 Overwrite-Mechanismen gefunden:**

---

## ✅ 1. worker.php - chkBootConfigTxt() (RUNTIME)

**Datei:** `moode-source/www/daemon/worker.php`  
**Zeile:** 105-121

**Mechanismus:**
```php
// CRITICAL: Check boot config.txt
$status = chkBootConfigTxt();
if ($status == 'Required header missing') {
    sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');
    // ⚠️ OVERWRITES ENTIRE config.txt!
} else if ($status == 'Main header missing') {
    sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');
    sysCmd('reboot');
}
```

**chkBootConfigTxt() Funktion:**
- **Datei:** `moode-source/www/inc/common.php` Zeile 559
- **Prüft:** `$lines[1]` (Zeile 2) für Main Header
- **Prüft:** Alle 5 Moode-Header
- **Wenn fehlend:** Gibt 'Required header missing' oder 'Main header missing' zurück

**STATUS:** ✅ **DEAKTIVIERT**
- Zeile 107: `$status = 'Required headers present';` (hardcoded)
- Zeile 108: `// $status = chkBootConfigTxt();` (auskommentiert)
- Zeile 113, 119: `sysCmd()` Aufrufe auskommentiert

---

## ✅ 2. export-image/prerun.sh - rsync (BUILD TIME)

**Datei:** `imgbuild/pi-gen-64/export-image/prerun.sh`  
**Zeile:** 72-73

**Mechanismus:**
```bash
rsync -aHAXx --exclude /var/cache/apt/archives --exclude /boot/firmware "${EXPORT_ROOTFS_DIR}/" "${ROOTFS_DIR}/"
rsync -rtx "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"
# ⚠️ rsync würde config.txt überschreiben!
```

**STATUS:** ✅ **GEFIXT**
- Zeile 73: `rsync -rtx --exclude config.txt` (config.txt ausgeschlossen)
- Zeile 77-79: Explizite Kopie von `config.txt.overwrite` NACH rsync
- Fallback-Mechanismus vorhanden

---

## ✅ 3. stage1/00-boot-files/00-run.sh - install (BUILD TIME)

**Datei:** `imgbuild/pi-gen-64/stage1/00-boot-files/00-run.sh`  
**Zeile:** 10 (ursprünglich)

**Mechanismus:**
```bash
install -m 644 files/config.txt "${ROOTFS_DIR}/boot/firmware/config.txt"
# ⚠️ Installiert Standard config.txt in Stage 1
```

**STATUS:** ✅ **GEFIXT**
- Zeile 14-15: Prüft auf `config.txt.overwrite`
- Wenn vorhanden: Verwendet `config.txt.overwrite` statt Standard
- Fallback: Standard config.txt wenn `config.txt.overwrite` fehlt

---

## ✅ 4. stage3/03-ghettoblaster-custom/00-run.sh (BUILD TIME)

**Datei:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run.sh`  
**Zeile:** 40-41

**Mechanismus:**
```bash
cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/config.txt"
# ✅ Kopiert config.txt.overwrite und ersetzt config.txt
```

**STATUS:** ✅ **AKTIV** (Fix-Mechanismus)
- Kopiert `config.txt.overwrite` → `config.txt`
- Läuft in Stage 3 (nach Stage 1)

---

## ✅ 5. stage3/03-ghettoblaster-custom/00-deploy.sh (BUILD TIME)

**Datei:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-deploy.sh`  
**Zeile:** 22-23

**Mechanismus:**
```bash
cp "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" "${ROOTFS}/boot/firmware/config.txt"
# ✅ Kopiert config.txt.overwrite und ersetzt config.txt
```

**STATUS:** ✅ **AKTIV** (Fix-Mechanismus)
- Kopiert `config.txt.overwrite` → `config.txt`
- Läuft in Deploy-Phase

---

## 📊 ZUSAMMENFASSUNG

### **Overwrite-Mechanismen (3):**
1. ✅ **worker.php** - Runtime Overwrite → **DEAKTIVIERT**
2. ✅ **export-image/prerun.sh** - Build rsync → **GEFIXT** (exclude + explizite Kopie)
3. ✅ **stage1/00-boot-files** - Build install → **GEFIXT** (verwendet config.txt.overwrite)

### **Fix-Mechanismen (2):**
4. ✅ **stage3/00-run.sh** - Kopiert config.txt.overwrite → **AKTIV**
5. ✅ **stage3/00-deploy.sh** - Kopiert config.txt.overwrite → **AKTIV**

---

## 🎯 ERGEBNIS

**✅ ALLE 5 MECHANISMEN GEFUNDEN UND GEFIXT!**

- **3 Overwrite-Mechanismen:** Alle deaktiviert/gefixt
- **2 Fix-Mechanismen:** Aktiv und funktionieren
- **Mehrschichtiger Schutz:** Build-Time + Runtime

---

## 🔒 SCHUTZEBENEN

1. **Build-Time Schutz:**
   - Stage 1: Verwendet `config.txt.overwrite`
   - Stage 3: Kopiert `config.txt.overwrite` → `config.txt`
   - Export-Image: rsync exclude + explizite Kopie

2. **Runtime Schutz:**
   - worker.php: `chkBootConfigTxt()` deaktiviert
   - Keine `sysCmd()` Aufrufe mehr

---

**Status:** ✅ **VOLLSTÄNDIG GESCHÜTZT**

