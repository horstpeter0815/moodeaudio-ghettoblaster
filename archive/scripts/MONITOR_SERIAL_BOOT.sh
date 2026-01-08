#!/bin/bash
# Monitor Serial Console and save boot logs

SERIAL_PORT="/dev/cu.usbmodem214302"
BAUDRATE="115200"
LOG_FILE="serial-boot-$(date +%Y%m%d_%H%M%S).log"

echo "═══════════════════════════════════════════════════════════"
echo "📊 SERIAL-BOOT MONITORING"
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
echo "🔌 Verbinde und speichere Boot-Logs..."
echo "   (Zum Beenden: Ctrl+C)"
echo ""

# Use cu to connect and log
cu -l "$SERIAL_PORT" -s "$BAUDRATE" 2>&1 | tee "$LOG_FILE"


