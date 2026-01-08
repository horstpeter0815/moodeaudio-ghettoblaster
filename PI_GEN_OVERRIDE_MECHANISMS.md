# pi-gen Override Mechanisms - Complete Documentation

**Date:** 2025-12-25  
**Purpose:** Dokumentation aller Override-Mechanismen in pi-gen die config.txt und andere Konfigurationen schützen

---

## 🔍 ALLE OVERRIDE-MECHANISMEN

### 1. **stage1/00-boot-files/00-run.sh** (BUILD TIME - Stage 1)

**Datei:** `imgbuild/pi-gen-64/stage1/00-boot-files/00-run.sh`

**Mechanismus:**
```bash
# PERMANENT FIX: Use config.txt.overwrite instead of default config.txt
MOODE_SOURCE="${MOODE_SOURCE:-/workspace/moode-source}"
if [ -f "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" ]; then
	install -m 644 "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" "${ROOTFS_DIR}/boot/firmware/config.txt"
	echo "✅ config.txt.overwrite used instead of default config.txt"
else
	# Fallback to default if overwrite not found
	install -m 644 files/config.txt "${ROOTFS_DIR}/boot/firmware/"
	echo "⚠️  config.txt.overwrite not found, using default config.txt"
fi
```

**Was passiert:**
- Prüft ob `config.txt.overwrite` existiert
- Wenn ja: Verwendet `config.txt.overwrite` statt Standard `config.txt`
- Wenn nein: Fallback auf Standard `config.txt`

**Timing:** Stage 1 - sehr früh im Build-Prozess

**Status:** ✅ Aktiv im Custom-Build

---

### 2. **stage3/03-ghettoblaster-custom/00-run.sh** (BUILD TIME - Stage 3)

**Datei:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run.sh`

**Mechanismus:**
```bash
# Copy config.txt.overwrite to boot partition AND REPLACE config.txt
if [ -f "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" ]; then
    mkdir -p "$ROOTFS/boot/firmware"
    # PERMANENT FIX: Replace config.txt with config.txt.overwrite (not just copy)
    cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/config.txt" || true
    echo "✅ config.txt.overwrite copied and REPLACED config.txt"
else
    echo "⚠️  config.txt.overwrite not found in moode-source"
fi
```

**Was passiert:**
- Kopiert `config.txt.overwrite` → `config.txt` (ERSETZT!)
- Überschreibt alles was in Stage 1 installiert wurde

**Timing:** Stage 3 - nach moOde Installation

**Status:** ✅ Aktiv im Custom-Build

---

### 3. **export-image/prerun.sh** (BUILD TIME - Export Phase)

**Datei:** `imgbuild/pi-gen-64/export-image/prerun.sh`

**Mechanismus:**
```bash
# Optimized rsync with progress and parallel transfers
rsync -aHAXx --exclude /var/cache/apt/archives --exclude /boot/firmware --info=progress2 "${EXPORT_ROOTFS_DIR}/" "${ROOTFS_DIR}/"
rsync -rtx --exclude config.txt --info=progress2 "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"

# PERMANENT FIX: Ensure custom config.txt.overwrite replaces config.txt AFTER rsync
# This prevents the default config.txt from stage1 from overwriting our custom config.txt
MOODE_SOURCE="${MOODE_SOURCE:-/workspace/moode-source}"
if [ -f "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" ]; then
	cp "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" "${ROOTFS_DIR}/boot/firmware/config.txt" || true
	echo "✅ config.txt.overwrite copied and REPLACED config.txt in export-image/prerun.sh"
else
	echo "⚠️  config.txt.overwrite not found at ${MOODE_SOURCE}/boot/firmware/config.txt.overwrite"
	# Fallback: Check if it's already in EXPORT_ROOTFS_DIR
	if [ -f "${EXPORT_ROOTFS_DIR}/boot/firmware/config.txt.overwrite" ]; then
		cp "${EXPORT_ROOTFS_DIR}/boot/firmware/config.txt.overwrite" "${ROOTFS_DIR}/boot/firmware/config.txt" || true
		echo "✅ Using config.txt.overwrite from EXPORT_ROOTFS_DIR"
	fi
fi
```

**Was passiert:**
1. rsync kopiert alles AUSSER `config.txt` (`--exclude config.txt`)
2. Danach: Explizite Kopie von `config.txt.overwrite` → `config.txt`
3. Verhindert dass rsync die Standard config.txt überschreibt

**Timing:** Export-Phase - ganz am Ende, direkt vor Image-Erstellung

**Status:** ✅ Aktiv im Custom-Build

---

### 4. **stage3/03-ghettoblaster-custom/00-deploy.sh** (BUILD TIME - Deploy Phase)

**Datei:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-deploy.sh`

**Mechanismus:**
```bash
# Copy config.txt.overwrite to boot partition AND REPLACE config.txt
if [ -f "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" ]; then
    mkdir -p "${ROOTFS}/boot/firmware"
    # PERMANENT FIX: Replace config.txt with config.txt.overwrite (not just copy)
    cp "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" "${ROOTFS}/boot/firmware/config.txt" || true
    echo "✅ config.txt.overwrite copied and REPLACED config.txt"
fi
```

**Was passiert:**
- Zusätzliche Sicherheitsschicht
- Ersetzt config.txt nochmal in Deploy-Phase

**Timing:** Deploy-Phase - nach Stage 3

**Status:** ✅ Aktiv im Custom-Build

---

