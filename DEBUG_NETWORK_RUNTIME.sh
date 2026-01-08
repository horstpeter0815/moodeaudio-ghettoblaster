#!/bin/bash
# Debug Network Runtime - Sammelt Runtime-Evidence vom Pi
# Verstehen WARUM NetworkManager fehlschlägt

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 DEBUG NETWORK RUNTIME                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PI_IP="192.168.10.2"

echo "📋 Prüfe ob Pi online ist..."
if ! timeout 2 ping -c 1 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi ist nicht online: $PI_IP"
    echo "   Bitte Pi booten und warten bis online"
    exit 1
fi

echo "✅ Pi ist online: $PI_IP"
echo ""

echo "🔍 Sammle Runtime-Evidence..."
echo ""

# NetworkManager Status
echo "=== NetworkManager Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status NetworkManager --no-pager -l" 2>/dev/null || echo "⚠️  Konnte Status nicht abrufen"
echo ""

# NetworkManager Logs
echo "=== NetworkManager Logs (letzte 30 Zeilen) ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "journalctl -u NetworkManager --no-pager -n 30" 2>/dev/null || echo "⚠️  Konnte Logs nicht abrufen"
echo ""

# systemd-networkd Status
echo "=== systemd-networkd Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status systemd-networkd --no-pager -l" 2>/dev/null || echo "⚠️  systemd-networkd nicht aktiv"
echo ""

# Netplan Config
echo "=== Netplan Configuration ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "cat /etc/netplan/*.yaml 2>/dev/null || echo 'Keine Netplan Config gefunden'" 2>/dev/null || echo "⚠️  Konnte Netplan nicht prüfen"
echo ""

# Network Interfaces
echo "=== Network Interfaces ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "ip addr show" 2>/dev/null || echo "⚠️  Konnte Interfaces nicht prüfen"
echo ""

# Active Jobs
echo "=== Active Systemd Jobs ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl list-jobs" 2>/dev/null || echo "⚠️  Konnte Jobs nicht abrufen"
echo ""

# network-guaranteed.service Status
echo "=== network-guaranteed.service Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status network-guaranteed.service --no-pager -l" 2>/dev/null || echo "⚠️  network-guaranteed.service nicht gefunden"
echo ""

echo "✅ Runtime-Evidence gesammelt!"
echo ""
echo "📋 Analysiere diese Logs um zu verstehen:"
echo "  • WARUM schlägt NetworkManager fehl?"
echo "  • Gibt es einen Konflikt mit systemd-networkd?"
echo "  • Was ist die genaue Fehlermeldung?"
echo ""

