#!/bin/bash
# Config-Validierung für moOde (basierend auf HiFiBerryOS fix-config.sh)
CONFIG=/boot/firmware/config.txt
ERRORS=0

# Prüfe display_rotate
if ! grep -q '^display_rotate=3' $CONFIG; then
    echo "WARNING: display_rotate=3 nicht gesetzt"
    ERRORS=$((ERRORS+1))
fi

# Prüfe vc4 Overlay
if ! grep -q 'dtoverlay=vc4-kms' $CONFIG; then
    echo "WARNING: vc4 Overlay nicht gefunden"
fi

# Prüfe hifiberry Overlay (falls vorhanden)
if grep -q 'dtoverlay=hifiberry-' $CONFIG && ! grep -q 'automute' $CONFIG; then
    echo "WARNING: automute fehlt bei hifiberry Overlay"
fi

exit $ERRORS

