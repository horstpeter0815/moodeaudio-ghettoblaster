#!/bin/bash
# Aktive Reparatur aller Systeme

echo "=== AKTIVE SYSTEM-REPARATUR ==="
echo "Datum: $(date)"
echo ""

# SYSTEM 1: HiFiBerryOS Pi 4
echo "=== SYSTEM 1: HiFiBerryOS Pi 4 (192.168.178.199) ==="
if ping -c 1 -W 2000 192.168.178.199 >/dev/null 2>&1; then
    echo "✅ Online - Prüfe Status..."
    sshpass -p 'hifiberry' ssh -o StrictHostKeyChecking=no root@192.168.178.199 "hostname && systemctl is-active weston cog audio-visualizer" 2>&1
else
    echo "❌ Offline"
    echo "→ Bitte prüfen: Ist das System eingeschaltet?"
fi
echo ""

# SYSTEM 2: moOde Pi 5
echo "=== SYSTEM 2: moOde Pi 5 (192.168.178.134) ==="
if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
    echo "✅ Online - Prüfe und repariere Services..."
    ./fix-pi5-boot-services.sh
else
    echo "❌ Offline - Analysiere mögliche Service-Probleme..."
    echo ""
    echo "⚠️  Problem-Services identifiziert:"
    echo "  - config-validate.service (kein Timeout)"
    echo "  - set-mpd-volume.service (könnte hängen)"
    echo ""
    echo "→ Reparatur-Script vorbereitet: fix-pi5-boot-services.sh"
fi
echo ""

# SYSTEM 3: moOde Pi 4
echo "=== SYSTEM 3: moOde Pi 4 (moodepi4) ==="
IP=$(ping -c 1 -W 2000 moodepi4.local 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$IP" ]; then
    echo "✅ Online ($IP) - Starte Setup..."
    if [ ! -f .pi4_ip ]; then
        echo "$IP" > .pi4_ip
        ./setup-pi4-ssh.sh
    fi
    echo ""
    echo "Prüfe System..."
    ./pi4-ssh.sh "hostname && cat /etc/os-release | head -3" 2>&1
else
    echo "⏳ Noch nicht im Netzwerk"
    echo "→ Bitte Pi 4 booten"
fi
echo ""

echo "=== ZUSAMMENFASSUNG ==="
echo "System 1: $(ping -c 1 -W 1000 192.168.178.199 >/dev/null 2>&1 && echo '✅ Online' || echo '❌ Offline')"
echo "System 2: $(ping -c 1 -W 1000 192.168.178.134 >/dev/null 2>&1 && echo '✅ Online' || echo '❌ Offline')"
echo "System 3: $([ -n "$(ping -c 1 -W 1000 moodepi4.local 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)" ] && echo '✅ Online' || echo '⏳ Offline')"
