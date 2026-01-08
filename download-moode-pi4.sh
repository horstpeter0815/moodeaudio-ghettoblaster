#!/bin/bash
# moOde Audio für Pi 4 herunterladen

echo "=== MOODE AUDIO FÜR PI 4 DOWNLOAD ==="
echo ""
echo "moOde Audio kann von https://moodeaudio.org/ heruntergeladen werden"
echo ""
echo "Für Pi 4 benötigt:"
echo "- moOde r900 (oder neueste Version)"
echo "- ARM64 oder ARMHF (je nach Pi 4 Modell)"
echo ""
echo "Download-Link wird gesucht..."

# Prüfe ob wget oder curl verfügbar
if command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -L -o"
elif command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -O"
else
    echo "❌ wget oder curl nicht gefunden"
    exit 1
fi

# moOde Download-URL (muss aktualisiert werden)
MOODE_URL="https://moodeaudio.org/download/moode-r900-arm64.img.zip"
MOODE_FILE="moode-r900-arm64.img.zip"

echo ""
echo "Bitte manuell herunterladen von:"
echo "https://moodeaudio.org/"
echo ""
echo "Oder automatisch (falls URL korrekt):"
read -p "Automatisch herunterladen? (y/N): " confirm

if [ "$confirm" == "y" ]; then
    echo "Lade moOde Image herunter..."
    $DOWNLOAD_CMD "$MOODE_FILE" "$MOODE_URL"
    
    if [ $? -eq 0 ]; then
        echo "✅ Download erfolgreich!"
        echo "Entpacke..."
        unzip "$MOODE_FILE"
        echo "✅ Fertig! Image: $(ls -1 *.img | head -1)"
    else
        echo "❌ Download fehlgeschlagen"
        echo "Bitte manuell von https://moodeaudio.org/ herunterladen"
    fi
else
    echo "Bitte manuell herunterladen und dann burn-moode-pi4.sh verwenden"
fi

