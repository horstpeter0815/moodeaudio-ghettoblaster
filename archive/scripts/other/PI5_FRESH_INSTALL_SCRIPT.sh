#!/bin/bash
# Fresh Moode Installation Script für Waveshare 7.9" DSI LCD auf Raspberry Pi 5
# Framebuffer-basierter Ansatz

set -e

echo "=========================================="
echo "Waveshare 7.9\" DSI LCD Setup - Raspberry Pi 5"
echo "=========================================="
echo ""

# Hardware-Info
echo "Hardware-Info:"
cat /proc/cpuinfo | grep -i "model name" | head -1
cat /proc/device-tree/model 2>/dev/null || echo "Device Tree Model nicht verfügbar"
echo ""

# Schritt 1: Hardware-Verifikation
echo "1. Prüfe I2C-Busse..."
if command -v i2cdetect &> /dev/null; then
    echo "I2C Bus 0:"
    i2cdetect -y 0 2>&1 | head -8
    echo ""
    echo "I2C Bus 1:"
    i2cdetect -y 1 2>&1 | head -8
    echo ""
    echo "I2C Bus 10 (DSI):"
    i2cdetect -y 10 2>&1 | head -8 || echo "Bus 10 nicht verfügbar (normal vor Config-Setup)"
else
    echo "i2c-tools nicht installiert, installiere..."
    sudo apt-get install -y i2c-tools
fi
echo ""

# Schritt 2: Config.txt Backup
echo "2. Erstelle Config.txt Backup..."
if [ -f /boot/firmware/config.txt ]; then
    sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backup erstellt: config.txt.backup.*"
else
    echo "WARNUNG: /boot/firmware/config.txt nicht gefunden!"
fi
echo ""

# Schritt 3: Tools installieren
echo "3. Installiere Tools..."
sudo apt-get update -qq
sudo apt-get install -y python3-pip python3-dev fbset i2c-tools 2>&1 | tail -5
pip3 install --user pygame numpy 2>&1 | tail -5 || echo "Pip-Installation fehlgeschlagen, versuche mit sudo..."
sudo pip3 install pygame numpy 2>&1 | tail -5 || echo "Pip-Installation optional"
echo ""

# Schritt 4: Framebuffer prüfen
echo "4. Prüfe Framebuffer..."
if [ -f /sys/class/graphics/fb0/virtual_size ]; then
    FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
    FB_BPP=$(cat /sys/class/graphics/fb0/bits_per_pixel)
    FB_NAME=$(cat /sys/class/graphics/fb0/name)
    echo "Framebuffer gefunden:"
    echo "  Größe: $FB_SIZE"
    echo "  Bits per Pixel: $FB_BPP"
    echo "  Name: $FB_NAME"
else
    echo "INFO: /dev/fb0 noch nicht verfügbar (normal vor Config-Setup)"
    echo "      Wird nach Config.txt-Anpassung und Reboot verfügbar sein"
fi
echo ""

# Schritt 5: Display-Manager Script erstellen
echo "5. Erstelle Display-Manager..."
mkdir -p /home/andre
cat > /home/andre/fb_display.py << 'PYEOF'
#!/usr/bin/env python3
"""
Framebuffer Display Manager für Waveshare 7.9" DSI LCD
Direkter mmap-Zugriff auf /dev/fb0
"""

import mmap
import struct
import time
import os
import sys

FB_DEV = '/dev/fb0'

def get_fb_info():
    """Lese Framebuffer-Informationen"""
    try:
        with open('/sys/class/graphics/fb0/virtual_size', 'r') as f:
            size = f.read().strip().split(',')
            width = int(size[0])
            height = int(size[1])
        with open('/sys/class/graphics/fb0/bits_per_pixel', 'r') as f:
            bpp = int(f.read().strip())
        return width, height, bpp
    except Exception as e:
        print(f"Fehler beim Lesen der FB-Info: {e}")
        # Fallback-Werte
        return 1280, 400, 16

