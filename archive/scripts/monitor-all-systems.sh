#!/bin/bash
# Kontinuierliche Überwachung aller 3 Systeme

echo "=== KONTINUIERLICHE SYSTEM-ÜBERWACHUNG ==="
echo "Start: $(date)"
echo ""

while true; do
    echo "$(date): Prüfe alle Systeme..."
    
    # System 1: HiFiBerryOS Pi 4
    if sshpass -p 'hifiberry' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 root@192.168.178.199 "hostname" 2>/dev/null | grep -q "."; then
        echo "✅ HiFiBerryOS Pi 4: Online"
    else
        echo "⏳ HiFiBerryOS Pi 4: Offline"
    fi
    
    # System 2: moOde Pi 5
    if ./pi5-ssh.sh "hostname" 2>&1 | grep -q "GhettoPi4"; then
        echo "✅ moOde Pi 5: Online"
        # Führe Prüfung durch
        ./pi5-ssh.sh "systemctl is-active mpd localdisplay set-mpd-volume config-validate && mpc volume" 2>&1 | head -5
    else
        echo "⏳ moOde Pi 5: Offline"
    fi
    
    # System 3: moOde Pi 4
    IP=$(ping -c 1 -W 1000 "moodepi4.local" 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
    if [ -n "$IP" ]; then
        echo "✅ moOde Pi 4: Online ($IP)"
        if [ ! -f .pi4_ip ]; then
            echo "$IP" > .pi4_ip
            echo "  → Starte SSH-Setup..."
            ./setup-pi4-ssh.sh
        fi
    else
        echo "⏳ moOde Pi 4: Offline"
    fi
    
    echo ""
    sleep 60
done

