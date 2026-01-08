# Raspberry Pi config.txt & cmdline.txt - Vollständige Referenz

**Erstellt:** 25. November 2024  
**Version:** 1.0  
**Ziel:** Umfassende Dokumentation aller config.txt und cmdline.txt Parameter für Raspberry Pi 4 und 5

---

## Inhaltsverzeichnis

1. [Einführung](#einführung)
2. [Hardware-Unterschiede: Pi 4 vs Pi 5](#hardware-unterschiede-pi-4-vs-pi-5)
3. [config.txt - Grundlagen](#configtxt---grundlagen)
4. [config.txt - Alle Parameter](#configtxt---alle-parameter)
5. [Device Tree Overlays (dtoverlay)](#device-tree-overlays-dtoverlay)
6. [Device Tree Parameters (dtparam)](#device-tree-parameters-dtparam)
7. [cmdline.txt - Vollständige Referenz](#cmdlinetxt---vollständige-referenz)
8. [Syntax und Flags](#syntax-und-flags)
9. [Praktische Beispiele](#praktische-beispiele)
10. [Troubleshooting](#troubleshooting)

---

## Einführung

Die `config.txt` und `cmdline.txt` Dateien sind die Hauptkonfigurationsdateien für Raspberry Pi Systeme. Sie werden beim Boot-Vorgang gelesen und konfigurieren Hardware, Kernel-Parameter und Systemverhalten.

**Wichtige Dateien:**
- `/boot/firmware/config.txt` (neue Firmware, Pi 4/5)
- `/boot/config.txt` (alte Firmware, Pi 3 und älter)
- `/boot/firmware/cmdline.txt` oder `/boot/cmdline.txt`

---

## Hardware-Unterschiede: Pi 4 vs Pi 5

### Raspberry Pi 4 Model B

**Prozessor:**
- Broadcom BCM2711 (Quad-core Cortex-A72 @ 1.8GHz)
- VideoCore VI GPU
- 1GB, 2GB, 4GB oder 8GB RAM

**Display-Interfaces:**
- 1x 2-lane MIPI DSI Display Connector
- 2x micro-HDMI Ports (HDMI 2.0, bis 4K@60Hz)
- 1x MIPI CSI Camera Connector

**I2C Busse:**
- `i2c-1`: GPIO I2C (Pins 3/5) - VideoCore verwaltet
- `i2c-10`: DSI/CSI I2C (über DSI/CSI Kabel) - VideoCore verwaltet

**USB:**
- 2x USB 3.0 Ports
- 2x USB 2.0 Ports

**Netzwerk:**
- Gigabit Ethernet
- Dual-band 802.11ac WiFi
- Bluetooth 5.0

**KMS Overlay:**
```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
```

---

### Raspberry Pi 5

**Prozessor:**
- Broadcom BCM2712 (Quad-core Cortex-A76 @ 2.4GHz)
- VideoCore VII GPU
- 4GB oder 8GB RAM (LPDDR4X)

**Display-Interfaces:**
- 1x 4-lane MIPI DSI Display Connector (verbessert!)
- 2x micro-HDMI Ports (HDMI 2.1, bis 4K@120Hz)
- 2x MIPI CSI Camera Connectors

**RP1 Controller (NEU!):**
- Dedizierter I/O-Controller (Raspberry Pi 1)
- Verwaltet GPIO, I2C, SPI, UART, PWM
- Separate I2C Busse über RP1
- `i2c-1`: RP1 I2C (GPIO) - RP1 verwaltet
- `i2c-6`: RP1 I2C (alternativ) - RP1 verwaltet
- `i2c-10`: DSI/CSI I2C (wie Pi 4) - VideoCore verwaltet

**USB:**
- 2x USB 3.0 Ports (verbessert)
- 2x USB 2.0 Ports

**Netzwerk:**
- Gigabit Ethernet
- Dual-band 802.11ac WiFi
- Bluetooth 5.0

**PCIe Support:**
- PCIe 2.0 x1 Anschluss
- NVMe SSD Support über M.2

**KMS Overlay:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
```

---

### Vergleichstabelle

| Feature | Pi 4 | Pi 5 |
|---------|------|------|
| DSI Lanes | 2-lane | 4-lane |
| HDMI Version | 2.0 | 2.1 |
| Max HDMI Resolution | 4K@60Hz | 4K@120Hz |
| I2C Controller | VideoCore | RP1 |
| Overlay für KMS | `vc4-kms-v3d-pi4` | `vc4-kms-v3d-pi5` |
| DSI Overlay Flag | `dsi0` oder `dsi1` | `dsi0` oder `dsi1` |
| PCIe Support | ❌ | ✅ |
| NVMe Support | ❌ | ✅ |
| RP1 Controller | ❌ | ✅ |

---

## config.txt - Grundlagen

### Dateistruktur

Die `config.txt` Datei verwendet Sektionen für verschiedene Pi-Modelle:

```ini
# Allgemeine Einstellungen (für alle Modelle)
[all]
parameter=wert

# Spezifisch für Pi 3
[pi3]
parameter=wert

# Spezifisch für Pi 4
[pi4]
parameter=wert

# Spezifisch für Pi 5
[pi5]
parameter=wert

# Spezifisch für Compute Module 4
[cm4]
parameter=wert
```

**Wichtig:** Parameter in `[all]` gelten für alle Modelle, werden aber von modellspezifischen Sektionen überschrieben.

### Kommentare

```ini
# Einzeiliger Kommentar
# Mehrzeilige Kommentare müssen jede Zeile mit # beginnen
```

### Parameter-Syntax

```ini
# Einfacher Parameter
parameter=wert

# Parameter mit mehreren Werten
parameter=wert1,wert2,wert3

# Boolean Parameter
parameter=1    # Aktiviert
parameter=0    # Deaktiviert

# Parameter mit Flags
dtoverlay=name,flag1,flag2=wert
```

---

## config.txt - Alle Parameter

### GPU Memory

```ini
# GPU-Speicher zuweisen (in MB)
gpu_mem=128          # Für alle Modelle
gpu_mem_256=100      # Nur wenn 256MB RAM
gpu_mem_512=100      # Nur wenn 512MB RAM
gpu_mem_1024=100     # Nur wenn 1024MB RAM
```

**Erklärung:** Weist dem VideoCore GPU Speicher zu. Mehr GPU-Speicher = bessere Grafikleistung, aber weniger RAM für das System.

**Empfohlen:**
- Minimal: 64MB
- Standard: 128MB
- Für 4K/Video: 256MB+

---

### Display-Auto-Detection

```ini
# Automatische Display-Erkennung
display_auto_detect=1    # Aktiviert (Standard)
display_auto_detect=0    # Deaktiviert (manuelle Konfiguration)
```

**Erklärung:** Wenn aktiviert, versucht der Pi automatisch, angeschlossene Displays zu erkennen. Bei `0` muss manuell konfiguriert werden.

**Wichtig für DSI-Displays:** Oft sollte `display_auto_detect=0` gesetzt werden, damit manuelle DSI-Konfiguration nicht überschrieben wird.

---

### HDMI-Konfiguration

```ini
# HDMI Hotplug-Verhalten
hdmi_ignore_hotplug=0    # HDMI wird erkannt wenn angeschlossen
hdmi_ignore_hotplug=1    # HDMI wird ignoriert (auch wenn angeschlossen)
hdmi_force_hotplug=0     # HDMI nicht erzwingen
hdmi_force_hotplug=1     # HDMI immer aktivieren (auch ohne Kabel)

# HDMI Blanking
hdmi_blanking=0          # HDMI nicht ausblenden
hdmi_blanking=1          # HDMI ausblenden (schwarz)

# HDMI Group und Mode
hdmi_group=0             # Auto-Detection
hdmi_group=1             # CEA (TV-Modi)
hdmi_group=2             # DMT (Monitor-Modi)
hdmi_mode=0              # Auto-Detection
hdmi_mode=16             # 1080p@60Hz (CEA)
hdmi_mode=82             # 1080p@60Hz (DMT)

# HDMI 4K@60Hz (nur Pi 4/5)
hdmi_enable_4kp60=0      # Deaktiviert
hdmi_enable_4kp60=1      # Aktiviert (benötigt HDMI 2.0/2.1)

# HDMI Drive
hdmi_drive=1             # DVI-Modus (kein Audio)
hdmi_drive=2             # HDMI-Modus (mit Audio)

# HDMI Force EDID Audio
hdmi_force_edid_audio=0  # Standard
hdmi_force_edid_audio=1  # Audio erzwingen

# HDMI Safe Mode
hdmi_safe=1              # Sichere HDMI-Einstellungen (Kompatibilität)
```

**Erklärung:**
- `hdmi_ignore_hotplug=1`: Nützlich wenn DSI-Display verwendet wird und HDMI deaktiviert werden soll
- `hdmi_group=1` (CEA): Für TVs, unterstützt CEC
- `hdmi_group=2` (DMT): Für Computer-Monitore
- `hdmi_enable_4kp60=1`: Benötigt HDMI 2.0 (Pi 4) oder 2.1 (Pi 5)

**HDMI Mode Tabelle (CEA - hdmi_group=1):**
- Mode 1: 640x480@60Hz
- Mode 4: 720x480@60Hz
- Mode 16: 1920x1080@60Hz
- Mode 31: 1920x1080@50Hz
- Mode 32: 1920x1080@24Hz

**HDMI Mode Tabelle (DMT - hdmi_group=2):**
- Mode 4: 640x480@60Hz
- Mode 9: 800x600@60Hz
- Mode 16: 1024x768@60Hz
- Mode 35: 1280x1024@75Hz
- Mode 82: 1920x1080@60Hz
- Mode 87: 3840x2160@60Hz (4K, benötigt hdmi_enable_4kp60=1)

---

### DSI Display Konfiguration

```ini
# LCD/Ignore LCD
ignore_lcd=0            # LCD wird verwendet
ignore_lcd=1            # LCD wird ignoriert

# DSI wird über Device Tree Overlays konfiguriert
# Siehe Abschnitt "Device Tree Overlays"
```

---

### I2C Konfiguration

```ini
# GPIO I2C aktivieren
dtparam=i2c_arm=on      # Aktiviert i2c-1 (GPIO Pins 3/5)
dtparam=i2c_arm=off     # Deaktiviert

# DSI/CSI I2C aktivieren
dtparam=i2c_vc=on       # Aktiviert i2c-10 (DSI/CSI I2C)
dtparam=i2c_vc=off      # Deaktiviert

# I2C Clock Speed (optional)
dtparam=i2c_arm_baudrate=100000    # 100kHz (Standard)
dtparam=i2c_arm_baudrate=400000    # 400kHz (Fast Mode)
dtparam=i2c_arm_baudrate=1000000   # 1MHz (Fast Mode Plus, nur Pi 4/5)
```

**Erklärung:**
- `i2c_arm`: GPIO I2C Bus (i2c-1), für HATs wie HiFiBerry
- `i2c_vc`: VideoCore I2C Bus (i2c-10), für DSI/CSI Displays

**Pi 4 vs Pi 5:**
- Pi 4: `i2c_arm` wird von VideoCore verwaltet
- Pi 5: `i2c_arm` wird von RP1 Controller verwaltet

---

### SPI Konfiguration

```ini
# SPI aktivieren
dtparam=spi=on          # Aktiviert SPI
dtparam=spi=off          # Deaktiviert

# SPI Baudrate (optional)
dtparam=spi_baudrate=1000000    # 1MHz (Standard)
```

---

### Audio Konfiguration

```ini
# Audio aktivieren/deaktivieren
dtparam=audio=on       # Audio aktiviert
dtparam=audio=off      # Audio deaktiviert

# Audio über HDMI
dtparam=audio=on
```

**Erklärung:** Audio kann über HDMI, 3.5mm Jack (nur Pi 4) oder I2S (für HATs) ausgegeben werden.

**Wichtig:** Pi 5 hat keinen 3.5mm Audio-Ausgang! Nur HDMI oder I2S.

---

### Overscan

```ini
# Overscan deaktivieren
disable_overscan=0     # Overscan aktiv (Standard)
disable_overscan=1      # Overscan deaktiviert (empfohlen für moderne Displays)
```

**Erklärung:** Overscan fügt schwarze Ränder hinzu. Bei modernen Displays sollte es deaktiviert sein.

---

### Splash Screen

```ini
# Boot-Splash deaktivieren
disable_splash=0       # Splash aktiv
disable_splash=1       # Splash deaktiviert
```

---

### ARM Boost

```ini
# ARM CPU Boost
arm_boost=0            # Standard-Taktfrequenz
arm_boost=1            # Erhöhte Taktfrequenz (empfohlen)
```

---

### 64-Bit Support

```ini
# 64-Bit Kernel aktivieren
arm_64bit=0            # 32-Bit Kernel
arm_64bit=1            # 64-Bit Kernel (empfohlen für Pi 4/5)
```

---

### Framebuffer

```ini
# Maximale Anzahl Framebuffer
max_framebuffers=2     # Standard: 2
```

---

### Firmware KMS Setup

```ini
# Firmware KMS Setup
disable_fw_kms_setup=0  # Firmware KMS aktiviert
disable_fw_kms_setup=1  # Firmware KMS deaktiviert
```

**Erklärung:** KMS (Kernel Mode Setting) wird normalerweise von der Firmware initialisiert. Bei `1` übernimmt der Kernel.

---

### EEPROM

```ini
# EEPROM Force Read
force_eeprom_read=0    # Standard
force_eeprom_read=1    # EEPROM erneut lesen
```

**Erklärung:** Zwingt den Pi, die EEPROM-Konfiguration erneut zu lesen. Selten benötigt.

---

### LED Konfiguration

```ini
# Activity LED Trigger
dtparam=act_led_trigger=heartbeat    # Heartbeat-Modus
dtparam=act_led_trigger=mmc0         # Blinkt bei SD-Karten-Aktivität
dtparam=act_led_trigger=default-on    # Immer an
dtparam=act_led_trigger=none         # Aus

# Activity LED GPIO
dtparam=act_led_gpio=47              # GPIO Pin für Activity LED

# Power LED (nur Pi 4/5)
dtparam=pwr_led_trigger=default-on   # Immer an
dtparam=pwr_led_trigger=none         # Aus
```

---

### Fan Control (nur Pi 4/5)

```ini
# Fan Temperature Control
dtparam=fan_temp0=50000              # Fan startet bei 50°C (in m°C)
dtparam=fan_temp0_hyst=5000         # Hysterese 5°C
dtparam=fan_temp0_speed=75           # Fan Speed 75%
```

---

### Camera

```ini
# Camera aktivieren
start_x=1             # Camera aktiviert
start_x=0              # Camera deaktiviert

# Camera LED deaktivieren
disable_camera_led=1   # Camera LED aus
```

---

## Device Tree Overlays (dtoverlay)

Device Tree Overlays sind Konfigurationsdateien, die Hardware-Funktionen aktivieren oder konfigurieren.

### Grundlegende Syntax

```ini
# Einfaches Overlay
dtoverlay=overlay-name

# Overlay mit Parametern
dtoverlay=overlay-name,param1=wert1,param2=wert2

# Overlay mit Flags
dtoverlay=overlay-name,flag1,flag2

# Overlay deaktivieren
dtoverlay=overlay-name
# Dann später:
#dtoverlay=overlay-name
```

### Wichtige Overlays

#### VideoCore KMS Overlays

```ini
# Pi 3
dtoverlay=vc4-kms-v3d,noaudio

# Pi 4
dtoverlay=vc4-kms-v3d-pi4,noaudio

# Pi 5
dtoverlay=vc4-kms-v3d-pi5,noaudio
```

**Flags:**
- `noaudio`: Deaktiviert Audio-Unterstützung

**Erklärung:** Aktiviert KMS (Kernel Mode Setting) für moderne Grafik-Treiber. Notwendig für DSI-Displays und moderne Anwendungen.

**⚠️ WICHTIG:** Pi 4 benötigt `vc4-kms-v3d-pi4`, Pi 5 benötigt `vc4-kms-v3d-pi5`! Generisches `vc4-kms-v3d` funktioniert, ist aber nicht optimal.

---

#### Waveshare DSI Display Overlay

```ini
# Waveshare 7.9" DSI LCD (Pi 4/5)
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch

# Mit Flags
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch,dsi0
```

**Panel-Größen:**
- `2_8_inch`
- `3_4_inch`
- `4_0_inch`
- `7_0_inchC`
- `7_9_inch`
- `8_0_inch`
- `10_1_inch`
- `11_9_inch`

**Flags:**
- `disable_touch`: Touchscreen deaktivieren
- `dsi0`: DSI-0 verwenden (Standard: DSI-1)
- `rotation=90`: Display rotieren (0, 90, 180, 270)
- `touchscreen-size-x=1280`: Touchscreen X-Größe
- `touchscreen-size-y=400`: Touchscreen Y-Größe
- `invx`: X-Achse invertieren
- `invy`: Y-Achse invertieren
- `swapxy`: X und Y tauschen

**Erklärung:**
- `dsi0` Flag: Pi 4 hat nur DSI-1, aber Overlay unterstützt `dsi0` für Kompatibilität
- `disable_touch`: Verhindert, dass `ws_touchscreen` an Panel-Adresse bindet

---

#### HiFiBerry Overlays

```ini
# HiFiBerry DAC+
dtoverlay=hifiberry-dacplus

# HiFiBerry AMP100
dtoverlay=hifiberry-amp100,automute

# HiFiBerry DAC+ DSP
dtoverlay=hifiberry-dacplusdsp
```

**Flags:**
- `automute`: Automatisches Muten bei Headphone-Erkennung

---

#### I2C GPIO Overlay

```ini
# Zusätzlicher I2C Bus über GPIO
dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1
```

**Parameter:**
- `i2c_gpio_sda`: GPIO Pin für SDA
- `i2c_gpio_scl`: GPIO Pin für SCL

---

#### Disable Overlays

```ini
# Bluetooth deaktivieren
dtoverlay=disable-bt

# WiFi deaktivieren
dtoverlay=disable-wifi

# WiFi und Bluetooth deaktivieren
dtoverlay=disable-wifi-bt
```

---

### Overlay-Parameter Syntax

```ini
# Parameter mit Wert
dtoverlay=name,param=wert

# Boolean Parameter (Flag)
dtoverlay=name,flag

# Mehrere Parameter
dtoverlay=name,param1=wert1,param2=wert2,flag1

# Parameter mit Komma im Wert (selten)
dtoverlay=name,param="wert,mit,komma"
```

---

## Device Tree Parameters (dtparam)

`dtparam` konfiguriert bereits vorhandene Hardware-Funktionen, während `dtoverlay` neue Hardware hinzufügt.

### I2C Parameters

```ini
dtparam=i2c_arm=on
dtparam=i2c_arm=off
dtparam=i2c_arm_baudrate=100000
```

### SPI Parameters

```ini
dtparam=spi=on
dtparam=spi=off
```

### Audio Parameters

```ini
dtparam=audio=on
dtparam=audio=off
```

### LED Parameters

```ini
dtparam=act_led_trigger=heartbeat
dtparam=act_led_gpio=47
dtparam=pwr_led_trigger=default-on
```

---

## cmdline.txt - Vollständige Referenz

Die `cmdline.txt` Datei enthält Kernel-Boot-Parameter, die beim Start an den Linux-Kernel übergeben werden.

### Grundlegende Syntax

```
parameter1 parameter2 parameter3=wert
```

Parameter werden durch Leerzeichen getrennt.

---

### Wichtigste Parameter

#### Root Filesystem

```
root=/dev/mmcblk0p2
root=PARTUUID=xxxxxxxx-xx
root=LABEL=ROOT
```

**Erklärung:** Definiert das Root-Dateisystem. `PARTUUID` ist robuster als `/dev/mmcblk0p2`.

---

#### Root Filesystem Type

```
rootfstype=ext4
rootfstype=f2fs
```

---

#### Root Wait

```
rootwait
```

**Erklärung:** Wartet bis Root-Dateisystem verfügbar ist (empfohlen).

---

#### Console

```
console=serial0,115200
console=tty1
console=tty5
console=ttyS0,115200
```

**Erklärung:**
- `serial0`: Serial Console (GPIO 14/15)
- `tty1`: Erste virtuelle Konsole
- `tty5`: Fünfte virtuelle Konsole (oft für GUI)

---

#### Video Parameter (VERALTET!)

```
video=DSI-1:1280x400@60
video=HDMI-A-1:1920x1080@60
```

**⚠️ WICHTIG:** `video=` Parameter sind **veraltet** und sollten **nicht** verwendet werden, wenn Device Tree Overlays aktiv sind! Sie können Konflikte verursachen.

**Erklärung:** Wurde früher verwendet, um Display-Modi zu setzen. Heute übernimmt das DRM/KMS System.

---

#### Quiet Boot

```
quiet
```

**Erklärung:** Reduziert Boot-Ausgaben (weniger Logs).

---

#### Splash

```
splash
```

**Erklärung:** Zeigt Boot-Splash-Screen.

---

#### Systemd Status

```
systemd.show_status=0    # Weniger Status-Ausgaben
systemd.show_status=1    # Mehr Status-Ausgaben
```

---

#### Network Interface Names

```
net.ifnames=0           # Alte Interface-Namen (eth0, wlan0)
net.ifnames=1           # Predictable Names (Standard)
```

---

#### WiFi Regulatory Domain

```
cfg80211.ieee80211_regdom=DE    # Deutschland
cfg80211.ieee80211_regdom=US    # USA
```

---

#### Cgroup

```
cgroup_enable=cpuset
cgroup_memory=1
cgroup_enable=memory
```

**Erklärung:** Aktiviert cgroup-Unterstützung (für Container, systemd).

---

#### ZSWAP

```
zswap.enabled=1
```

**Erklärung:** Aktiviert ZSWAP (komprimierter Swap im RAM).

---

### Vollständiges cmdline.txt Beispiel

```
console=serial0,115200 console=tty1 root=PARTUUID=b8ef428a-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE
```

**Erklärung:**
- `console=serial0,115200 console=tty1`: Serial und TTY Console
- `root=PARTUUID=...`: Root über PARTUUID
- `rootfstype=ext4`: Ext4 Dateisystem
- `fsck.repair=yes`: Automatische Reparatur bei Fehlern
- `rootwait`: Warten auf Root
- `cfg80211.ieee80211_regdom=DE`: WiFi-Regulierung Deutschland

---

## Syntax und Flags

### Flag-Definition

Ein **Flag** ist ein Boolean-Parameter ohne Wert. Wenn ein Flag vorhanden ist, ist es aktiviert.

**Beispiele:**
```ini
# In dtoverlay
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch
#                                                      ^^^^^^^^^^^^^ Flag

dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,dsi0
#                                                      ^^^^ Flag
```

### Parameter mit Werten

```ini
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,touchscreen-size-x=1280
#                                                      ^^^^^^^^^^^^^^^^^^^^ Parameter mit Wert
```

### Komma-Syntax

```ini
# Mehrere Parameter/Flags durch Komma getrennt
dtoverlay=name,flag1,param1=wert1,flag2,param2=wert2
```

**Wichtig:** Keine Leerzeichen nach Kommas!

---

## Praktische Beispiele

### Beispiel 1: Waveshare 7.9" DSI Display auf Pi 4

```ini
# config.txt
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch

[all]
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=i2c_arm=on
dtparam=i2c_vc=on
```

```bash
# cmdline.txt
console=serial0,115200 console=tty1 root=PARTUUID=xxxx-xx rootfstype=ext4 rootwait
# KEIN video= Parameter!
```

---

### Beispiel 2: HiFiBerry DAC+ auf Pi 4

```ini
# config.txt
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio

[all]
dtparam=i2c_arm=on
dtoverlay=hifiberry-dacplus
dtparam=audio=off
```

---

### Beispiel 3: Pi 5 mit Waveshare Display

```ini
# config.txt
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch

[all]
display_auto_detect=0
hdmi_ignore_hotplug=1
dtparam=i2c_arm=on
dtparam=i2c_vc=on
```

**Unterschied zu Pi 4:** `vc4-kms-v3d-pi5` statt `vc4-kms-v3d-pi4`

---

### Beispiel 4: HDMI 4K@60Hz auf Pi 4

```ini
# config.txt
[pi4]
hdmi_enable_4kp60=1
hdmi_group=2
hdmi_mode=87

[all]
dtoverlay=vc4-kms-v3d-pi4
```

---

## Troubleshooting

### Problem: Display zeigt kein Bild

**Mögliche Ursachen:**
1. Falsches Overlay aktiviert (Pi 4 vs Pi 5!)
2. HDMI und DSI gleichzeitig aktiv
3. `video=` Parameter in cmdline.txt konflikt mit Overlay
4. Falsche Panel-Größe

**Lösung:**
```ini
# config.txt
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch

[all]
display_auto_detect=0
hdmi_ignore_hotplug=1
```

```bash
# cmdline.txt - ENTFERNE video= Parameter!
```

---

### Problem: I2C Device nicht erkannt

**Mögliche Ursachen:**
1. Falscher I2C Bus
2. I2C nicht aktiviert
3. Hardware-Problem

**Lösung:**
```ini
# Für GPIO I2C (i2c-1)
dtparam=i2c_arm=on

# Für DSI I2C (i2c-10)
dtparam=i2c_vc=on
```

---

### Problem: Dependency Cycles

**Symptom:**
```
dmesg | grep "dependency cycle"
```

**Ursache:** Device Tree Overlays haben zirkuläre Abhängigkeiten.

**Lösung:** Overlays in richtiger Reihenfolge laden, manchmal hilft `force_eeprom_read=1`.

---

### Problem: HDMI wird nicht deaktiviert

**Lösung:**
```ini
hdmi_ignore_hotplug=1
hdmi_force_hotplug=0
hdmi_blanking=1
display_auto_detect=0
```

---

## Weitere Ressourcen

- [Raspberry Pi Dokumentation](https://www.raspberrypi.com/documentation/)
- [Device Tree Overlays](https://github.com/raspberrypi/firmware/tree/master/boot/overlays)
- [config.txt Referenz](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [cmdline.txt Referenz](https://www.raspberrypi.com/documentation/computers/linux_kernel.html)

---

**Ende des Dokuments - Version 1.0**

*Dieses Dokument wird kontinuierlich erweitert während der Arbeit am Display-Problem.*

