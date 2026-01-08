# Raspberry Pi 4B Technische Dokumentation - Analyse

## Heruntergeladene Dokumente
- **Raspberry_Pi_4_Datasheet.pdf** (403KB) - Release 1.1, March 2024
- **Raspberry_Pi_4_Product_Brief.pdf** (601KB)

## Wichtige Erkenntnisse für Waveshare DSI Display

### 1. DSI Interface Spezifikation

**Pi 4B hat:**
- **1x Raspberry Pi 2-lane MIPI DSI Display connector**
- **Backwards compatible** mit legacy Raspberry Pi boards
- Unterstützt alle verfügbaren Raspberry Pi display peripherals

**WICHTIG:** Pi 4B hat nur **2-lane MIPI DSI** (nicht 4-lane wie Pi 5!)

### 2. Video/Graphics Hardware

- **VideoCore VI 3D Graphics**
- **Supports dual HDMI display output up to 4Kp60**
- **2x micro-HDMI ports** (beide unterstützen CEC und HDMI 2.0)

### 3. Weitere Display-Interfaces

- **DPI (Display Parallel Interface):** Standard parallel RGB interface auf GPIOs
  - Up-to-24-bit parallel interface
  - Kann einen sekundären Display unterstützen

### 4. Software Stack

- **ARMv8 Instruction Set**
- **Mature Linux software stack**
- **Recent Linux kernel support**
- **Many drivers upstreamed**
- **Stable and well supported userland**
- **Availability of GPU functions using standard APIs**

### 5. GPIO Interface

- **28x user GPIO** supporting various interface options:
  - Up to 6x UART
  - Up to 6x I2C
  - Up to 5x SPI
  - 1x SDIO interface
  - 1x DPI (Parallel RGB Display)
  - 1x PCM
  - Up to 2x PWM channels
  - Up to 3x GPCLK outputs

### 6. Power Requirements

- **5V DC** über USB-C-Anschluss (mindestens 3A)
- **5V DC** über GPIO-Header (mindestens 3A)
- **Power over Ethernet (PoE)** unterstützt (erfordert separates PoE HAT)

### 7. Temperature Range

- **Recommended ambient operating temperature:** 0 to 50 degrees Celsius
- **CPU throttling:** Bei 85°C wird CPU speed und voltage reduziert

## Vergleich: Pi 4B vs Pi 5 (für DSI Display)

| Feature | Pi 4B | Pi 5 |
|---------|-------|------|
| DSI Lanes | **2-lane MIPI DSI** | 4-lane MIPI DSI (2x DSI interfaces) |
| DSI Connector | 1x Raspberry Pi DSI connector | 22PIN DSI1 port |
| Cable | **15PIN FPC cable** | DSI-Cable-12cm |
| DSI Interface Name | DSI-1 (in Bullseye) | DSI-2 (in Bookworm) |
| VideoCore | VideoCore VI | VideoCore VII |

## Relevanz für Waveshare 7.9" DSI Display

1. **Hardware-Kompatibilität:**
   - Pi 4B verwendet **15PIN FPC cable** (nicht DSI-Cable-12cm)
   - Pi 4B hat nur **2-lane MIPI DSI** (ausreichend für Waveshare Display)
   - Waveshare Display ist kompatibel mit Pi 4B

2. **Software-Konfiguration:**
   - `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch` funktioniert mit Pi 4B
   - VC4 KMS driver unterstützt Pi 4B
   - DRM/KMS Stack ist verfügbar

3. **Display-Interface:**
   - In Bullseye/Buster: **DSI-1** (nicht DSI-2!)
   - In Bookworm: Kann DSI-2 sein (wenn Pi 5 verwendet wird)

## Nächste Schritte

Basierend auf dieser Analyse sollte die Video-Pipeline für Pi 4B folgendes testen:

1. **DSI Hardware:**
   - 2-lane MIPI DSI connector detection
   - 15PIN FPC cable connection
   - DSI host initialization

2. **VideoCore VI:**
   - VC4 KMS driver loading
   - DRM device creation
   - Framebuffer allocation

3. **Display Pipeline:**
   - Panel driver binding
   - DSI host to panel communication
   - Mode setting
   - Backlight control

