#!/usr/bin/env python3
################################################################################
#
# PeppyMeter Extended Displays
#
# - Overlay für PeppyMeter mit Temperatur und Stream-Info
# - Umschaltbar zwischen Power Meter und Info-Displays
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

import pygame
import sys
import os
import time
import json
import subprocess
import threading
from datetime import datetime

# Display-Konfiguration
DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 400
DISPLAY = ":0"

# Farben
COLOR_BLACK = (0, 0, 0)
COLOR_WHITE = (255, 255, 255)
COLOR_GREEN = (0, 255, 0)
COLOR_YELLOW = (255, 255, 0)
COLOR_RED = (255, 0, 0)
COLOR_BLUE = (0, 0, 255)
COLOR_GRAY = (128, 128, 128)

# Temperatur-Bereiche
TEMP_GREEN_MAX = 60
TEMP_YELLOW_MAX = 70

# Display-Modi
MODE_POWER_METER = "power"
MODE_TEMPERATURE = "temperature"
MODE_STREAM_INFO = "stream"

class ExtendedDisplays:
    def __init__(self):
        self.display_mode_1 = MODE_POWER_METER  # Control Display 1
        self.display_mode_2 = MODE_POWER_METER   # Control Display 2
        self.switch_interval = 10  # Sekunden zwischen automatischem Umschalten
        self.last_switch_time = time.time()
        self.touch_enabled = True
        self.peppymeter_enabled = True  # PeppyMeter on/off state
        
        # Touch gesture detection
        self.last_tap_time = 0
        self.tap_timeout = 0.5  # 500ms for double tap detection
        self.tap_count = 0
        self.last_tap_position = None
        self.tap_position_threshold = 50  # pixels - max distance for double tap
        self.touch_down_time = 0  # Track touch duration for single tap detection
        
        # Pygame initialisieren
        os.environ['DISPLAY'] = DISPLAY
        pygame.init()
        self.screen = pygame.display.set_mode((DISPLAY_WIDTH, DISPLAY_HEIGHT), pygame.NOFRAME)
        pygame.display.set_caption("PeppyMeter Extended")
        
        # Font initialisieren
        self.font_large = pygame.font.Font(None, 72)
        self.font_medium = pygame.font.Font(None, 48)
        self.font_small = pygame.font.Font(None, 36)
        
        # Transparentes Overlay
        self.overlay = pygame.Surface((DISPLAY_WIDTH, DISPLAY_HEIGHT))
        self.overlay.set_alpha(200)  # Semi-transparent
        
        # Thread für Daten-Sammlung
        self.data = {
            'temperature': 0.0,
            'temperature_color': COLOR_GREEN,
            'sample_rate': 0,
            'sample_rate_display': 'N/A',
            'bit_depth': 0,
            'format': 'N/A',
            'oversampling': 'N/A'
        }
        self.data_lock = threading.Lock()
        self.running = True
        
        # Starte Daten-Sampler Thread
        self.data_thread = threading.Thread(target=self.update_data, daemon=True)
        self.data_thread.start()
    
    def get_cpu_temperature(self):
        """Liest CPU-Temperatur in °C"""
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp_millidegrees = int(f.read().strip())
                temp_celsius = temp_millidegrees / 1000.0
                return temp_celsius
        except:
            return 0.0
    
    def get_temperature_color(self, temp):
        """Bestimmt Farbe basierend auf Temperatur"""
        if temp < TEMP_GREEN_MAX:
            return COLOR_GREEN
        elif temp < TEMP_YELLOW_MAX:
            return COLOR_YELLOW
        else:
            return COLOR_RED
    
    def get_stream_info(self):
        """Liest Stream-Informationen von MPD"""
        try:
            # Sample Rate von MPD
            result = subprocess.run(
                ['mpc', 'status', '-f', '%samplerate%'],
                capture_output=True,
                text=True,
                timeout=1
            )
            if result.returncode == 0:
                sample_rate = int(result.stdout.strip())
                sample_rate_display = f"{sample_rate // 1000} kHz" if sample_rate >= 1000 else f"{sample_rate} Hz"
            else:
                sample_rate = 0
                sample_rate_display = 'N/A'
            
            # Bit Depth von MPD
            result = subprocess.run(
                ['mpc', 'status', '-f', '%bitdepth%'],
                capture_output=True,
                text=True,
                timeout=1
            )
            if result.returncode == 0:
                bit_depth = int(result.stdout.strip())
            else:
                bit_depth = 0
            
            # Format-String
            if sample_rate > 0 and bit_depth > 0:
                format_str = f"{sample_rate_display} / {bit_depth}-bit"
            else:
                format_str = 'N/A'
            
            # Oversampling (vereinfacht: Sample Rate / 44.1 kHz)
            if sample_rate > 0:
                oversampling = sample_rate / 44100.0
                if oversampling >= 1.0:
                    oversampling_display = f"{oversampling:.1f}x"
                else:
                    oversampling_display = "N/A"
            else:
                oversampling_display = "N/A"
            
            return {
                'sample_rate': sample_rate,
                'sample_rate_display': sample_rate_display,
                'bit_depth': bit_depth,
                'format': format_str,
                'oversampling': oversampling_display
            }
        except:
            return {
                'sample_rate': 0,
                'sample_rate_display': 'N/A',
                'bit_depth': 0,
                'format': 'N/A',
                'oversampling': 'N/A'
            }
    
    def update_data(self):
        """Aktualisiert Daten kontinuierlich"""
        while self.running:
            # Temperatur
            temp = self.get_cpu_temperature()
            temp_color = self.get_temperature_color(temp)
            
            # Stream-Info
            stream_info = self.get_stream_info()
            
            # Update shared data
            with self.data_lock:
                self.data['temperature'] = temp
                self.data['temperature_color'] = temp_color
                self.data.update(stream_info)
            
            time.sleep(1)  # Update alle Sekunde
    
    def draw_temperature_display(self, x, y, width, height):
        """Zeichnet Temperatur-Display"""
        # Hintergrund
        pygame.draw.rect(self.overlay, COLOR_BLACK, (x, y, width, height))
        pygame.draw.rect(self.overlay, COLOR_WHITE, (x, y, width, height), 2)
        
        # Titel
        title = self.font_small.render("CPU Temp", True, COLOR_WHITE)
        self.overlay.blit(title, (x + 10, y + 10))
        
        # Temperatur-Wert
        with self.data_lock:
            temp = self.data['temperature']
            temp_color = self.data['temperature_color']
        
        temp_text = self.font_large.render(f"{temp:.1f}°C", True, temp_color)
        text_rect = temp_text.get_rect(center=(x + width // 2, y + height // 2 - 20))
        self.overlay.blit(temp_text, text_rect)
        
        # Temperatur-Balken
        bar_width = width - 40
        bar_height = 20
        bar_x = x + 20
        bar_y = y + height - 40
        
        # Hintergrund-Balken
        pygame.draw.rect(self.overlay, COLOR_GRAY, (bar_x, bar_y, bar_width, bar_height))
        
        # Füll-Balken (0-100°C)
        fill_width = int((temp / 100.0) * bar_width)
        if fill_width > bar_width:
            fill_width = bar_width
        
        pygame.draw.rect(self.overlay, temp_color, (bar_x, bar_y, fill_width, bar_height))
        
        # Skala
        for i in range(0, 101, 20):
            scale_x = bar_x + int((i / 100.0) * bar_width)
            pygame.draw.line(self.overlay, COLOR_WHITE, (scale_x, bar_y - 5), (scale_x, bar_y + bar_height + 5), 1)
            scale_text = self.font_small.render(f"{i}", True, COLOR_WHITE)
            self.overlay.blit(scale_text, (scale_x - 10, bar_y - 25))
    
    def draw_stream_info_display(self, x, y, width, height):
        """Zeichnet Stream-Info-Display"""
        # Hintergrund
        pygame.draw.rect(self.overlay, COLOR_BLACK, (x, y, width, height))
        pygame.draw.rect(self.overlay, COLOR_WHITE, (x, y, width, height), 2)
        
        # Titel
        title = self.font_small.render("Stream Info", True, COLOR_WHITE)
        self.overlay.blit(title, (x + 10, y + 10))
        
        # Stream-Daten
        with self.data_lock:
            sample_rate = self.data['sample_rate_display']
            format_str = self.data['format']
            oversampling = self.data['oversampling']
        
        # Sample Rate
        sample_text = self.font_medium.render(sample_rate, True, COLOR_GREEN)
        self.overlay.blit(sample_text, (x + 20, y + 60))
        
        # Format
        format_text = self.font_small.render(format_str, True, COLOR_WHITE)
        self.overlay.blit(format_text, (x + 20, y + 110))
        
        # Oversampling
        oversampling_label = self.font_small.render("Oversampling:", True, COLOR_WHITE)
        self.overlay.blit(oversampling_label, (x + 20, y + 150))
        
        oversampling_text = self.font_medium.render(oversampling, True, COLOR_BLUE)
        self.overlay.blit(oversampling_text, (x + 20, y + 190))
    
    def handle_touch_down(self, pos):
        """Behandelt Touchscreen-Down Event"""
        if not self.touch_enabled:
            return
        
        self.touch_down_time = time.time()
        x, y = pos
        current_time = time.time()
        
        # Check for double tap
        if current_time - self.last_tap_time < self.tap_timeout:
            if self.last_tap_position and \
               abs(x - self.last_tap_position[0]) < self.tap_position_threshold and \
               abs(y - self.last_tap_position[1]) < self.tap_position_threshold:
                self.tap_count += 1
                if self.tap_count == 2:
                    # Double tap detected - switch mode
                    self.tap_count = 0
                    self.last_tap_time = 0
                    self.last_tap_position = None
                    
                    # Control Display 1 Bereich (linke Hälfte)
                    if x < DISPLAY_WIDTH // 2:
                        if self.display_mode_1 == MODE_POWER_METER:
                            self.display_mode_1 = MODE_TEMPERATURE
                        else:
                            self.display_mode_1 = MODE_POWER_METER
                        print(f"Double tap detected - Left display mode switched to: {self.display_mode_1}")
                    else:
                        if self.display_mode_2 == MODE_POWER_METER:
                            self.display_mode_2 = MODE_STREAM_INFO
                        else:
                            self.display_mode_2 = MODE_POWER_METER
                        print(f"Double tap detected - Right display mode switched to: {self.display_mode_2}")
                    self.last_switch_time = time.time()
                    return
        
        # Reset tap count if timeout exceeded
        self.tap_count = 1
        self.last_tap_time = current_time
        self.last_tap_position = (x, y)
    
    def handle_touch_up(self, pos):
        """Behandelt Touchscreen-Up Event (Single Tap Detection)"""
        if not self.touch_enabled:
            return
        
        current_time = time.time()
        # If tap was very brief (< 200ms), it's a single tap (not double tap)
        if self.touch_down_time > 0 and (current_time - self.touch_down_time) < 0.2:
            # Check if this was NOT a double tap (enough time has passed)
            if current_time - self.last_tap_time > self.tap_timeout or self.tap_count == 1:
                # Single quick tap - toggle PeppyMeter
                self.peppymeter_enabled = not self.peppymeter_enabled
                if self.peppymeter_enabled:
                    print("PeppyMeter ENABLED (single tap detected)")
                    try:
                        subprocess.run(['systemctl', 'start', 'peppymeter.service'], 
                                     capture_output=True, text=True, timeout=2)
                    except:
                        pass
                else:
                    print("PeppyMeter DISABLED (single tap detected)")
                    try:
                        subprocess.run(['systemctl', 'stop', 'peppymeter.service'], 
                                     capture_output=True, text=True, timeout=2)
                    except:
                        pass
                self.tap_count = 0
                self.last_tap_time = 0
                self.touch_down_time = 0
    
    def check_auto_switch(self):
        """Prüft ob automatisches Umschalten nötig ist"""
        current_time = time.time()
        if current_time - self.last_switch_time >= self.switch_interval:
            # Automatisches Umschalten
            if self.display_mode_1 == MODE_POWER_METER:
                self.display_mode_1 = MODE_TEMPERATURE
            else:
                self.display_mode_1 = MODE_POWER_METER
            
            if self.display_mode_2 == MODE_POWER_METER:
                self.display_mode_2 = MODE_STREAM_INFO
            else:
                self.display_mode_2 = MODE_POWER_METER
            
            self.last_switch_time = current_time
    
    def run(self):
        """Haupt-Loop"""
        clock = pygame.time.Clock()
        
        while self.running:
            # Events verarbeiten
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    self.handle_touch_down(event.pos)
                elif event.type == pygame.MOUSEBUTTONUP:
                    self.handle_touch_up(event.pos)
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        self.running = False
            
            # Automatisches Umschalten prüfen (nur wenn PeppyMeter enabled)
            if self.peppymeter_enabled:
                self.check_auto_switch()
            
            # Overlay leeren
            self.overlay.fill((0, 0, 0, 0))
            
            # Show disabled message if PeppyMeter is off
            if not self.peppymeter_enabled:
                disabled_text = self.font_large.render("PeppyMeter DISABLED", True, COLOR_WHITE)
                disabled_rect = disabled_text.get_rect(center=(DISPLAY_WIDTH // 2, DISPLAY_HEIGHT // 2 - 30))
                self.overlay.blit(disabled_text, disabled_rect)
                
                tap_text = self.font_medium.render("Tap once to enable", True, COLOR_GRAY)
                tap_rect = tap_text.get_rect(center=(DISPLAY_WIDTH // 2, DISPLAY_HEIGHT // 2 + 30))
                self.overlay.blit(tap_text, tap_rect)
            else:
                # Control Display 1 (links)
                if self.display_mode_1 == MODE_TEMPERATURE:
                    self.draw_temperature_display(10, 10, DISPLAY_WIDTH // 2 - 20, DISPLAY_HEIGHT - 20)
                
                # Control Display 2 (rechts)
                if self.display_mode_2 == MODE_STREAM_INFO:
                    self.draw_stream_info_display(DISPLAY_WIDTH // 2 + 10, 10, DISPLAY_WIDTH // 2 - 20, DISPLAY_HEIGHT - 20)
            
            # Overlay auf Screen blitten
            self.screen.blit(self.overlay, (0, 0))
            pygame.display.flip()
            
            clock.tick(30)  # 30 FPS
        
        pygame.quit()

if __name__ == "__main__":
    try:
        displays = ExtendedDisplays()
        displays.run()
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

