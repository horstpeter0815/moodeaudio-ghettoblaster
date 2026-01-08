# 🔍 PI-GEN BUILD SCRIPTS ANALYSE - config.txt Problem

**Datum:** 2025-12-21  
**Zweck:** Analyse der pi-gen Build-Scripts bezüglich config.txt Installation und Überschreibungsproblem

---

## 📋 BUILD SEQUENZ

### **Stage 1: Boot Files Installation**

**Datei:** `imgbuild/pi-gen-64/stage1/00-boot-files/00-run.sh`

**Code:**
```bash
install -m 644 files/config.txt "${ROOTFS_DIR}/boot/firmware/"
```

**Was passiert:**
- Standard Raspberry Pi `config.txt` wird installiert
- **KEINE moOde Headers!**
- Wird zur finalen `/boot/firmware/config.txt` im Image

**Inhalt der Standard config.txt:**
```
# For more options and information see
# http://rptl.io/configtxt
# Some settings may impact device functionality. See link above for details
...
```

**PROBLEM:** Keine moOde Headers vorhanden!

---

### **Stage 3: Custom Components**

**Dateien:**
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run.sh`
- `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-deploy.sh`

**Code:**
```bash
if [ -f "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" ]; then
    mkdir -p "$ROOTFS/boot/firmware"
    cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/" || true
    echo "✅ config.txt.overwrite copied to $ROOTFS/boot/firmware/"
fi
```

**Was passiert:**
- `config.txt.overwrite` wird kopiert nach `/boot/firmware/`
- **ABER:** Es wird NICHT verwendet!
- Die Standard `config.txt` bleibt aktiv!

**PROBLEM:** `config.txt.overwrite` wird ignoriert!

---

## 🔴 DAS PROBLEM

### **1. Standard config.txt hat keine Headers**

**Datei:** `imgbuild/pi-gen-64/stage1/00-boot-files/files/config.txt`

**Struktur:**
- Zeile 1: `# For more options and information see`
- Zeile 2: `# http://rptl.io/configtxt`
- **KEIN** `# This file is managed by moOde`
- **KEINE** der 5 erforderlichen Headers

**FOLGE:**
- Beim Boot prüft `worker.php` → Headers fehlen → **OVERWRITE!**

---

### **2. config.txt.overwrite wird nicht verwendet**

**Problem:**
- `config.txt.overwrite` wird nur kopiert, nicht ersetzt
- Es bleibt als separate Datei
- Die Standard `config.txt` bleibt aktiv
- **KEIN Script** ersetzt `config.txt` mit `config.txt.overwrite`

**FOLGE:**
- Custom Settings in `config.txt.overwrite` werden ignoriert
- Standard config.txt ohne Headers wird verwendet
- Beim Boot → Overwrite!

---

### **3. config.txt.overwrite hat Header in falscher Zeile**

**Datei:** `moode-source/boot/firmware/config.txt.overwrite`

**Struktur:**
```
Zeile 1: #########################################
Zeile 2: # Ghettoblaster Custom Build
Zeile 3: # This file is managed by moOde  ← Main Header in Zeile 3!
```

**PROBLEM:**
- Main Header ist in **Zeile 3**, nicht Zeile 2
- `chkBootConfigTxt()` prüft `$lines[1]` (Zeile 2)
- Zeile 2 ist `# Ghettoblaster Custom Build` → wird nicht erkannt!

**FOLGE:**
- Selbst wenn verwendet → Header würde nicht erkannt
- `worker.php` würde "Main header missing" zurückgeben → Overwrite + Reboot!

---

## ✅ LÖSUNGSANSÄTZE

### **Lösung 1: config.txt.overwrite → config.txt ersetzen**

**In:** `imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run.sh`

**Änderung:**
```bash
# Statt nur kopieren:
cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/"

# Ersetzen:
cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/config.txt"
```

**Vorteil:**
- Einfach, direkt
- Custom config.txt wird verwendet

**Nachteil:**
- Überschreibt Standard config.txt komplett
- Könnte wichtige Standard-Settings verlieren

---

### **Lösung 2: Header in Zeile 2 verschieben**

**In:** `moode-source/boot/firmware/config.txt.overwrite`

**Änderung:**
```
# This file is managed by moOde  ← Zeile 1 (oder leer lassen, dann Zeile 2)
# Ghettoblaster Custom Build
#########################################
```

**Vorteil:**
- Header wird von `chkBootConfigTxt()` erkannt
- Keine anderen Änderungen nötig

**Nachteil:**
- Erfordert Änderung an config.txt.overwrite
- Muss mit Lösung 1 kombiniert werden

---

### **Lösung 3: Standard config.txt mit Headers versehen**

**In:** `imgbuild/pi-gen-64/stage1/00-boot-files/files/config.txt`

**Änderung:**
```
# This file is managed by moOde  ← Zeile 1 (oder leer lassen, dann Zeile 2)

# Device filters
[pi5]
...

# General settings
[all]
...

# Do not alter this section
...

# Audio overlays
...
```

**Vorteil:**
- Standard config.txt hat Headers
- Keine Custom Scripts nötig
- Funktioniert für alle Builds

**Nachteil:**
- Ändert Standard pi-gen Template
- Könnte andere Projekte beeinflussen

---

### **Lösung 4: Post-Build Script**

**Neue Datei:** `imgbuild/pi-gen-64/export-image/06-custom-config/00-run.sh`

**Code:**
```bash
#!/bin/bash
if [ -f "${ROOTFS_DIR}/boot/firmware/config.txt.overwrite" ]; then
    cp "${ROOTFS_DIR}/boot/firmware/config.txt.overwrite" \
       "${ROOTFS_DIR}/boot/firmware/config.txt"
    echo "✅ Custom config.txt installed"
fi
```

**Vorteil:**
- Läuft nach allen Stages
- Überschreibt Standard config.txt am Ende
- Keine Änderungen an Standard Templates

**Nachteil:**
- Erfordert neue Stage/Export-Step
- Timing muss stimmen

---

## 🎯 EMPFOHLENE LÖSUNG

**Kombination aus Lösung 1 + 2:**

1. **config.txt.overwrite Header in Zeile 2 verschieben:**
   ```
   # This file is managed by moOde  ← Zeile 1 (oder leer)
   # Ghettoblaster Custom Build
   #########################################
   ```

2. **00-run.sh modifizieren, um config.txt zu ersetzen:**
   ```bash
   if [ -f "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" ]; then
       cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" \
          "$ROOTFS/boot/firmware/config.txt"
       echo "✅ Custom config.txt installed (replaced standard)"
   fi
   ```

**Vorteile:**
- Einfach umzusetzen
- Direkt und klar
- Header wird erkannt
- Custom Settings werden verwendet

---

## 📊 ZUSAMMENFASSUNG

**HAUPTPROBLEM:**
1. Standard config.txt hat keine moOde Headers
2. config.txt.overwrite wird nicht verwendet
3. config.txt.overwrite hat Header in falscher Zeile

**ROOT CAUSE:**
- pi-gen installiert Standard config.txt ohne Headers
- Custom Scripts kopieren nur config.txt.overwrite, verwenden es aber nicht
- Beim Boot fehlen Headers → worker.php überschreibt alles

**LÖSUNG:**
- config.txt.overwrite Header in Zeile 2 verschieben
- 00-run.sh modifizieren, um config.txt zu ersetzen
- Beim Boot sind Headers vorhanden → kein Overwrite!

---

**Status:** ✅ **ANALYSE ABGESCHLOSSEN - LÖSUNG IDENTIFIZIERT**

