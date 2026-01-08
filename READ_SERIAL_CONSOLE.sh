#!/bin/bash
################################################################################
#
# READ_SERIAL_CONSOLE.sh
#
# Liest die Serial Console direkt aus
#
################################################################################

SERIAL_PORT="/dev/cu.usbmodem214302"
BAUDRATE="115200"

if [ ! -e "$SERIAL_PORT" ]; then
    echo "❌ Serial Port nicht gefunden: $SERIAL_PORT"
    exit 1
fi

echo "=== SERIAL CONSOLE LIVE ==="
echo "Port: $SERIAL_PORT"
echo "Baudrate: $BAUDRATE"
echo ""

# Konfiguriere Serial Port
stty -f "$SERIAL_PORT" "$BAUDRATE" raw -echo -echoe -echok 2>/dev/null

# Lese Serial Console
timeout 10 cat "$SERIAL_PORT" 2>&1 | head -200 || \
timeout 10 dd if="$SERIAL_PORT" bs=1 count=2000 2>/dev/null | strings | head -200 || \
echo "Konnte Serial Console nicht lesen"

