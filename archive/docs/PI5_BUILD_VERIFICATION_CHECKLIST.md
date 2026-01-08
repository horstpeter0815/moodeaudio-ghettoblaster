# ✅ PI 5 BUILD VERIFICATION CHECKLIST

**Datum:** 2025-12-09  
**Status:** 🔍 VOLLSTÄNDIGE PRÜFUNG VOR BUILD  
**Zweck:** Jedes Detail prüfen bevor Build gestartet wird

---

## 🎯 HARDWARE-TARGET

- [x] **Hardware:** Raspberry Pi 5 (BCM2712)
- [x] **Audio:** HiFiBerry AMP100
- [x] **Display:** Waveshare 1280x400 DSI LCD
- [x] **Touchscreen:** FT6236

---

## 📦 KERNEL-PAKETE

### **Datei:** `imgbuild/pi-gen-64/stage0/02-firmware/01-packages`

- [x] ✅ `linux-image-rpi-2712` (Pi 5 Kernel) - **VORHANDEN**
- [x] ✅ `linux-headers-rpi-2712` (Pi 5 Headers) - **VORHANDEN**
- [x] ✅ `linux-image-rpi-v8` (Pi 4 Kernel) - **ENTFERNT**
- [x] ✅ `linux-headers-rpi-v8` (Pi 4 Headers) - **ENTFERNT**

**Status:** ✅ **KORREKT - NUR PI 5 KERNEL**

---

## ⚙️ CONFIG.TXT

### **Datei:** `moode-source/boot/firmware/config.txt.overwrite`

- [x] ✅ `[pi5]` Sektion vorhanden
- [x] ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` in `[pi5]` Sektion
- [x] ✅ `[pi4]` Sektion hat `dtoverlay=vc4-kms-v3d,noaudio` (für Kompatibilität)
- [x] ✅ `[all]` Sektion hat **KEINE** device-spezifischen Overlays

**Status:** ✅ **KORREKT - PI 5 OVERLAY IN RICHTIGER SEKTION**

---

## 🔌 DEVICE TREE OVERLAYS

### **Datei:** `moode-source/boot/firmware/overlays/ghettoblaster-amp100.dts`
- [x] ✅ `compatible = "brcm,bcm2712"` (Pi 5)

### **Datei:** `moode-source/boot/firmware/overlays/ghettoblaster-ft6236.dts`
- [x] ✅ `compatible = "brcm,bcm2712"` (Pi 5)

**Status:** ✅ **KORREKT - ALLE OVERLAYS FÜR PI 5**

---

## 🏗️ BUILD-KONFIGURATION

### **Datei:** `imgbuild/pi-gen-64/config`
- [x] ✅ `IMG_NAME=moode-r1001`
- [x] ✅ `RELEASE=trixie`
- [x] ✅ `TARGET_HOSTNAME=GhettoBlaster`
- [x] ✅ `ENABLE_SSH=1`

**Status:** ✅ **KORREKT**

---

## 📋 BUILD-STAGES

### **Stage 0: Firmware**
- [x] ✅ Kernel-Pakete korrekt (nur Pi 5)

### **Stage 3: Custom Components**
- [x] ✅ `03-ghettoblaster-custom/00-deploy.sh` kopiert config.txt.overwrite
- [x] ✅ `03-ghettoblaster-custom/00-run-chroot.sh` installiert Services

**Status:** ✅ **KORREKT**

---

## 🔧 CUSTOM COMPONENTS

### **Services:**
- [x] ✅ Alle Services vorhanden
- [x] ✅ Services sind Pi 5 kompatibel

### **Scripts:**
- [x] ✅ Alle Scripts vorhanden
- [x] ✅ Scripts sind Pi 5 kompatibel

**Status:** ✅ **KORREKT**

---

## ⚠️ POTENTIELLE PROBLEME

### **1. Kernel Driver Installation**
- **Datei:** `imgbuild/pi-gen-64/stage3/02-moode-install-post/00-run-chroot.sh`
- **Status:** ✅ Script sucht automatisch nach Kernel-Paket
- **Risiko:** ⚠️ **NIEDRIG** - Sollte funktionieren

### **2. rpi-update**
- **Status:** ✅ **NICHT GEFUNDEN** - Kein rpi-update im Build
- **Risiko:** ✅ **KEIN RISIKO**

---

## ✅ FINALE VERIFIKATION

### **Vor Build-Start prüfen:**

1. [x] ✅ Kernel-Pakete: Nur Pi 5
2. [x] ✅ Config.txt: Pi 5 Overlay in [pi5] Sektion
3. [x] ✅ Device Tree: Alle Overlays für bcm2712
4. [x] ✅ Build-Config: Korrekt
5. [x] ✅ Custom Components: Vorhanden und kompatibel

---

## 🚀 BUILD-BEREITSCHAFT

**Status:** ✅ **BEREIT FÜR BUILD**

**Alle kritischen Komponenten sind für Pi 5 konfiguriert!**

---

**Erstellt:** 2025-12-09  
**Nächste Schritte:** Build starten

