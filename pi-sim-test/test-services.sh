#!/bin/bash
# Test script for Pi Boot Simulation
# Tests all services and fixes

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 PI BOOT SIMULATION - SERVICE TESTS                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Wait for systemd to be ready
echo "⏳ Warte auf systemd..."
sleep 5

# Test 1: User andre exists with UID 1000
echo ""
echo "🔍 TEST 1: User andre (UID 1000)"
if id -u andre >/dev/null 2>&1; then
    UID=$(id -u andre)
    if [ "$UID" = "1000" ]; then
        echo "   ✅ User 'andre' hat UID 1000"
    else
        echo "   ❌ User 'andre' hat UID $UID (sollte 1000 sein)"
        exit 1
    fi
else
    echo "   ❌ User 'andre' existiert nicht"
    exit 1
fi

# Test 2: Hostname
echo ""
echo "🔍 TEST 2: Hostname"
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "GhettoBlaster" ]; then
    echo "   ✅ Hostname ist 'GhettoBlaster'"
else
    echo "   ❌ Hostname ist '$HOSTNAME' (sollte 'GhettoBlaster' sein)"
    exit 1
fi

# Test 3: SSH enabled
echo ""
echo "🔍 TEST 3: SSH enabled"
if systemctl is-enabled ssh >/dev/null 2>&1 || systemctl is-enabled sshd >/dev/null 2>&1; then
    echo "   ✅ SSH ist enabled"
else
    echo "   ⚠️  SSH ist nicht enabled (wird von Services aktiviert)"
fi

# Test 4: Sudoers
echo ""
echo "🔍 TEST 4: Sudoers"
if sudo -n true 2>/dev/null; then
    echo "   ✅ Sudoers funktioniert (NOPASSWD)"
else
    echo "   ❌ Sudoers funktioniert nicht"
    exit 1
fi

# Test 5: Services exist
echo ""
echo "🔍 TEST 5: Custom Services"
SERVICES=(
    "enable-ssh-early.service"
    "fix-ssh-sudoers.service"
    "fix-user-id.service"
    "localdisplay.service"
    "disable-console.service"
)

for service in "${SERVICES[@]}"; do
    if [ -f "/lib/systemd/system/$service" ] || [ -f "/lib/systemd/system/custom/$service" ]; then
        echo "   ✅ $service vorhanden"
    else
        echo "   ⚠️  $service nicht gefunden (kann normal sein, wenn nicht gemountet)"
    fi
done

# Test 6: Scripts exist
echo ""
echo "🔍 TEST 6: Custom Scripts"
SCRIPTS=(
    "start-chromium-clean.sh"
    "xserver-ready.sh"
    "worker-php-patch.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "/usr/local/bin/$script" ] || [ -f "/usr/local/bin/custom/$script" ]; then
        echo "   ✅ $script vorhanden"
    else
        echo "   ⚠️  $script nicht gefunden (kann normal sein, wenn nicht gemountet)"
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ALLE TESTS ABGESCHLOSSEN                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

