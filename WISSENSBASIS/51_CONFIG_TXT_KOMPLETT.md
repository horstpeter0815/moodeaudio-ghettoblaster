# CONFIG.TXT KOMPLETTE PARAMETER-DOKUMENTATION

**Datum:** 02.12.2025  
**Zweck:** Vollständige Dokumentation aller config.txt Parameter für Raspberry Pi  
**Quelle:** Offizielle Raspberry Pi Dokumentation + HiFiBerryOS Analyse

---

## DISPLAY ROTATION PARAMETER

### **display_rotate**
**Beschreibung:** Rotiert das Display um 0°, 90°, 180° oder 270°

**Werte:**
- `display_rotate=0` - Keine Rotation (Standard)
- `display_rotate=1` - 90° im Uhrzeigersinn (Portrait)
- `display_rotate=2` - 180° (auf dem Kopf)
- `display_rotate=3` - 270° (90° gegen Uhrzeigersinn = Landscape)

**Hinweis:** 
- Funktioniert mit Framebuffer (fb0)
- Bei DRM/KMS kann zusätzlich `rotate` Parameter in cmdline.txt nötig sein
- Bei vc4-kms-v3d kann `dtoverlay=vc4-kms-v3d,rotate=270` verwendet werden

**Beispiel:**
```
display_rotate=3  # Landscape (270°)
```

---

## VIDEO PARAMETER (CMDLINE.TXT)

### **video=**
**Beschreibung:** Setzt Display-Auflösung, Refresh-Rate und Rotation über Kernel-Parameter

**Syntax:**
```
video=<output>:<resolution>@<refresh>,rotate=<degrees>
```

**Parameter:**
- `<output>`: HDMI-A-1, HDMI-A-2, DSI-1, etc.
- `<resolution>`: 1280x400, 1920x1080, etc.
- `<refresh>`: 60, 50, etc.
- `rotate`: 0, 90, 180, 270

**Beispiel:**
```
video=HDMI-A-1:1280x400@60,rotate=270
```

**Hinweis:**
- Überschreibt display_rotate in config.txt
- Funktioniert mit vc4-fkms-v3d und vc4-kms-v3d
- Muss in cmdline.txt gesetzt werden

---

## HIFIBERRY DAC+ PRO OVERLAY

### **dtoverlay=hifiberry-dacplus**
**Beschreibung:** Aktiviert HiFiBerry DAC+ Pro Audio-Overlay

**Parameter:**
- `automute` - Auto-Mute Funktion aktivieren
- `24db_digital_gain` - 24dB digital gain
- `leds_off` - LEDs ausschalten
- `mute_ext_ctl` - Externe Mute-Kontrolle

**Syntax:**
```
dtoverlay=hifiberry-dacplus,automute
dtoverlay=hifiberry-dacplus,automute,24db_digital_gain
```

**I2C Bus:**
- Standard: I2C Bus 1
- Address: 0x4d (PCM5122)

**Beispiel:**
```
dtoverlay=hifiberry-dacplus,automute
```

---

## VC4 DISPLAY OVERLAY

### **dtoverlay=vc4-fkms-v3d**
**Beschreibung:** Aktiviert VC4 Fake KMS (Framebuffer-basiert)

**Parameter:**
- `audio=off` - Audio über HDMI deaktivieren
- `audio=on` - Audio über HDMI aktivieren

**Syntax:**
```
dtoverlay=vc4-fkms-v3d,audio=off
```

**Hinweis:**
- Verwendet Framebuffer (/dev/fb0)
- display_rotate funktioniert
- video= Parameter in cmdline.txt funktioniert

### **dtoverlay=vc4-kms-v3d**
**Beschreibung:** Aktiviert VC4 KMS (DRM-basiert)

**Parameter:**
- `rotate=0|90|180|270` - Display-Rotation
- `audio=off|on` - HDMI Audio

**Syntax:**
```
dtoverlay=vc4-kms-v3d,rotate=270,audio=off
```

**Hinweis:**
- Verwendet DRM (/dev/dri/card0)
- Moderner, aber komplexer
- Rotation über rotate Parameter

---

## I2C PARAMETER

### **dtparam=i2c=on**
**Beschreibung:** Aktiviert I2C Bus 1 (GPIO 2/3)

**Syntax:**
```
dtparam=i2c=on
```

### **dtoverlay=i2c-gpio**
**Beschreibung:** Erstellt zusätzlichen I2C Bus über GPIO

