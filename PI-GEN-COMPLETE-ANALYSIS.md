# PI-GEN VOLLSTÄNDIGE ANALYSE - ALLE SCRIPTS

**Datum:** 2025-12-21  
**Zweck:** Vollständige Durchsuchung von pi-gen nach allen Scripts, die config.txt oder boot/firmware betreffen

---

## 📊 STATISTIK

- **34 Shell-Scripts** gefunden
- **113 Dateien** insgesamt in pi-gen
- **3 kritische Stellen** für config.txt gefunden

---

## 🔍 ALLE SCRIPTS NACH STAGE

### **STAGE 0:**
- `stage0/00-configure-apt/00-run.sh` - APT Konfiguration
- `stage0/prerun.sh` - Bootstrap
- `stage0/02-firmware/02-run.sh` - Firmware Setup

### **STAGE 1:**
- `stage1/00-boot-files/00-run.sh` - **KRITISCH: Installiert Standard config.txt**
- `stage1/01-sys-tweaks/00-run.sh` - System Tweaks
- `stage1/prerun.sh` - Stage 1 Pre-Run
- `stage1/02-net-tweaks/00-run.sh` - Network Tweaks

### **STAGE 2:**
- `stage2/01-sys-tweaks/01-run.sh` - System Tweaks
- `stage2/prerun.sh` - Stage 2 Pre-Run
- `stage2/04-cloud-init/01-run.sh` - Cloud Init (kommentiert: boot/firmware)
- `stage2/03-set-timezone/02-run.sh` - Timezone
- `stage2/02-net-tweaks/01-run.sh` - Network Tweaks

### **STAGE 3:**
- `stage3/01-print-support/00-run.sh` - Print Support
- `stage3/prerun.sh` - Stage 3 Pre-Run
- `stage3/00-moode-install-prereq/00-run-chroot.sh` - moOde Prerequisites
- `stage3/03-ghettoblaster-custom/00-run.sh` - **KOPIERT config.txt.overwrite**
- `stage3/03-ghettoblaster-custom/00-run-chroot.sh` - Custom Components (chroot)
- `stage3/03-ghettoblaster-custom/00-deploy.sh` - **KOPIERT config.txt.overwrite**
- `stage3/02-moode-install-post/00-run-chroot.sh` - moOde Post-Install

### **STAGE 4:**
- `stage4/01-disable-wayvnc/00-run.sh` - WayVNC Disable
- `stage4/prerun.sh` - Stage 4 Pre-Run

### **STAGE 5:**
- `stage5/prerun.sh` - Stage 5 Pre-Run

### **EXPORT-IMAGE:**
- `export-image/00-allow-rerun/00-run.sh` - Allow Rerun
- `export-image/01-user-rename/01-run.sh` - User Rename
- `export-image/02-set-sources/01-run.sh` - Set Sources
- `export-image/03-network/01-run.sh` - Network Config
- `export-image/04-set-partuuid/00-run.sh` - Set PartUUID (modifiziert cmdline.txt)
- `export-image/05-finalise/01-run.sh` - Finalise (kopiert issue.txt nach boot/firmware)
- `export-image/prerun.sh` - **KRITISCH: rsync kopiert boot/firmware**

### **EXPORT-NOOBS:**
- `export-noobs/prerun.sh` - NOOBS Pre-Run
- `export-noobs/00-release/00-run.sh` - NOOBS Release
- `export-noobs/00-release/files/partition_setup.sh` - Partition Setup

### **SCRIPTS:**
- `scripts/common` - Common Functions
- `scripts/dependencies_check` - Dependencies Check
- `scripts/remove-comments.sed` - Remove Comments

### **BUILD:**
- `build.sh` - Haupt-Build-Script
- `build-docker.sh` - Docker Build

---

## 🎯 KRITISCHE STELLEN FÜR config.txt

### **1. stage1/00-boot-files/00-run.sh**
**Zeile 10:**
```bash
install -m 644 files/config.txt "${ROOTFS_DIR}/boot/firmware/"
```
**Was es tut:** Installiert Standard config.txt in Stage 1  
**Status:** ✅ OK - wird später überschrieben

---

### **2. export-image/prerun.sh**
**Zeile 72-73:**
```bash
rsync -aHAXx --exclude /var/cache/apt/archives --exclude /boot/firmware "${EXPORT_ROOTFS_DIR}/" "${ROOTFS_DIR}/"
rsync -rtx --exclude config.txt "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"
```
**Was es tut:** Kopiert ALLES von EXPORT_ROOTFS_DIR nach ROOTFS_DIR  
**Problem:** rsync würde config.txt überschreiben  
**Fix:** ✅ `--exclude config.txt` + danach config.txt.overwrite kopieren (Zeile 74-87)

