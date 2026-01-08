#!/bin/bash
# Ghettoblaster - Post-Build Overlay Kompilierung
# Kompiliert Custom Overlays zu DTBO

OVERLAYS_DIR="/boot/firmware/overlays"
DTBO_DIR="/boot/firmware/overlays"

# Kompiliere FT6236 Overlay
if [ -f "$OVERLAYS_DIR/ghettoblaster-ft6236.dts" ]; then
    dtc -@ -I dts -O dtb -o "$DTBO_DIR/ghettoblaster-ft6236.dtbo" \
        "$OVERLAYS_DIR/ghettoblaster-ft6236.dts" 2>/dev/null && \
        echo "✅ FT6236 Overlay kompiliert" || \
        echo "⚠️  FT6236 Overlay Kompilierung fehlgeschlagen"
fi

# Kompiliere AMP100 Overlay
if [ -f "$OVERLAYS_DIR/ghettoblaster-amp100.dts" ]; then
    dtc -@ -I dts -O dtb -o "$DTBO_DIR/ghettoblaster-amp100.dtbo" \
        "$OVERLAYS_DIR/ghettoblaster-amp100.dts" 2>/dev/null && \
        echo "✅ AMP100 Overlay kompiliert" || \
        echo "⚠️  AMP100 Overlay Kompilierung fehlgeschlagen"
fi
