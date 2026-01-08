#!/bin/bash
# Visualizer EINschalten
# Stoppt normales Interface und startet Visualizer

echo "Switching to Visualizer mode..."

# Stoppe normales Interface
systemctl stop cog.service 2>/dev/null

# Starte Visualizer-Service
systemctl start audio-visualizer.service

# Warte kurz
sleep 2

# Starte Visualizer-Browser
systemctl start cog-visualizer.service

echo "Visualizer is now active"
echo "To switch back: /opt/hifiberry/bin/visualizer-off.sh"

