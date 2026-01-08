# Waveshare 7.9" DSI LCD - Vollständige Analyse aller Abschnitte

## 1. Features
- 7.9inch DSI touch screen with five-point capacitive touch control
- IPS display panel with a hardware resolution of 400×1480
- Toughened glass touch panel, hardness up to 6H
- **Support Pi5/CM5/4B/CM4/3B+/3A+/3B/CM3+/CM3** ← WICHTIG: Pi 4B ist unterstützt
- Directly drive the LCD by the DSI interface on the Raspberry Pi, with up to 60Hz refreshing rate
- **Supports Bookworm/Bullseye/Buster systems** when working with Raspberry Pi
- Supports software control of backlight brightness

## 2. Hardware Connection

### Working with Pi5/CM5/CM4/CM3+/CM3
- **DSI-Cable-12cm** cable
- Connect to **22PIN DSI1 port** of the Raspberry Pi motherboard
- **NICHT für Pi 4!**

### Working with Pi4B/3B+/3B/3A+ ← **DIES IST DER RICHTIGE ABSCHNITT FÜR PI 4**
- **15PIN FPC cable** (nicht DSI-Cable-12cm!)
- Connect DSI interface of display to DSI interface of the Raspberry Pi board
- Install the Raspberry Pi with its back facing downward onto the display board

## 3. Software Setting

### For Bookworm and Bullseye System

**Schritt 1:**
- Connect the TF card to the PC
- Download and use Raspberry Pi Imager to flash the corresponding system image

**Schritt 2:**
- After the image flashing is completed, open the **config.txt** file in the root directory of the TF card
- **Add the following code at the end of the config.txt**, save and safely eject the TF card
- **WICHTIG:** Der Code-Block ist im Snapshot nicht sichtbar, aber basierend auf früheren Analysen sollte es sein:
  ```
  dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
  ```
- **Note:** Seit Pi5/CM4/CM3+/CM3 zwei mipi DSI interfaces haben, muss man beachten, dass... (Text abgeschnitten)

**Schritt 3:**
- Insert the TF card into the Raspberry Pi
- Power on the Raspberry Pi
- Wait for a few seconds normally to enter the display
- After the system starts, the touch function can be used normally

## 4. Bookworm Touch Screen Rotation
- **Nur für Bookworm System!**
- Bullseye/Buster unterstützen diese synchronisierte Rotation NICHT
- Steps:
  1. Open "Screen Configuration" application
  2. Go to "Screen"->"DSI-2"->"Touchscreen", check "11-005d Goodix Capacitive TouchScreen", click "Apply"
  3. Go to "Screen"->"DSI-2"->"Orientation", check the direction, click "Apply"
- **Note:** Only the Bookworm system supports the above synchronization rotation method. For Bullseye and Buster systems, after displaying rotation, touch rotation needs to be manually set separately.

## 5. Bullseye/Buster Display Rotation
- Open "Screen Configuration" application
- Go to "Screen" -> "DSI-1" -> "Orientation" (nicht DSI-2!)
- Check the direction you need to rotate, click "Apply"

## 6. Disable Touch
- At the end of the config.txt file, add the following command corresponding to disabling touch:
  ```
  dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch
  ```
- Note: After adding a command, it needs to be restarted to take effect.

## WICHTIGE ERKENNTNISSE:

1. **Pi 4 vs Pi 5:** 
   - Pi 4 verwendet **15PIN FPC cable** (nicht DSI-Cable-12cm)
   - Pi 5 verwendet **DSI-Cable-12cm** und **22PIN DSI1 port**

2. **DSI Interface Unterschied:**
   - Pi 4: **DSI-1** (in Bullseye/Buster Rotation Anweisungen)
   - Pi 5: **DSI-2** (in Bookworm Touch Screen Rotation Anweisungen)

3. **config.txt für Bookworm/Bullseye:**
   - Basis: `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch`
   - Mit disable_touch: `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch`

4. **Rotation:**
   - Bookworm: Synchronisierte Display+Touch Rotation über "Screen Configuration"
   - Bullseye/Buster: Display Rotation über "Screen Configuration", Touch Rotation muss separat gesetzt werden

5. **Der Code-Block in Schritt 2:**
   - Wird im Snapshot nicht erfasst, aber sollte `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch` sein
   - Muss am **Ende** der config.txt hinzugefügt werden

