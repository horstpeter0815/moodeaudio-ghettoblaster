#!/bin/bash
# Debug NetworkManager-wait-online Failure
# Sammelt Runtime-Evidence vom Pi

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 DEBUG NETWORKMANAGER-WAIT-ONLINE                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PI_IP="192.168.10.2"

echo "📋 Prüfe ob Pi online ist..."
if ! timeout 2 ping -c 1 "$PI_IP" >/dev/null 2>&1; then
    echo "❌ Pi ist nicht online: $PI_IP"
    echo "   Versuche 192.168.178.162..."
    PI_IP="192.168.178.162"
    if ! timeout 2 ping -c 1 "$PI_IP" >/dev/null 2>&1; then
        echo "❌ Pi ist nicht online"
        echo "   Bitte Pi booten und warten bis online"
        exit 1
    fi
fi

echo "✅ Pi ist online: $PI_IP"
echo ""

echo "🔍 Sammle Runtime-Evidence..."
echo ""

# NetworkManager-wait-online Status
echo "=== NetworkManager-wait-online.service Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status NetworkManager-wait-online.service --no-pager -l" 2>/dev/null || echo "⚠️  Konnte Status nicht abrufen"
echo ""

# NetworkManager Status
echo "=== NetworkManager.service Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status NetworkManager.service --no-pager -l" 2>/dev/null || echo "⚠️  Konnte Status nicht abrufen"
echo ""

# NetworkManager Logs
echo "=== NetworkManager Logs (letzte 50 Zeilen) ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "journalctl -u NetworkManager.service --no-pager -n 50" 2>/dev/null || echo "⚠️  Konnte Logs nicht abrufen"
echo ""

# NetworkManager-wait-online Logs
echo "=== NetworkManager-wait-online Logs ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "journalctl -u NetworkManager-wait-online.service --no-pager -n 30" 2>/dev/null || echo "⚠️  Konnte Logs nicht abrufen"
echo ""

# Network Interfaces
echo "=== Network Interfaces ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "ip addr show" 2>/dev/null || echo "⚠️  Konnte Interfaces nicht prüfen"
echo ""

# systemd-networkd Status
echo "=== systemd-networkd Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status systemd-networkd --no-pager -l" 2>/dev/null || echo "⚠️  systemd-networkd nicht aktiv"
echo ""

# Netplan Status
echo "=== Netplan Status ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "netplan status 2>/dev/null || echo 'netplan status nicht verfügbar'" 2>/dev/null || echo "⚠️  Konnte Netplan nicht prüfen"
echo ""

# Active Jobs
echo "=== Active Systemd Jobs ==="
ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl list-jobs" 2>/dev/null || echo "⚠️  Konnte Jobs nicht abrufen"
echo ""

echo "✅ Runtime-Evidence gesammelt!"
echo ""
echo "📋 Analysiere diese Logs um zu verstehen:"
echo "  • WARUM schlägt NetworkManager-wait-online fehl?"
echo "  • Ist NetworkManager aktiv?"
echo "  • Gibt es Interface-Probleme?"
echo "  • Gibt es Konflikte mit systemd-networkd?"
echo ""

