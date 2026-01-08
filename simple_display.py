#!/usr/bin/env python3
"""
Simple Display Tool - Direct Framebuffer Access
Shows a test pattern on the display via framebuffer
"""
import os
import struct
import time

FB_DEVICE = "/dev/fb0"
WIDTH = 1280
HEIGHT = 400
BYTES_PER_PIXEL = 4  # ARGB32

def write_framebuffer():
    """Write test pattern to framebuffer"""
    try:
        fb = open(FB_DEVICE, "wb")
        
        # Test pattern: gradient
        for y in range(HEIGHT):
            for x in range(WIDTH):
                # Create gradient pattern
                r = int((x / WIDTH) * 255) & 0xFF
                g = int((y / HEIGHT) * 255) & 0xFF
                b = 128
                a = 255
                
                # ARGB32 format: AARRGGBB
                pixel = struct.pack("I", (a << 24) | (r << 16) | (g << 8) | b)
                fb.write(pixel)
        
        fb.close()
        print(f"Wrote {WIDTH}x{HEIGHT} test pattern to {FB_DEVICE}")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Need root to write to framebuffer")
        exit(1)
    
    print("Writing test pattern to framebuffer...")
    write_framebuffer()
    print("Done. Pattern should be visible on display.")

