#!/bin/bash
# Repariert alle Display-Probleme

echo "=== DISPLAY-REPARATUR ALLER SYSTEME ==="

# System 1: HiFiBerryOS
echo "System 1 (HiFiBerryOS):"
sshpass -p 'hifiberry' ssh -o StrictHostKeyChecking=no root@192.168.178.101 << 'EOF'
# Prüfe Weston Config
if [ -f /etc/xdg/weston/weston.ini ]; then
    echo "Weston Config prüfen..."
    grep -A 10 "\[output\]" /etc/xdg/weston/weston.ini
fi

# Prüfe Display Mode
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "FB nicht verfügbar"
EOF

# System 2: moOde Pi 5
echo ""
echo "System 2 (moOde Pi 5):"
./pi5-ssh.sh << 'EOF'
# Prüfe X11 Display
DISPLAY=:0 xrandr 2>/dev/null | head -10 || echo "X11 nicht verfügbar"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "FB nicht verfügbar"
EOF

# System 3: moOde Pi 4
echo ""
echo "System 3 (moOde Pi 4):"
./pi4-ssh.sh << 'EOF'
# Prüfe X11 Display
DISPLAY=:0 xrandr 2>/dev/null | head -10 || echo "X11 nicht verfügbar"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "FB nicht verfügbar"
EOF