**Parameter:**
- `i2c_gpio_sda=<gpio>` - SDA GPIO Pin
- `i2c_gpio_scl=<gpio>` - SCL GPIO Pin

**Syntax:**
```
dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1
```

---

## DISPLAY PARAMETER

### **disable_overscan=1**
**Beschreibung:** Deaktiviert Overscan (Display zeigt volle Auflösung)

**Syntax:**
```
disable_overscan=1
```

### **gpu_mem_XXX**
**Beschreibung:** GPU Memory Zuweisung in MB

**Werte:**
- `gpu_mem_256=100` - Für 256MB Pi
- `gpu_mem_512=100` - Für 512MB Pi
- `gpu_mem_1024=100` - Für 1024MB Pi

**Syntax:**
```
gpu_mem_1024=100
```

---

## KERNEL PARAMETER

### **kernel=zImage**
**Beschreibung:** Kernel-Datei

**Syntax:**
```
kernel=zImage
```

### **start_file=start.elf**
**Beschreibung:** Bootloader-Datei

**Syntax:**
```
start_file=start.elf
```

### **fixup_file=fixup.dat**
**Beschreibung:** Fixup-Datei für Memory-Split

**Syntax:**
```
fixup_file=fixup.dat
```

---

## VOLLSTÄNDIGE PARAMETER-LISTE

### **Display:**
- `display_rotate=0|1|2|3`
- `disable_overscan=0|1`
- `gpu_mem_XXX=<MB>`
- `dtoverlay=vc4-fkms-v3d,audio=off|on`
- `dtoverlay=vc4-kms-v3d,rotate=0|90|180|270,audio=off|on`

### **Audio:**
- `dtoverlay=hifiberry-dacplus,automute,24db_digital_gain,leds_off`
- `dtoverlay=hifiberry-amp100`
- `dtoverlay=hifiberry-dac`

### **I2C:**
- `dtparam=i2c=on`
- `dtoverlay=i2c-gpio,i2c_gpio_sda=<gpio>,i2c_gpio_scl=<gpio>`

### **Kernel:**
- `kernel=zImage`
- `start_file=start.elf`
- `fixup_file=fixup.dat`

---

## CMDLINE.TXT PARAMETER

### **video=**
```
video=<output>:<resolution>@<refresh>,rotate=<degrees>
```

### **root=**
```
root=/dev/mmcblk0p2
```

### **rootwait**
```
rootwait
```

### **console=**
```
console=tty1|tty5
```

---

---

## AUTOMUTE PARAMETER (DETAILIERT)

### **automute für hifiberry-dacplus**
**Beschreibung:** Aktiviert Auto-Mute Funktion - Audio wird automatisch stummgeschaltet wenn kein Signal vorhanden ist

**Syntax:**
```
dtoverlay=hifiberry-dacplus,automute
```

**Funktionsweise:**
- PCM5122 Chip erkennt fehlendes Audio-Signal
- Automatisches Muting über Hardware
- Verhindert Rauschen bei fehlendem Signal

**Hinweis:**
- Funktioniert nur mit PCM5122-basierten DACs
- Muss im Device Tree Overlay aktiviert werden
- Kann nicht über ALSA Mixer gesteuert werden

**Troubleshooting:**
- Prüfe ob Overlay korrekt geladen: `dmesg | grep hifiberry`
- Prüfe I2C Kommunikation: `i2cdetect -y 1` (sollte 0x4d zeigen)
- Prüfe ALSA Card: `aplay -l` (sollte sndrpihifiberry zeigen)

---

## DISPLAY ROTATION (DETAILIERT)

### **Warum funktioniert display_rotate nicht immer?**

**Problem:**
- `display_rotate` funktioniert nur mit Framebuffer (fb0)
- Bei DRM/KMS wird Rotation anders gehandhabt
- Konflikt zwischen config.txt und cmdline.txt Parameter

**Lösungen:**

1. **Framebuffer (vc4-fkms-v3d):**
   ```
   dtoverlay=vc4-fkms-v3d,audio=off
   display_rotate=3
   ```

2. **DRM/KMS (vc4-kms-v3d):**
   ```
   dtoverlay=vc4-kms-v3d,rotate=270,audio=off
   ```

3. **Kernel Parameter (cmdline.txt):**
   ```
   video=HDMI-A-1:1280x400@60,rotate=270
   ```

**Hinweis:**
- Nur EINE Methode verwenden
- cmdline.txt Parameter überschreibt config.txt
- Bei Konflikten: cmdline.txt hat Vorrang

---

**Dokumentation wird kontinuierlich erweitert...**

