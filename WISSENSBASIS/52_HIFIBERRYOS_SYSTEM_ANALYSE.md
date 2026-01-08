# HIFIBERRYOS SYSTEM ANALYSE

**Datum:** 02.12.2025  
**Zweck:** Vollständige Analyse des HiFiBerryOS Systems  
**Hardware:** Raspberry Pi 4 Model B, HiFiBerry DAC+ Pro, Display 1280x400

---

## SYSTEM ÜBERSICHT

### **Betriebssystem:**
- **OS:** HiFiBerryOS (Buildroot-basiert)
- **Version:** 20230404 (Build-Datum: 04. April 2023)
- **Kernel:** Linux 5.15.78-v7l
- **Architektur:** ARMv7l
- **Buildroot:** Buildroot-basiertes Embedded Linux System

### **Hostname:**
- ghettoblasterp4

---

## DISPLAY SYSTEM

### **Display Hardware:**
- **Auflösung:** 1280x400 (Landscape)
- **Framebuffer:** /dev/fb0 (vc4drmfb)
- **DRM:** /dev/dri/card0 (vc4)

### **Display Services:**
- **cog.service** - Web Browser für Web-Interface
  - Verwendet WPE WebKit
  - Zeigt http://localhost:80/#now-playing
  - Läuft auf Display
  - **Abhängigkeit:** weston.service (Wayland Compositor)
  - **Status:** Läuft (PID 1121)
  - **Environment:** COG_PLATFORM_FDO_VIEW_FULLSCREEN=1
  - **Restart:** Immer (RestartSec=20)

### **Display Overlay:**
```
dtoverlay=vc4-fkms-v3d,audio=off
```

### **Display Rotation:**
- **config.txt:** `display_rotate=1` (90° im Uhrzeigersinn)
- **cmdline.txt:** `video=HDMI-A-1:1280x400@60,rotate=270`

### **Display Module:**
- **vc4** - VC4 Display Driver
- **drm_kms_helper** - DRM KMS Helper
- **drm** - Direct Rendering Manager

### **Display Boot-Sequenz (dmesg):**
```
[0.261620] simple-framebuffer 3e4bf000.framebuffer: fb0: simplefb registered!
[4.614302] fb0: switching to vc4 from simple
[4.629130] vc4-drm gpu: bound fe600000.firmwarekms (ops vc4_fkms_ops [vc4])
[4.631092] [drm] Initialized vc4 0.0.0 20140616 for gpu on minor 1
[4.887861] vc4-drm gpu: [drm] fb0: vc4drmfb frame buffer device
```

**Erkenntnis:**
- Framebuffer wird zuerst als "simplefb" initialisiert
- Dann wechselt zu vc4 (vc4-fkms-v3d)
- vc4drmfb wird als Framebuffer-Device erstellt

---

## AUDIO SYSTEM

### **Audio Hardware:**
- **Card:** HiFiBerry DAC+ Pro
- **Device:** PCM5122 (I2C 0x4d)
- **ALSA Card:** card 0: sndrpihifiberry

### **Audio Services:**
- **audiocontrol2.service** - Audio Control Service
  - Python3-basiert
  - Steuert Audio-Funktionen
- **hifiberry-detect.service** - HiFiBerry Hardware-Erkennung
  - Erkennt HiFiBerry Hardware automatisch
  - Konfiguriert System entsprechend
- **hifiberry-finish.service** - HiFiBerry Finalisierung
  - Wird nach Hardware-Erkennung ausgeführt

### **Audio Overlay:**
```
dtoverlay=hifiberry-dacplus,automute
```

### **Audio Module:**
- **snd_soc_pcm512x** - PCM5122 Driver
- **snd_soc_hifiberry_dacplus** - HiFiBerry DAC+ Driver
- **snd_soc_bcm2835_i2s** - BCM2835 I2S Driver

---

## I2C BUS ARCHITEKTUR

