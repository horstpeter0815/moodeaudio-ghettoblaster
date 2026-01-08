#!/bin/bash
# Visualizer AUSschalten
# Stoppt Visualizer und startet normales Interface

echo "Switching back to normal interface..."

# Stoppe Visualizer-Browser
systemctl stop cog-visualizer.service

# Stoppe Visualizer-Service (optional - kann laufen bleiben)
# systemctl stop audio-visualizer.service

# Starte normales Interface
systemctl start cog.service

echo "Normal interface is now active"
echo "To switch to visualizer: /opt/hifiberry/bin/visualizer-on.sh"

