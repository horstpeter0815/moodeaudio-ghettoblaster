#!/bin/bash
# AUTO EXECUTE - Führt alles automatisch aus

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== AUTO EXECUTE DISPLAY FIX ==="
echo ""

# Prüfe sshpass
if ! command -v sshpass &> /dev/null; then
    echo "Installiere sshpass..."
    if command -v brew &> /dev/null; then
        brew install hudochenkov/sshpass/sshpass 2>&1 || true
    else
        echo "Homebrew nicht gefunden. Installiere Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 || true
        brew install hudochenkov/sshpass/sshpass 2>&1 || true
    fi
fi

# Kopiere Script auf Pi
echo "Kopiere Script auf Pi..."
scp -o StrictHostKeyChecking=no RUN_ON_PI.sh andre@192.168.178.178:/tmp/fix_display.sh 2>&1 || {
    echo "⚠️  scp fehlgeschlagen, versuche mit sshpass..."
    sshpass -p '0815' scp -o StrictHostKeyChecking=no RUN_ON_PI.sh andre@192.168.178.178:/tmp/fix_display.sh 2>&1 || {
        echo "❌ Kopieren fehlgeschlagen"
        exit 1
    }
}

# Führe Script auf Pi aus
echo "Führe Script auf Pi aus..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 andre@192.168.178.178 'bash /tmp/fix_display.sh' 2>&1

# Reboot
echo ""
echo "Reboote Pi..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 andre@192.168.178.178 'sudo reboot' 2>&1 || true

echo ""
echo "=== FERTIG ==="
echo "Pi wird rebootet. Warte 1-2 Minuten."

