#!/usr/bin/env python3
"""
Simple Display Manager - Continuous framebuffer display
Shows system info and test pattern on display
"""
import os
import struct
import time
import subprocess
from datetime import datetime

FB_DEVICE = "/dev/fb0"
WIDTH = 1280
HEIGHT = 400
BYTES_PER_PIXEL = 4  # ARGB32

def get_fb_size():
    """Get actual framebuffer size"""
    try:
        with open("/sys/class/graphics/fb0/virtual_size", "r") as f:
            size = f.read().strip()
            w, h = map(int, size.split(","))
            return w, h
    except:
        return WIDTH, HEIGHT

def write_pixel(fb, x, y, r, g, b, a=255):
    """Write a single pixel"""
    pixel = struct.pack("I", (a << 24) | (r << 16) | (g << 8) | b)
    fb.seek((y * WIDTH + x) * BYTES_PER_PIXEL)
    fb.write(pixel)

def clear_screen(fb, r=0, g=0, b=0):
    """Clear screen with color"""
    pixel = struct.pack("I", (255 << 24) | (r << 16) | (g << 8) | b)
    for _ in range(WIDTH * HEIGHT):
        fb.write(pixel)

def draw_text_simple(fb, text, x, y, r=255, g=255, b=255):
    """Simple text rendering - just draw pixels for now"""
    # Very basic - just show text position
    for i, char in enumerate(text[:50]):  # Limit to 50 chars
        # Simple 8x8 font simulation
        for py in range(8):
            for px in range(8):
                if (ord(char) + px + py) % 3 == 0:  # Simple pattern
                    write_pixel(fb, x + i*8 + px, y + py, r, g, b)

def main():
    if os.geteuid() != 0:
        print("Need root to write to framebuffer")
        exit(1)
    
    # Get actual framebuffer size
    fb_width, fb_height = get_fb_size()
    print(f"Framebuffer size: {fb_width}x{fb_height}")
    
    try:
        fb = open(FB_DEVICE, "wb")
        
        frame = 0
        while True:
            # Clear screen
            clear_screen(fb, 20, 20, 40)
            
            # Draw gradient background
            for y in range(min(HEIGHT, fb_height)):
                for x in range(min(WIDTH, fb_width)):
                    r = int((x / WIDTH) * 100) & 0xFF
                    g = int((y / HEIGHT) * 100) & 0xFF
                    b = int((frame % 255))
                    pixel = struct.pack("I", (255 << 24) | (r << 16) | (g << 8) | b)
                    fb.seek((y * fb_width + x) * BYTES_PER_PIXEL)
                    fb.write(pixel)
            
            fb.flush()
            frame += 1
            time.sleep(0.1)  # 10 FPS
            
    except KeyboardInterrupt:
        print("\nStopping...")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'fb' in locals():
            fb.close()

if __name__ == "__main__":
    main()