def draw_pixel(fb_mmap, x, y, r, g, b, width, height, bpp):
    """Zeichne einen Pixel"""
    if not (0 <= x < width and 0 <= y < height):
        return
    offset = (y * width + x) * (bpp // 8)
    try:
        if bpp == 16:
            # RGB565: RRRRR GGGGGG BBBBB
            color = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
            fb_mmap[offset:offset+2] = struct.pack('<H', color)
        elif bpp == 24:
            # BGR24
            fb_mmap[offset:offset+3] = struct.pack('BBB', b, g, r)
        elif bpp == 32:
            # BGRA32
            fb_mmap[offset:offset+4] = struct.pack('BBBB', b, g, r, 255)
    except Exception as e:
        pass  # Ignoriere Pixel-Fehler

def clear_screen(fb_mmap, width, height, bpp, r=0, g=0, b=0):
    """Lösche Bildschirm mit Farbe"""
    fb_size = width * height * (bpp // 8)
    if bpp == 16:
        color = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
        color_bytes = struct.pack('<H', color)
        for i in range(0, fb_size, 2):
            fb_mmap[i:i+2] = color_bytes
    elif bpp == 24:
        color_bytes = struct.pack('BBB', b, g, r)
        for i in range(0, fb_size, 3):
            fb_mmap[i:i+3] = color_bytes
    elif bpp == 32:
        color_bytes = struct.pack('BBBB', b, g, r, 255)
        for i in range(0, fb_size, 4):
            fb_mmap[i:i+4] = color_bytes

def draw_rect(fb_mmap, x, y, w, h, r, g, b, width, height, bpp):
    """Zeichne ein Rechteck"""
    for py in range(max(0, y), min(height, y+h)):
        for px in range(max(0, x), min(width, x+w)):
            draw_pixel(fb_mmap, px, py, r, g, b, width, height, bpp)

def main():
    """Hauptfunktion"""
    print("Framebuffer Display Manager startet...")
    
    # Warte auf Framebuffer
    max_retries = 10
    for i in range(max_retries):
        if os.path.exists(FB_DEV):
            break
        print(f"Warte auf {FB_DEV}... ({i+1}/{max_retries})")
        time.sleep(1)
    
    if not os.path.exists(FB_DEV):
        print(f"FEHLER: {FB_DEV} nicht gefunden!")
        sys.exit(1)
    
    width, height, bpp = get_fb_info()
    print(f"Framebuffer: {width}x{height}, {bpp} bpp")
    
    try:
        with open(FB_DEV, 'r+b') as fb:
            fb_size = width * height * (bpp // 8)
            fb_mmap = mmap.mmap(fb.fileno(), fb_size, access=mmap.ACCESS_WRITE)
            
            try:
                frame = 0
                print("Display-Manager läuft. Drücke Ctrl+C zum Beenden.")
                
                while True:
                    # Clear to black
                    clear_screen(fb_mmap, width, height, bpp, 0, 0, 0)
                    
                    # Draw animated pattern
                    center_x, center_y = width // 2, height // 2
                    anim_size = 50 + int(30 * abs((frame % 120) - 60) / 60)
                    color_val = (frame * 4) % 255
                    
                    # Haupt-Rechteck (animiert)
                    draw_rect(fb_mmap, center_x - anim_size//2, center_y - anim_size//2, 
                             anim_size, anim_size, color_val, 255-color_val, 128, width, height, bpp)
                    
                    # Border (grün)
                    border_w = 5
                    draw_rect(fb_mmap, 10, 10, width-20, border_w, 0, 255, 0, width, height, bpp)  # Top
                    draw_rect(fb_mmap, 10, height-15, width-20, border_w, 0, 255, 0, width, height, bpp)  # Bottom
                    draw_rect(fb_mmap, 10, 10, border_w, height-20, 0, 255, 0, width, height, bpp)  # Left
                    draw_rect(fb_mmap, width-15, 10, border_w, height-20, 0, 255, 0, width, height, bpp)  # Right
                    
                    # Status-Text (einfache Pixel-Darstellung)
                    # Zeichne "Moode" als Rechtecke
                    text_y = height - 50
                    text_x = 20
                    draw_rect(fb_mmap, text_x, text_y, 100, 30, 255, 255, 255, width, height, bpp)
                    
                    fb_mmap.flush()
                    frame += 1
                    time.sleep(0.1)
                    
            except KeyboardInterrupt:
                print("\nBeende Display-Manager...")
            finally:
                # Clear screen to black on exit
                clear_screen(fb_mmap, width, height, bpp, 0, 0, 0)
                fb_mmap.flush()
                fb_mmap.close()
                
    except PermissionError:
        print(f"FEHLER: Keine Berechtigung für {FB_DEV}")
        print("Führe aus mit: sudo python3 /home/andre/fb_display.py")
        sys.exit(1)
    except Exception as e:
        print(f"FEHLER: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF

chmod +x /home/andre/fb_display.py
echo "Display-Manager erstellt: /home/andre/fb_display.py"
echo ""

# Schritt 6: Systemd Service
echo "6. Erstelle Systemd Service..."
sudo tee /etc/systemd/system/fb_display.service > /dev/null << 'EOF'
[Unit]
Description=Framebuffer Display Manager
After=graphical.target

[Service]
Type=simple
User=andre
ExecStart=/usr/bin/python3 /home/andre/fb_display.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
echo "Service erstellt (noch nicht aktiviert)"
echo ""

echo "=========================================="
echo "Setup abgeschlossen!"
echo "=========================================="
echo ""
echo "Nächste Schritte:"
echo "1. Config.txt anpassen (siehe PI5_FRESH_INSTALL_PLAN.md)"
echo "   Wichtig: [pi5] Sektion verwenden!"
echo "2. Reboot durchführen"
echo "3. Test: sudo python3 /home/andre/fb_display.py"
echo "4. Aktivieren: sudo systemctl enable --now fb_display.service"
echo ""
echo "Hinweis: Framebuffer wird erst nach Config.txt-Setup verfügbar sein!"
echo ""