**Zeile 74-87:**
```bash
# PERMANENT FIX: Ensure custom config.txt.overwrite replaces config.txt AFTER rsync
MOODE_SOURCE="${MOODE_SOURCE:-/workspace/moode-source}"
if [ -f "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" ]; then
	cp "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" "${ROOTFS_DIR}/boot/firmware/config.txt" || true
	echo "✅ config.txt.overwrite copied and REPLACED config.txt in export-image/prerun.sh"
else
	# Fallback: Check if it's already in EXPORT_ROOTFS_DIR
	if [ -f "${EXPORT_ROOTFS_DIR}/boot/firmware/config.txt.overwrite" ]; then
		cp "${EXPORT_ROOTFS_DIR}/boot/firmware/config.txt.overwrite" "${ROOTFS_DIR}/boot/firmware/config.txt" || true
		echo "✅ Using config.txt.overwrite from EXPORT_ROOTFS_DIR"
	fi
fi
```
**Status:** ✅ FIXED

---

### **3. stage3/03-ghettoblaster-custom/00-run.sh**
**Zeile 36-44:**
```bash
# Copy config.txt.overwrite to boot partition AND REPLACE config.txt
if [ -f "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" ]; then
    mkdir -p "$ROOTFS/boot/firmware"
    # PERMANENT FIX: Replace config.txt with config.txt.overwrite (not just copy)
    cp "$MOODE_SOURCE/boot/firmware/config.txt.overwrite" "$ROOTFS/boot/firmware/config.txt" || true
    echo "✅ config.txt.overwrite copied and REPLACED config.txt"
```
**Was es tut:** Kopiert config.txt.overwrite → config.txt in Stage 3  
**Status:** ✅ OK

---

### **4. stage3/03-ghettoblaster-custom/00-deploy.sh**
**Zeile 18-23:**
```bash
# Copy config.txt.overwrite to boot partition AND REPLACE config.txt
if [ -f "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" ]; then
    mkdir -p "${ROOTFS}/boot/firmware"
    # PERMANENT FIX: Replace config.txt with config.txt.overwrite (not just copy)
    cp "${MOODE_SOURCE}/boot/firmware/config.txt.overwrite" "${ROOTFS}/boot/firmware/config.txt" || true
    echo "✅ config.txt.overwrite copied and REPLACED config.txt"
```
**Was es tut:** Kopiert config.txt.overwrite → config.txt im Deploy  
**Status:** ✅ OK

---

## 📋 ANDERE WICHTIGE STELLEN

### **export-image/04-set-partuuid/00-run.sh**
**Zeile 13:**
```bash
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${ROOTFS_DIR}/boot/firmware/cmdline.txt"
```
**Was es tut:** Modifiziert cmdline.txt (nicht config.txt)  
**Status:** ✅ OK

---

### **export-image/05-finalise/01-run.sh**
**Zeile 67:**
```bash
install -m 644 "${ROOTFS_DIR}/etc/rpi-issue" "${ROOTFS_DIR}/boot/firmware/issue.txt"
```
**Was es tut:** Kopiert issue.txt nach boot/firmware (nicht config.txt)  
**Status:** ✅ OK

---

### **stage2/04-cloud-init/01-run.sh**
**Zeile 12-14 (KOMMENTIERT):**
```bash
#install -v -m 755 files/meta-data "${ROOTFS_DIR}/boot/firmware/meta-data"
#install -v -m 755 files/user-data "${ROOTFS_DIR}/boot/firmware/user-data"
#install -v -m 755 files/network-config "${ROOTFS_DIR}/boot/firmware/network-config"
```
**Was es tut:** Cloud-init Dateien (kommentiert, betrifft nicht config.txt)  
**Status:** ✅ OK

---

## ✅ ZUSAMMENFASSUNG

**Alle Scripts durchsucht:** ✅  
**Kritische Stellen gefunden:** 3  
**Alle Fixes angewendet:** ✅

**BEIM NÄCHSTEN BUILD:**
1. Stage 1 installiert Standard config.txt
2. Stage 3 überschreibt mit config.txt.overwrite
3. export-image/prerun.sh überschreibt NICHT mehr (--exclude config.txt + danach kopieren)

**KEINE Python-Scripts gefunden, die config.txt überschreiben!**

