#!/bin/bash
################################################################################
#
# QUICK DEBUG CONNECT
#
# Verbindet schnell zum Pi und startet Debugger
#
################################################################################

PI_HOST="${1:-192.168.178.143}"
PI_USER="${2:-andre}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔌 QUICK DEBUG CONNECT                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Verbinde zu: $PI_USER@$PI_HOST"
echo ""

# Test SSH-Verbindung
if ! ssh -o ConnectTimeout=5 "$PI_USER@$PI_HOST" "echo 'SSH OK'" 2>/dev/null; then
    echo "❌ ERROR: Kann nicht zu Pi verbinden"
    echo ""
    echo "📋 Prüfe:"
    echo "  1. Pi läuft? ping $PI_HOST"
    echo "  2. SSH aktiv? nc -zv $PI_HOST 22"
    echo "  3. Web-UI: http://$PI_HOST"
    exit 1
fi

echo "✅ SSH-Verbindung OK"
echo ""

# Prüfe ob Debug-Tools installiert sind
if ! ssh "$PI_USER@$PI_HOST" "command -v gdb >/dev/null 2>&1"; then
    echo "⚠️  Debug-Tools nicht installiert"
    echo "📋 Installiere Debug-Tools..."
    ./SETUP_PI_DEBUGGER.sh "$PI_HOST" "$PI_USER"
    echo ""
fi

echo "🔧 Starte Debug-Session..."
echo ""
echo "📋 Verfügbare Optionen:"
echo "  1. Service debuggen: debug-service <service>"
echo "  2. Service verfolgen: trace-service <service>"
echo "  3. Service überwachen: monitor-service <service>"
echo "  4. Chromium debuggen: debug-chromium"
echo "  5. Logs ansehen: view-logs <service>"
echo ""

# Starte interaktive SSH-Session mit Debug-Helper
ssh -t "$PI_USER@$PI_HOST" << 'DEBUG_SESSION_EOF'
    # Lade Debug-Helper
    if [ -f ~/debug/debug-services.sh ]; then
        source ~/debug/debug-services.sh
        echo "✅ Debug-Helper geladen"
    else
        echo "⚠️  Debug-Helper nicht gefunden"
        echo "   Führe aus: ./SETUP_PI_DEBUGGER.sh"
    fi
    
    echo ""
    echo "🔧 DEBUG-SESSION GESTARTET"
    echo ""
    echo "📋 Verfügbare Befehle:"
    echo "  - debug-service <service>  - Service mit GDB debuggen"
    echo "  - trace-service <service>  - Service mit strace verfolgen"
    echo "  - monitor-service <service> - Service mit htop überwachen"
    echo ""
    echo "📋 Beispiele:"
    echo "  debug-service localdisplay.service"
    echo "  trace-service localdisplay.service"
    echo "  monitor-service localdisplay.service"
    echo ""
    echo "📋 Chromium debuggen:"
    echo "  PID=\$(pgrep chromium)"
    echo "  sudo gdb -p \$PID"
    echo ""
    echo "📋 Logs ansehen:"
    echo "  journalctl -u localdisplay.service -f"
    echo ""
    
    # Starte bash mit Debug-Helper
    exec bash
DEBUG_SESSION_EOF

