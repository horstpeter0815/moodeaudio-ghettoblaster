#!/bin/bash
# COMPLETE DISPLAY FIX - Final Implementation
# Following Project Plan: Day 1 Morning - System Recovery

echo "=========================================="
echo "COMPLETE DISPLAY FIX - FINAL"
echo "Date: $(date)"
echo "=========================================="
echo ""

# System 2: Final fix with restart
echo "=== SYSTEM 2: FINAL FIX & RESTART ==="
ssh pi2 << 'EOF'
echo "1. Stopping service..."
sudo systemctl stop localdisplay
sleep 2

echo "2. Killing all processes..."
sudo pkill -9 chromium Xorg xinit 2>/dev/null || true
sleep 2

echo "3. Restarting service..."
sudo systemctl start localdisplay
echo "Service started. Waiting 15 seconds for full initialization..."
sleep 15
EOF

sleep 2
echo ""
echo "Checking System 2:"
ssh pi2 "export DISPLAY=:0 && ps aux | grep chromium | grep -v grep | wc -l | xargs echo 'Chromium processes:' && xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1 || echo 'Checking...'"

echo ""
echo "=== SYSTEM 3: FINAL FIX & RESTART ==="
ssh pi3 << 'EOF'
echo "1. Stopping service..."
sudo systemctl stop localdisplay
sleep 2

echo "2. Killing all processes..."
sudo pkill -9 chromium Xorg xinit 2>/dev/null || true
sleep 2

echo "3. Restarting service..."
sudo systemctl start localdisplay
echo "Service started. Waiting 15 seconds for full initialization..."
sleep 15
EOF

sleep 2
echo ""
echo "Checking System 3:"
ssh pi3 "export DISPLAY=:0 && ps aux | grep chromium | grep -v grep | wc -l | xargs echo 'Chromium processes:' && xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1 || echo 'Checking...'"

echo ""
echo "=========================================="
echo "FIX COMPLETE - PLEASE CHECK DISPLAYS"
echo "=========================================="

