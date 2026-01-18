#!/bin/bash
# Hält alle Systeme wach und verhindert Sleep-Modus

echo "=== SYSTEME WACHHALTEN ==="
echo "Datum: $(date)"
echo ""

# System 1: HiFiBerryOS Pi 4
echo "System 1 (HiFiBerryOS Pi 4):"
if sshpass -p 'hifiberry' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 root@192.168.178.199 "hostname && systemctl is-active weston" 2>&1 | grep -q "."; then
    echo "✅ Online - Halte wach..."
    sshpass -p 'hifiberry' ssh -o StrictHostKeyChecking=no root@192.168.178.199 "systemctl disable sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; echo 'Sleep deaktiviert'" 2>&1
    sshpass -p 'hifiberry' ssh -o StrictHostKeyChecking=no root@192.168.178.199 "uptime && systemctl is-active weston cog" 2>&1
else
    echo "❌ Offline"
fi
echo ""

# System 2: moOde Pi 5
echo "System 2 (moOde Pi 5):"
if ./pi5-ssh.sh "hostname" >/dev/null 2>&1; then
    echo "✅ Online - Halte wach..."
    ./pi5-ssh.sh "sudo systemctl disable sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; echo 'Sleep deaktiviert'" 2>&1
    ./pi5-ssh.sh "uptime && systemctl is-active mpd localdisplay" 2>&1
else
    echo "❌ Offline"
fi
echo ""

# System 3: moOde Pi 4
echo "System 3 (moOde Pi 4):"
if ./pi4-ssh.sh "hostname" >/dev/null 2>&1; then
    echo "✅ Online - Halte wach..."
    ./pi4-ssh.sh "sudo systemctl disable sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; echo 'Sleep deaktiviert'" 2>&1
    ./pi4-ssh.sh "uptime && systemctl is-active mpd localdisplay" 2>&1
else
    echo "❌ Offline"
fi
echo ""

echo "=== FERTIG ==="