## 📊 OVERRIDE SEQUENZ (Build Order)

```
1. stage1/00-boot-files/00-run.sh
   └─> Verwendet config.txt.overwrite statt Standard config.txt
   
2. stage3/03-ghettoblaster-custom/00-run.sh
   └─> Ersetzt config.txt mit config.txt.overwrite (nochmal)
   
3. stage3/03-ghettoblaster-custom/00-deploy.sh
   └─> Ersetzt config.txt mit config.txt.overwrite (nochmal)
   
4. export-image/prerun.sh
   └─> rsync --exclude config.txt
   └─> Dann: config.txt.overwrite → config.txt (final)
```

**Ergebnis:** `config.txt.overwrite` wird an 4 Stellen verwendet/ersetzt!

---

## ⚠️ WICHTIG: config.txt.overwrite Struktur

**Datei:** `moode-source/boot/firmware/config.txt.overwrite`

**KRITISCH:** Header muss in Zeile 2 sein!

```bash
# Zeile 1: Leer ODER Kommentar
# Zeile 2: # This file is managed by moOde  ← MUSS HIER SEIN!
#########################################
# Ghettoblaster Custom Build
```

**Warum:**
- `worker.php` prüft `$lines[1]` (Zeile 2) für Main Header
- Wenn Header nicht in Zeile 2 → wird nicht erkannt → Overwrite!

---

## 🔒 SCHUTZ VOR RUNTIME OVERWRITE

### worker.php Overwrite (RUNTIME)

**Problem:** worker.php kann config.txt beim Boot überschreiben

**Lösung:** config.txt.overwrite muss moOde Headers haben!

**Header-Struktur die erkannt wird:**
```
Zeile 1: (leer oder Kommentar)
Zeile 2: # This file is managed by moOde  ← Main Header
Zeile 3: #########################################
Zeile 4: # Device filters
Zeile 5: [cm4]
...
Zeile X: # General settings
Zeile Y: [all]
...
Zeile Z: # Do not alter this section
...
Zeile A: # Integrated adapters
...
Zeile B: # Audio overlays
...
```

**Alle 5 Header müssen vorhanden sein:**
1. Main Header (Zeile 2)
2. Device filters
3. General settings
4. Do not alter this section
5. Integrated adapters
6. Audio overlays

---

## 📋 ZUSAMMENFASSUNG

### ✅ Was funktioniert (Custom-Build):

1. **Stage 1:** Verwendet config.txt.overwrite statt Standard
2. **Stage 3:** Ersetzt config.txt mit config.txt.overwrite
3. **Deploy:** Ersetzt nochmal (Sicherheit)
4. **Export:** rsync schließt config.txt aus, dann explizite Kopie

### ⚠️ Was NICHT funktioniert (Standard moOde Image):

- **Keine Override-Mechanismen!**
- Standard config.txt wird verwendet
- Keine config.txt.overwrite
- worker.php kann beim Boot überschreiben

### 🎯 Für Standard moOde Image:

**Option 1:** config.txt.overwrite manuell auf SD-Karte kopieren
```bash
cp config.txt.overwrite /Volumes/bootfs/config.txt
```

**Option 2:** moOde Headers zu Standard config.txt hinzufügen
```bash
# Füge Header in Zeile 2 hinzu
sed -i '2i\
# This file is managed by moOde\
' /Volumes/bootfs/config.txt
```

---

## 🔍 PRÜFUNG: Welche Overrides sind aktiv?

### Auf dem aktuellen Pi (Standard moOde Image):

**Status:**
- ✅ config.txt hat moOde Headers (Zeile 2: "# This file is managed by moOde")
- ✅ worker.php erkennt Headers → kein Overwrite
- ✅ Backup erstellt: `/boot/firmware/config.txt.working-backup`
- ✅ Restore-Service aktiviert
- ❌ Keine pi-gen Overrides (Standard Image, kein Custom-Build)

**config.txt Struktur:**
```
Zeile 1: #########################################
Zeile 2: # This file is managed by moOde  ← Header korrekt!
Zeile 3: #########################################
```

**worker.php Status:**
- Prüft `chkBootConfigTxt()` → gibt "Required headers present" zurück
- Kein Overwrite nötig

### Im Custom-Build:

**Status:**
- ✅ Alle 4 Override-Mechanismen aktiv
- ✅ config.txt.overwrite wird verwendet (4x im Build-Prozess)
- ✅ rsync schließt config.txt aus (`--exclude config.txt`)
- ✅ config.txt.overwrite hat Header in Zeile 2 (korrekt!)

**Override-Sequenz:**
1. Stage 1: Verwendet config.txt.overwrite statt Standard
2. Stage 3: Ersetzt nochmal
3. Deploy: Ersetzt nochmal (Sicherheit)
4. Export: rsync schließt aus, dann explizite Kopie

---

## 🎯 ANWENDUNG AUF STANDARD MOODE IMAGE

**Script erstellt:** `APPLY_PI_GEN_OVERRIDES_TO_SD.sh`

**Was es tut:**
- Wendet config.txt.overwrite an (wie pi-gen Stage 1)
- Erstellt Backup
- Verifiziert moOde Headers

**Ausführung:**
```bash
sudo ./APPLY_PI_GEN_OVERRIDES_TO_SD.sh
```

**Ergebnis:**
- config.txt wird durch config.txt.overwrite ersetzt
- Hat alle moOde Headers (verhindert worker.php Overwrite)
- Hat Custom Settings (Display-Rotation, etc.)

