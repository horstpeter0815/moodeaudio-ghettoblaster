#!/bin/bash
# Installiert sshpass (falls nötig) und führt Display-Fix aus

echo "=== INSTALLIERE SSHPASS UND FIXE DISPLAY ==="
echo ""

# Prüfe ob sshpass installiert ist
if ! command -v sshpass &> /dev/null; then
    echo "sshpass nicht gefunden. Installiere..."
    
    # Prüfe ob Homebrew installiert ist
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew nicht gefunden. Installiere Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "Installiere sshpass via Homebrew..."
    brew install hudochenkov/sshpass/sshpass
    
    if ! command -v sshpass &> /dev/null; then
        echo "❌ sshpass Installation fehlgeschlagen"
        echo "Versuche alternative Installation..."
        # Alternative: Direkt von GitHub
        cd /tmp
        git clone https://github.com/hudochenkov/sshpass.git
        cd sshpass
        ./configure
        make
        sudo make install
        cd -
    fi
else
    echo "✅ sshpass bereits installiert"
fi

echo ""
echo "Prüfe sshpass Installation..."
if command -v sshpass &> /dev/null; then
    echo "✅ sshpass gefunden: $(which sshpass)"
    sshpass -V
else
    echo "❌ sshpass konnte nicht installiert werden"
    echo "Bitte manuell installieren:"
    echo "  brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

echo ""
echo "=== FÜHRE DISPLAY-FIX AUS ==="
echo ""

# Führe Display-Fix aus
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "FIX_MOODE_DISPLAY_FINAL.sh" ]; then
    chmod +x FIX_MOODE_DISPLAY_FINAL.sh
    ./FIX_MOODE_DISPLAY_FINAL.sh
else
    echo "❌ FIX_MOODE_DISPLAY_FINAL.sh nicht gefunden"
    exit 1
fi

echo ""
echo "=== FERTIG ==="
echo ""
echo "Nächster Schritt: Pi 5 rebooten"
echo "  ssh andre@192.168.178.178"
echo "  sudo reboot"

