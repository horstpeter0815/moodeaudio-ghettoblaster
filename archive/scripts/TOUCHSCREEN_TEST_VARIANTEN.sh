#!/bin/bash
# Setze Touchscreen-Test-Variante

PI_USER="andre"
PI_HOST="ghettoblaster.local"
PI_PASSWORD="0815"
TOUCHSCREEN_ID="10"

VARIANTE=$1

case $VARIANTE in
    A|a)
        MATRIX="1 0 0 0 -1 1 0 0 1"
        DESC="Nur Y invertiert (Basis)"
        ;;
    B|b)
        MATRIX="0 1 0 -1 0 1 0 0 1"
        DESC="X/Y vertauscht, nur Y invertiert"
        ;;
    C|c)
        MATRIX="0 -1 1 -1 0 1 0 0 1"
        DESC="X/Y vertauscht, beide invertiert"
        ;;
    D|d)
        MATRIX="-1 0 1 0 -1 1 0 0 1"
        DESC="Beide invertiert, nicht vertauscht"
        ;;
    E|e)
        MATRIX="1 0 0 0 1 0 0 0 1"
        DESC="Normal (keine Transformation)"
        ;;
    *)
        echo "Verwendung: $0 [A|B|C|D|E]"
        echo ""
        echo "Variante A: Nur Y invertiert"
        echo "Variante B: X/Y vertauscht, nur Y invertiert"
        echo "Variante C: X/Y vertauscht, beide invertiert"
        echo "Variante D: Beide invertiert, nicht vertauscht"
        echo "Variante E: Normal (keine Transformation)"
        exit 1
        ;;
esac

echo "=== SETZE VARIANTE $VARIANTE: $DESC ==="
echo "Matrix: $MATRIX"
echo ""

sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER"@"$PI_HOST" << ENDSSH
export DISPLAY=:0
xinput set-prop $TOUCHSCREEN_ID "Coordinate Transformation Matrix" $MATRIX
echo "✅ Matrix gesetzt"
echo ""
echo "Aktuelle Matrix:"
xinput list-props $TOUCHSCREEN_ID | grep "Coordinate Transformation Matrix"
ENDSSH

echo ""
echo "✅ VARIANTE $VARIANTE GESETZT!"
echo ""
echo "💡 BITTE JETZT TESTEN:"
echo "   1. Tippen: Ist der Cursor am richtigen Ort?"
echo "   2. Wischen: Scrollt es in die richtige Richtung?"
echo "   3. Offset: Wie weit ist der Cursor vom Finger entfernt?"
