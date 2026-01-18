#!/bin/bash
# Complete SD Card Analysis - cloud-init.target and NetworkManager
# Analysiert alle potenziellen Blockierer

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 COMPLETE SD CARD ANALYSIS                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde Root-Partition
ROOT_MOUNT=""
if mount | grep -q "rootfs"; then
    ROOT_MOUNT=$(mount | grep rootfs | awk '{print $3}' | head -1)
else
    echo "❌ Root-Partition nicht gemountet!"
    exit 1
fi

echo "✅ Root-Partition: $ROOT_MOUNT"
echo ""

echo "📋 Analysiere alle potenziellen Probleme..."
echo ""

# 1. Services die auf moode-startup.service warten
echo "=== 1. Services die auf moode-startup.service warten ==="
SERVICES_WAITING=$(find "$ROOT_MOUNT" -name "*.service" -type f -exec grep -l "After=.*moode-startup" {} \; 2>/dev/null)
if [ -z "$SERVICES_WAITING" ]; then
    echo "✅ Keine Services gefunden die auf moode-startup.service warten"
else
    echo "⚠️  Gefundene Services:"
    echo "$SERVICES_WAITING" | while read -r service; do
        echo "  • $(basename "$service")"
        echo "    $(grep "After=.*moode-startup" "$service" | head -1)"
    done
fi
echo ""

# 2. network-guaranteed.service Syntax
echo "=== 2. network-guaranteed.service Syntax ==="
NETWORK_GUARANTEED=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -n "$NETWORK_GUARANTEED" ]; then
    echo "✅ Gefunden: $NETWORK_GUARANTEED"
    if grep -q "2>&1" "$NETWORK_GUARANTEED"; then
        echo "✅ Syntax korrekt (2>&1 gefunden)"
    else
        echo "⚠️  Syntax-Fehler gefunden!"
        echo "   Korrupte Zeilen:"
        grep -E "2>.*1[^&]|2>.*systemctl" "$NETWORK_GUARANTEED" | head -5
    fi
    echo ""
    echo "Dependencies:"
    grep -E "After=|Wants=|Requires=|Before=" "$NETWORK_GUARANTEED" | head -5
else
    echo "❌ network-guaranteed.service nicht gefunden"
fi
echo ""

# 3. fix-user-id.service
echo "=== 3. fix-user-id.service ==="
FIX_USER_ID=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
if [ -n "$FIX_USER_ID" ]; then
    echo "✅ Gefunden: $FIX_USER_ID"
    echo ""
    echo "Dependencies:"
    grep -E "After=|Wants=|Requires=" "$FIX_USER_ID" || echo "Keine Dependencies"
    if grep -q "After=moode-startup.service" "$FIX_USER_ID"; then
        echo ""
        echo "⚠️  Wartet auf moode-startup.service (kann cloud-init.target blockieren)"
    else
        echo ""
        echo "✅ Wartet nicht auf moode-startup.service"
    fi
else
    echo "❌ fix-user-id.service nicht gefunden"
fi
echo ""

# 4. fix-ssh-sudoers.service
echo "=== 4. fix-ssh-sudoers.service ==="
FIX_SSH_SUDOERS=$(find "$ROOT_MOUNT" -name "fix-ssh-sudoers.service" -type f | head -1)
if [ -n "$FIX_SSH_SUDOERS" ]; then
    echo "✅ Gefunden: $FIX_SSH_SUDOERS"
    echo ""
    echo "Dependencies:"
    grep -E "After=|Wants=|Requires=" "$FIX_SSH_SUDOERS" || echo "Keine Dependencies"
    if grep -q "After=moode-startup.service" "$FIX_SSH_SUDOERS"; then
        echo ""
        echo "⚠️  Wartet auf moode-startup.service (kann cloud-init.target blockieren)"
    else
        echo ""
        echo "✅ Wartet nicht auf moode-startup.service"
    fi
else
    echo "❌ fix-ssh-sudoers.service nicht gefunden"
fi
echo ""

# 5. NetworkManager Konfiguration
echo "=== 5. NetworkManager Konfiguration ==="
if [ -d "$ROOT_MOUNT/etc/netplan" ]; then
    echo "Netplan Dateien:"
    ls -la "$ROOT_MOUNT/etc/netplan/" 2>/dev/null | grep -v "^total" || echo "Keine Netplan Dateien"
    for file in "$ROOT_MOUNT/etc/netplan"/*.yaml; do
        if [ -f "$file" ]; then
            echo ""
            echo "Datei: $(basename "$file")"
            cat "$file"
        fi
    done
else
    echo "Kein /etc/netplan Verzeichnis"
fi
echo ""

echo "✅ Analyse abgeschlossen!"
echo ""

