#!/bin/bash
# Fresh Moode Installation Script für Waveshare 7.9" DSI LCD
# Framebuffer-basierter Ansatz

set -e

echo "=========================================="
echo "Waveshare 7.9\" DSI LCD Setup"
echo "=========================================="
echo ""

# Schritt 1: Hardware-Verifikation
echo "1. Prüfe I2C-Busse..."
if command -v i2cdetect &> /dev/null; then
    echo "I2C Bus 0:"
    i2cdetect -y 0 | head -5
    echo ""
    echo "I2C Bus 1:"
    i2cdetect -y 1 | head -5
    echo ""
    echo "I2C Bus 10 (DSI):"
    i2cdetect -y 10 2>&1 | head -5 || echo "Bus 10 nicht verfügbar"
else
    echo "i2c-tools nicht installiert, installiere..."
    sudo apt-get install -y i2c-tools
fi
echo ""

# Schritt 2: Config.txt Backup und Setup
echo "2. Setup config.txt..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
echo "Backup erstellt"
echo ""

# Schritt 3: Tools installieren
echo "3. Installiere Tools..."
sudo apt-get update -qq
sudo apt-get install -y python3-pip python3-dev fbset i2c-tools 2>&1 | tail -5
pip3 install --user pygame numpy 2>&1 | tail -5
echo ""

# Schritt 4: Framebuffer prüfen
echo "4. Prüfe Framebuffer..."
if [ -f /sys/class/graphics/fb0/virtual_size ]; then
    FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
    FB_BPP=$(cat /sys/class/graphics/fb0/bits_per_pixel)
    echo "Framebuffer: $FB_SIZE, $FB_BPP bpp"
else
    echo "WARNUNG: /dev/fb0 nicht gefunden!"
fi
echo ""

# Schritt 5: Display-Manager Script erstellen
echo "5. Erstelle Display-Manager..."
cat > /home/andre/fb_display.py << 'PYEOF'
#!/usr/bin/env python3
import mmap
import struct
import time
import os

FB_DEV = '/dev/fb0'

def get_fb_info():
    with open('/sys/class/graphics/fb0/virtual_size', 'r') as f:
        size = f.read().strip().split(',')
        width = int(size[0])
        height = int(size[1])
    with open('/sys/class/graphics/fb0/bits_per_pixel', 'r') as f:
        bpp = int(f.read().strip())
    return width, height, bpp

def draw_pixel(fb_mmap, x, y, r, g, b, width, height, bpp):
    if not (0 <= x < width and 0 <= y < height):
        return
    offset = (y * width + x) * (bpp // 8)
    if bpp == 16:
        color = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
        fb_mmap[offset:offset+2] = struct.pack('<H', color)
    elif bpp == 24 or bpp == 32:
        fb_mmap[offset:offset+3] = struct.pack('BBB', b, g, r)

def clear_screen(fb_mmap, width, height, bpp, r=0, g=0, b=0):
    for y in range(height):
        for x in range(width):
            draw_pixel(fb_mmap, x, y, r, g, b, width, height, bpp)

def draw_rect(fb_mmap, x, y, w, h, r, g, b, width, height, bpp):
    for py in range(y, min(y+h, height)):
        for px in range(x, min(x+w, width)):
            draw_pixel(fb_mmap, px, py, r, g, b, width, height, bpp)

def main():
    width, height, bpp = get_fb_info()
    print(f'Framebuffer: {width}x{height}, {bpp} bpp')
    
    with open(FB_DEV, 'r+b') as fb:
        fb_size = width * height * (bpp // 8)
        fb_mmap = mmap.mmap(fb.fileno(), fb_size, access=mmap.ACCESS_WRITE)
        
        try:
            frame = 0
            while True:
                # Clear to black
                clear_screen(fb_mmap, width, height, bpp, 0, 0, 0)
                
                # Draw animated pattern
                center_x, center_y = width // 2, height // 2
                size = 50 + int(30 * (frame % 60) / 60)
                color = (frame * 4) % 255
                
                draw_rect(fb_mmap, center_x - size//2, center_y - size//2, 
                         size, size, color, 255-color, 128, width, height, bpp)
                
                # Draw border
                draw_rect(fb_mmap, 10, 10, width-20, 5, 0, 255, 0, width, height, bpp)
                draw_rect(fb_mmap, 10, height-15, width-20, 5, 0, 255, 0, width, height, bpp)
                draw_rect(fb_mmap, 10, 10, 5, height-20, 0, 255, 0, width, height, bpp)
                draw_rect(fb_mmap, width-15, 10, 5, height-20, 0, 255, 0, width, height, bpp)
                
                fb_mmap.flush()
                frame += 1
                time.sleep(0.1)
                
        except KeyboardInterrupt:
            pass
        finally:
            fb_mmap.close()

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
echo "1. Config.txt manuell anpassen (siehe FRESH_INSTALL_PLAN.md)"
echo "2. Reboot durchführen"
echo "3. Test: sudo python3 /home/andre/fb_display.py"
echo "4. Aktivieren: sudo systemctl enable fb_display.service"
echo ""

