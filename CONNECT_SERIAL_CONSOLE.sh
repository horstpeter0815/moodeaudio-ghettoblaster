#!/bin/bash
# Connect to Serial Console and monitor boot

SERIAL_PORT="/dev/cu.usbmodem214302"
BAUDRATE="115200"

echo "═══════════════════════════════════════════════════════════"
echo "🔌 SERIAL-KONSOLE VERBINDEN"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if serial port exists
if [ ! -e "$SERIAL_PORT" ]; then
    echo "❌ Serial-Port nicht gefunden: $SERIAL_PORT"
    echo ""
    echo "📋 Verfügbare Serial-Ports:"
    ls -la /dev/cu.usbmodem* 2>/dev/null || echo "   Keine gefunden"
    exit 1
fi

echo "✅ Serial-Port gefunden: $SERIAL_PORT"
echo "📋 Baudrate: $BAUDRATE"
echo ""
echo "🔌 Verbinde Serial-Konsole..."
echo "   (Zum Beenden: Ctrl+A, dann K, dann Y)"
echo ""
echo "⏳ Warte auf Daten..."
echo ""

# Connect with screen
screen "$SERIAL_PORT" "$BAUDRATE"


