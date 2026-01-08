# Display Manager Optionen für Framebuffer

## Tools die Framebuffer direkt auslesen:

### 1. fbi (Framebuffer Imageviewer)
```bash
sudo apt-get install fbi
sudo fbi -T 1 -d /dev/fb0 -noverbose image.png
```
- ✅ Zeigt Bilder direkt auf Framebuffer
- ✅ Kein CRTC nötig
- ✅ Einfach zu installieren

### 2. DirectFB
```bash
sudo apt-get install directfb
```
- ✅ Direkter Framebuffer-Zugriff
- ✅ Hardware-Beschleunigung möglich
- ⚠️ Komplexer Setup

### 3. Python + pygame (bereits getestet)
```python
import pygame
os.environ['SDL_FBDEV'] = '/dev/fb0'
screen = pygame.display.set_mode((400, 1280))
```
- ✅ Funktioniert bereits
- ✅ Kann kontinuierlich laufen
- ✅ Flexibel

### 4. fbset + dd (direkter Schreibzugriff)
```bash
fbset -fb /dev/fb0 -g 400 1280 400 1280 32
dd if=image.raw of=/dev/fb0
```
- ✅ Sehr einfach
- ✅ Direkter Zugriff
- ⚠️ Nur statische Bilder

### 5. X11 mit fbdev (bereits getestet)
- ⚠️ Braucht CRTC
- ❌ Funktioniert nicht ohne Patch

## Empfehlung:

**fbi** oder **Python + pygame** für kontinuierliche Anzeige

---

**Status:** Prüfe welche Tools verfügbar sind...

