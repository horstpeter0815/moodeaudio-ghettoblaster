#!/bin/bash
################################################################################
#
# Starte Build-Monitor im Hintergrund
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Prüfe ob Monitor schon läuft
if pgrep -f "monitor-build.sh" >/dev/null; then
    echo "⚠️  Monitor läuft bereits (PID: $(pgrep -f monitor-build.sh))"
    exit 0
fi

# Starte Monitor im Hintergrund
nohup "$SCRIPT_DIR/monitor-build.sh" > /dev/null 2>&1 &

echo "✅ Build-Monitor gestartet (PID: $!)"
echo ""
echo "Monitor-Status prüfen:"
echo "  tail -f build-monitor.log"
echo ""
echo "Alerts ansehen:"
echo "  tail -f build-alert.log"
echo ""
echo "Monitor stoppen:"
echo "  pkill -f monitor-build.sh"

