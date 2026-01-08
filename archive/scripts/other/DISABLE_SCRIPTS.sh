#!/bin/bash
# Deaktiviert alle Scripts (entfernt Ausführungsrechte)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== DEAKTIVIERE SCRIPTS ==="
echo ""

# Liste aller Scripts
SCRIPTS=(
    "FIX_MOODE_DISPLAY_FINAL.sh"
    "VERIFY_DISPLAY_FIX.sh"
    "CONFIGURE_AMP100.sh"
    "PHASE1_HARDWARE_WITH_AMP100.sh"
    "PHASE2_ALSA_AMP100.sh"
    "CHECK_PI_STATUS.sh"
    "STANDARD_TEST_SUITE_FINAL.sh"
    "AUTO_EXECUTE.sh"
    "DO_IT_NOW.sh"
    "RUN_ON_PI.sh"
    "fix_display_on_pi.sh"
    "INSTALL_SSHPASS_AND_FIX.sh"
    "execute_fix_now.py"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        chmod -x "$script"
        echo "✅ $script deaktiviert"
    fi
done

# Alle anderen .sh Dateien
find . -maxdepth 1 -name "*.sh" -type f -exec chmod -x {} \;
echo ""
echo "✅ Alle .sh Scripts deaktiviert"

# Python Scripts
find . -maxdepth 1 -name "*.py" -type f -exec chmod -x {} \;
echo "✅ Alle .py Scripts deaktiviert"

echo ""
echo "=== FERTIG ==="
echo "Alle Scripts sind jetzt deaktiviert (keine Ausführungsrechte)"
echo ""
echo "Um Scripts wieder zu aktivieren:"
echo "  chmod +x <script-name>"
echo ""

