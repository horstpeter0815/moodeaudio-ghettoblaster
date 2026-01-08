# Raspberry Pi VM Setup Guide für Driver-Entwicklung

## Ziel
Eine Raspberry Pi VM aufsetzen um Driver-Code zu entwickeln, Device Tree Overlays zu testen, und System-Verhalten zu verstehen - OHNE Hardware-Risiko.

## Option 1: QEMU mit Raspberry Pi Emulation

### Voraussetzungen (macOS)
```bash
brew install qemu
```

### Image Download
```bash
# Raspberry Pi OS Lite (kleiner, schneller)
wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-01-15/2024-01-15-raspios-bookworm-armhf-lite.img.xz
unxz 2024-01-15-raspios-bookworm-armhf-lite.img.xz
```

### QEMU Start
```bash
qemu-system-arm \
  -M versatilepb \
  -cpu arm1176 \
  -m 256 \
  -drive file=2024-01-15-raspios-bookworm-armhf-lite.img,format=raw \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device rtl8139,netdev=net0 \
  -kernel kernel-qemu-4.19.50-buster \
  -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
  -no-reboot
```

**Problem:** QEMU emuliert NICHT Raspberry Pi Hardware genau - kein DSI, kein I2C wie auf echtem Pi.

## Option 2: Docker mit Raspberry Pi Emulation

### Dockerfile
```dockerfile
FROM arm32v7/debian:bookworm

RUN apt-get update && apt-get install -y \
    build-essential \
    linux-headers-$(uname -r) \
    git \
    vim

WORKDIR /workspace
```

### Build & Run
```bash
docker build -t rpi-dev .
docker run -it --rm rpi-dev bash
```

**Problem:** Auch hier keine echte Pi-Hardware.

## Option 3: Native Cross-Compile (BESTE OPTION für uns!)

### Warum?
- Wir entwickeln auf Mac
- Kompilieren für ARM64
- Testen auf echtem Pi
- KEINE VM nötig!

### Setup (bereits vorhanden)
```bash
# Wir haben bereits:
# - Cross-Compiler
# - Kernel-Source
# - Driver-Code
# - SSH-Zugriff auf Pi
```

## Option 4: Raspberry Pi Imager + Image Mount

### Image mounten und editieren
```bash
# Image mounten
hdiutil attach -imagekey diskimage-class=CRawDiskImage 2024-01-15-raspios-bookworm-armhf-lite.img

# Config editieren
nano /Volumes/boot/config.txt

# Unmounten
hdiutil detach /Volumes/boot
```

**Nützlich für:** Config-Dateien vorbereiten, aber kein Runtime-Test.

## Empfehlung für unser Projekt

**KEINE VM nötig!** Wir haben bereits:
1. ✅ Cross-Compile Setup
2. ✅ Kernel-Source lokal
3. ✅ SSH-Zugriff auf Pi
4. ✅ Driver-Code lokal entwickelbar

**Was wir BRAUCHEN:**
- CRTC-Problem verstehen (Device Tree Analyse)
- Waveshare Overlay analysieren
- fkms + DSI Kompatibilität recherchieren

**VM würde helfen für:**
- Device Tree Syntax-Tests
- Driver-Logik testen (ohne Hardware)
- System-Verhalten verstehen

**Aber:** Für Hardware-spezifische Probleme (I2C, DSI, CRTC) brauchen wir den echten Pi.

## Entscheidung

**Option A:** VM aufsetzen für Learning/Development
- Zeitaufwand: 1-2 Stunden Setup
- Nutzen: Mittel (hilft beim Verstehen, nicht bei Hardware)

**Option B:** Fokus auf CRTC-Problem-Analyse
- Zeitaufwand: Sofort
- Nutzen: Hoch (löst das aktuelle Problem)

**Meine Empfehlung:** Option B - CRTC-Problem analysieren, VM später wenn nötig.

