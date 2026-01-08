#!/bin/bash
# Systematischer Touchscreen-Test für Pi5 und Pi4

PI5_USER="andre"
PI5_HOST="ghettoblaster.local"
PI5_PASSWORD="0815"

PI4_USER="andre"
PI4_HOST="moodepi4.local"
PI4_PASSWORD="0815"

echo "=== SYSTEMATISCHER TOUCHSCREEN-TEST ==="
echo ""
echo "Wähle Pi:"
echo "1. Pi5 (ghettoblaster)"
echo "2. Pi4 (moodepi4)"
read -p "Auswahl (1 oder 2): " PI_CHOICE

if [ "$PI_CHOICE" = "1" ]; then
    PI_USER="$PI5_USER"
    PI_HOST="$PI5_HOST"
    PI_PASSWORD="$PI5_PASSWORD"
    TOUCHSCREEN_ID="10"
elif [ "$PI_CHOICE" = "2" ]; then
    PI_USER="$PI4_USER"
    PI_HOST="$PI4_HOST"
    PI_PASSWORD="$PI4_PASSWORD"
    TOUCHSCREEN_ID="6"
else
    echo "Ungültige Auswahl!"
    exit 1
fi

echo ""
echo "=== TEST-VARIANTEN ==="
echo ""
echo "A: Nur Y invertiert (Basis)"
echo "   Matrix: 1 0 0 0 -1 1 0 0 1"
echo ""
echo "B: X/Y vertauscht, nur Y invertiert"
echo "   Matrix: 0 1 0 -1 0 1 0 0 1"
echo ""
echo "C: X/Y vertauscht, beide invertiert"
echo "   Matrix: 0 -1 1 -1 0 1 0 0 1"
echo ""
echo "D: Beide invertiert, nicht vertauscht"
echo "   Matrix: -1 0 1 0 -1 1 0 0 1"
echo ""
echo "E: Normal (keine Transformation)"
echo "   Matrix: 1 0 0 0 1 0 0 0 1"
echo ""

read -p "Wähle Variante (A/B/C/D/E): " VARIANTE

case $VARIANTE in
    A|a)
        MATRIX="1 0 0 0 -1 1 0 0 1"
        ;;
    B|b)
        MATRIX="0 1 0 -1 0 1 0 0 1"
        ;;
    C|c)
        MATRIX="0 -1 1 -1 0 1 0 0 1"
        ;;
    D|d)
        MATRIX="-1 0 1 0 -1 1 0 0 1"
        ;;
    E|e)
        MATRIX="1 0 0 0 1 0 0 0 1"
        ;;
    *)
        echo "Ungültige Variante!"
        exit 1
        ;;
esac

echo ""
echo "Setze Matrix: $MATRIX"
sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER"@"$PI_HOST" << ENDSSH
export DISPLAY=:0
xinput set-prop $TOUCHSCREEN_ID "Coordinate Transformation Matrix" $MATRIX
echo "✅ Matrix gesetzt"
echo ""
echo "Aktuelle Matrix:"
xinput list-props $TOUCHSCREEN_ID | grep "Coordinate Transformation Matrix"
ENDSSH

echo ""
echo "✅ TEST-VARIANTE GESETZT!"
echo ""
echo "💡 BITTE JETZT TESTEN:"
echo "   1. Tippen: Ist der Cursor am richtigen Ort?"
echo "   2. Wischen: Scrollt es in die richtige Richtung?"
echo "   3. Offset: Wie weit ist der Cursor vom Finger entfernt?"
echo ""
echo "Drücke Enter, wenn du getestet hast..."
read

echo ""
echo "Wie war das Ergebnis?"
echo "1. Perfekt - diese Variante verwenden"
echo "2. Richtung stimmt, aber Offset vorhanden"
echo "3. Richtung stimmt nicht"
read -p "Auswahl (1/2/3): " ERGEBNIS

if [ "$ERGEBNIS" = "1" ]; then
    echo ""
    echo "✅ Diese Variante wird in .xinitrc gespeichert..."
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER"@"$PI_HOST" << ENDSSH
sed -i 's/xinput set-prop [0-9]* "Coordinate Transformation Matrix" .*/xinput set-prop $TOUCHSCREEN_ID "Coordinate Transformation Matrix" $MATRIX 2>\/dev\/null || true/' /home/$PI_USER/.xinitrc
echo "✅ .xinitrc aktualisiert"
ENDSSH
elif [ "$ERGEBNIS" = "2" ]; then
    echo ""
    echo "💡 Für Offset-Korrektur:"
    echo "   Wir müssen die Matrix anpassen (z.B. Skalierung oder Translation)"
    echo "   Bitte sage mir:"
    echo "   - Wie weit ist der Offset? (z.B. 2cm, 4cm)"
    echo "   - In welche Richtung? (links/rechts/oben/unten)"
fi

echo ""
echo "✅ TEST ABGESCHLOSSEN!"