### **I2C Bus 1:**
- **Controller:** bcm2835 (i2c@7e804000)
- **GPIO:** 2/3 (SDA/SCL)
- **Devices:**
  - 0x4d - PCM5122 (HiFiBerry DAC+ Pro)

### **I2C Bus 10:**
- **Status:** Nicht verfügbar
- **Hinweis:** Touchscreen nicht erkannt

### **I2C Module:**
- **i2c_bcm2835** - BCM2835 I2C Controller (Bus 1)
- **i2c_gpio** - GPIO-basierter I2C Bus (Bus 22)
- **i2c_algo_bit** - Bit-banging I2C Algorithmus
- **i2c_dev** - I2C Device Interface

### **I2C Bus Details:**
- **Bus 1:** /dev/i2c-1 (bcm2835, GPIO 2/3)
- **Bus 22:** /dev/i2c-22 (i2c-gpio, GPIO 0/1)
- **Bus 10:** Nicht verfügbar (Touchscreen nicht erkannt)

### **I2C Overlay:**
```
dtparam=i2c=on
dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1
```

---

## SERVICES ÜBERSICHT

### **Display Services:**
- **cog.service** - Web Browser (WPE WebKit)
  - Zeigt Web-Interface auf Display
  - Port: 80

### **Audio Services:**
- **audiocontrol2.service** - Audio Control
  - Steuert Audio-Funktionen
  - Python3-basiert

### **Network Services:**
- **avahi-daemon.service** - mDNS/DNS-SD
- **bluetooth.service** - Bluetooth
- **bluealsa.service** - BlueALSA

### **System Services:**
- **dbus.service** - D-Bus
- **docker.service** - Docker
- **getty@tty1.service** - Console

---

## BOOT KONFIGURATION

### **config.txt:**
```
# Display
disable_overscan=1
display_rotate=1
dtoverlay=vc4-fkms-v3d,audio=off

# I2C
dtparam=i2c=on
dtparam=spi=on
dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1

# Audio
dtoverlay=hifiberry-dacplus,automute

# Kernel
kernel=zImage
start_file=start.elf
fixup_file=fixup.dat
```

### **cmdline.txt:**
```
root=/dev/mmcblk0p2 rootwait console=tty5 systemd.show_status=0 quiet splash video=HDMI-A-1:1280x400@60,rotate=270
```

---

## WARUM FUNKTIONIERT ES HIER?

### **1. Buildroot-System:**
- Minimales System
- Keine Konflikte mit Desktop-Environment
- Direkte Hardware-Zugriffe

### **2. Display:**
- **vc4-fkms-v3d** - Framebuffer-basiert
- **cog.service** - Einfacher Web Browser
- Keine X Server Komplexität

### **3. Audio:**
- **hifiberry-dacplus** Overlay funktioniert direkt
- Keine ALSA-Konflikte
- Automatische Hardware-Erkennung

### **4. I2C:**
- Standard I2C Bus 1 funktioniert
- Keine Timing-Probleme
- Einfache Hardware-Zugriffe

---

## UNTERSCHIED ZU MOODE

### **moOde:**
- **RaspiOS-basiert** - Vollständiges Debian
- **X Server** - Komplexes Display-System
- **LightDM** - Display Manager
- **Mehrere Services** - Können kollidieren

### **HiFiBerryOS:**
- **Buildroot** - Minimales System
- **Framebuffer** - Einfaches Display
- **cog.service** - Einfacher Browser
- **Weniger Services** - Weniger Konflikte

---

## LESSONS LEARNED

### **1. Display:**
- Framebuffer ist einfacher als X Server
- vc4-fkms-v3d funktioniert zuverlässig
- Rotation über display_rotate + video= Parameter

### **2. Audio:**
- hifiberry-dacplus Overlay funktioniert direkt
- automute Parameter funktioniert
- Keine zusätzliche Konfiguration nötig

### **3. I2C:**
- Standard I2C Bus 1 funktioniert zuverlässig
- Keine Timing-Probleme bei einfachem System
- Hardware-Erkennung funktioniert automatisch

---

**System-Analyse wird kontinuierlich erweitert...**

