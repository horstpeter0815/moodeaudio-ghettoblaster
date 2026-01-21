#!/usr/bin/env python3
"""
PeppyMeter Swipe Gesture Wrapper
Adds swipe up/down detection to toggle between PeppyMeter and moOde UI
"""

import pygame
import subprocess
import sys
import os
import time
import signal

# Display configuration
DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 400
SWIPE_MIN_DISTANCE = 100  # Minimum vertical distance for swipe
SWIPE_MAX_TIME = 0.8      # Maximum time for swipe (seconds)

class SwipeDetector:
    def __init__(self):
        self.touch_start_pos = None
        self.touch_start_time = None
        self.peppymeter_process = None
        
        # Initialize Pygame for touch detection
        os.environ['DISPLAY'] = ':0'
        pygame.init()
        
        # Create transparent overlay window for touch detection
        self.screen = pygame.display.set_mode((DISPLAY_WIDTH, DISPLAY_HEIGHT), 
                                              pygame.NOFRAME | pygame.FULLSCREEN)
        pygame.display.set_caption("Swipe Detector")
        
        # Make window transparent/invisible (shows PeppyMeter underneath)
        self.screen.set_alpha(1)  # Almost fully transparent
        self.screen.fill((0, 0, 0, 0))
        
        print("Swipe gesture detector initialized")
        print("Swipe UP or DOWN to toggle between PeppyMeter and moOde UI")
    
    def start_peppymeter(self):
        """Launch PeppyMeter process"""
        try:
            if os.path.exists("/opt/peppymeter/peppymeter.py"):
                print("Starting PeppyMeter...")
                self.peppymeter_process = subprocess.Popen(
                    ['python3', '/opt/peppymeter/peppymeter.py'],
                    cwd='/opt/peppymeter',
                    env={**os.environ, 'DISPLAY': ':0'},
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                return True
        except Exception as e:
            print(f"Error starting PeppyMeter: {e}")
        return False
    
    def stop_peppymeter(self):
        """Stop PeppyMeter process"""
        if self.peppymeter_process:
            try:
                print("Stopping PeppyMeter...")
                self.peppymeter_process.terminate()
                self.peppymeter_process.wait(timeout=3)
            except:
                try:
                    self.peppymeter_process.kill()
                except:
                    pass
            self.peppymeter_process = None
    
    def toggle_to_moode_ui(self):
        """Toggle from PeppyMeter to moOde UI"""
        print("\n=== SWIPE DETECTED: Switching to moOde UI ===")
        
        try:
            # Update database: peppy_display = 0
            subprocess.run([
                'sqlite3', 
                '/var/local/www/db/moode-sqlite3.db',
                "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
            ], timeout=5, check=True)
            
            print("Database updated: peppy_display=0")
            
            # Stop PeppyMeter
            self.stop_peppymeter()
            
            # Restart localdisplay service to show moOde UI
            subprocess.run(['sudo', 'systemctl', 'restart', 'localdisplay'], 
                         timeout=10, check=True)
            
            print("Switching to moOde UI...")
            time.sleep(2)
            
            # Exit this script (localdisplay will restart with Chromium)
            sys.exit(0)
            
        except Exception as e:
            print(f"Error toggling to moOde UI: {e}")
    
    def detect_swipe(self, start_pos, end_pos, duration):
        """
        Detect if movement is a vertical swipe
        Returns: 'up', 'down', or None
        """
        if not start_pos or not end_pos:
            return None
        
        dx = end_pos[0] - start_pos[0]
        dy = end_pos[1] - start_pos[1]
        
        # Check if movement is primarily vertical
        if abs(dy) < SWIPE_MIN_DISTANCE:
            return None
        
        # Check if swipe was fast enough
        if duration > SWIPE_MAX_TIME:
            return None
        
        # Check if vertical movement dominates horizontal
        if abs(dy) < abs(dx) * 1.5:  # Must be more vertical than horizontal
            return None
        
        # Determine direction
        if dy < 0:
            return 'up'
        else:
            return 'down'
    
    def run(self):
        """Main loop"""
        # Start PeppyMeter
        if not self.start_peppymeter():
            print("Failed to start PeppyMeter")
            return
        
        clock = pygame.time.Clock()
        running = True
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                
                elif event.type == pygame.KEYDOWN:
                    # Escape key to exit
                    if event.key == pygame.K_ESCAPE:
                        print("Escape pressed - exiting")
                        running = False
                
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    # Touch down - record starting position
                    self.touch_start_pos = event.pos
                    self.touch_start_time = time.time()
                    print(f"Touch down at: {event.pos}")
                
                elif event.type == pygame.MOUSEBUTTONUP:
                    # Touch up - check for swipe
                    if self.touch_start_pos and self.touch_start_time:
                        touch_end_pos = event.pos
                        duration = time.time() - self.touch_start_time
                        
                        swipe = self.detect_swipe(
                            self.touch_start_pos, 
                            touch_end_pos, 
                            duration
                        )
                        
                        if swipe:
                            print(f"SWIPE {swipe.upper()} detected! (distance: {abs(touch_end_pos[1] - self.touch_start_pos[1])}px, duration: {duration:.2f}s)")
                            # Any vertical swipe (up or down) toggles to moOde UI
                            self.toggle_to_moode_ui()
                            running = False
                        else:
                            print(f"Touch released at: {touch_end_pos} (no swipe detected)")
                        
                        # Reset
                        self.touch_start_pos = None
                        self.touch_start_time = None
            
            # Keep overlay transparent
            self.screen.fill((0, 0, 0, 0))
            pygame.display.flip()
            
            # Check if PeppyMeter is still running
            if self.peppymeter_process and self.peppymeter_process.poll() is not None:
                print("PeppyMeter process ended")
                running = False
            
            clock.tick(30)  # 30 FPS
        
        # Cleanup
        self.stop_peppymeter()
        pygame.quit()

def signal_handler(sig, frame):
    """Handle termination signals"""
    print("\nReceived termination signal")
    sys.exit(0)

if __name__ == "__main__":
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        detector = SwipeDetector()
        detector.run()
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
