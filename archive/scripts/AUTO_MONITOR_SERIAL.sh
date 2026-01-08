#!/bin/bash
# Automatically monitor Serial Console and detect boot

SERIAL_PORT="/dev/cu.usbmodem214302"
BAUDRATE="115200"
LOG_FILE="serial-boot-$(date +%Y%m%d_%H%M%S).log"

echo "═══════════════════════════════════════════════════════════"
echo "📊 AUTO SERIAL-BOOT MONITORING"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if serial port exists
if [ ! -e "$SERIAL_PORT" ]; then
    echo "❌ Serial-Port nicht gefunden: $SERIAL_PORT"
    exit 1
fi

echo "✅ Serial-Port: $SERIAL_PORT"
echo "📋 Baudrate: $BAUDRATE"
echo "📝 Log-Datei: $LOG_FILE"
echo ""
echo "🔌 Verbinde Serial-Konsole..."
echo "⏳ Warte auf Boot-Logs..."
echo ""
echo "💡 Tipp: Pi jetzt einschalten!"
echo ""

# Use screen in background to capture output
screen -dmS serial-monitor "$SERIAL_PORT" "$BAUDRATE"

# Wait a moment
sleep 2

# Try to read from serial port
echo "📊 Lese Serial-Daten..."
timeout 10 cat "$SERIAL_PORT" 2>/dev/null | head -20 || echo "⏳ Warte auf Daten..."

echo ""
echo "✅ Monitoring läuft"
echo "📋 Um Logs zu sehen: screen -r serial-monitor"
echo "📋 Um zu beenden: screen -X -S serial-monitor quit"


