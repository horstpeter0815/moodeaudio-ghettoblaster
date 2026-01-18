#!/bin/bash
# Diagnose why UI buttons are disabled - based on moOde's actual logic

DB="/var/local/www/db/moode-sqlite3.db"

echo "=== UI Button Disable Logic Diagnosis ==="
echo ""

# Get all relevant settings
PEPPY_DISPLAY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)
LOCAL_DISPLAY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)
AUDIOOUT=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='audioout';" 2>/dev/null)
ALSAEQUAL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsaequal';" 2>/dev/null)
EQFA12P=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='eqfa12p';" 2>/dev/null)
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null)

echo "Current Settings:"
echo "  peppy_display: $PEPPY_DISPLAY"
echo "  local_display: $LOCAL_DISPLAY"
echo "  audioout: $AUDIOOUT"
echo "  alsaequal: $ALSAEQUAL"
echo "  eqfa12p: $EQFA12P"
echo "  alsa_output_mode: $ALSA_MODE"
echo ""

echo "=== Button Disable Logic (from moOde source) ==="
echo ""

# Logic from per-config.php line 228-229:
# $_webui_on_off_disable = $_SESSION['peppy_display'] == '1' ? 'disabled' : '';
# $_peppy_on_off_disable = ($_SESSION['local_display'] == '1' || allowPeppyInAlsaChain() == false) ? 'disabled' : '';

echo "1. Local Display Button:"
if [ "$PEPPY_DISPLAY" = "1" ]; then
    echo "  ⚠ DISABLED because peppy_display = 1"
    echo "  Fix: Set peppy_display = 0 to enable Local Display button"
else
    echo "  ✓ ENABLED (peppy_display != 1)"
fi
echo ""

echo "2. Peppy Display Button:"
DISABLED_REASONS=()

if [ "$LOCAL_DISPLAY" = "1" ]; then
    DISABLED_REASONS+=("local_display = 1")
fi

# allowPeppyInAlsaChain() logic:
# Returns false if: audioout == 'Bluetooth' && (alsaequal != 'Off' || eqfa12p != 'Off')
if [ "$AUDIOOUT" = "Bluetooth" ]; then
    if [ "$ALSAEQUAL" != "Off" ] || [ "$EQFA12P" != "Off" ]; then
        DISABLED_REASONS+=("Bluetooth audio with EQ active")
    fi
fi

if [ ${#DISABLED_REASONS[@]} -gt 0 ]; then
    echo "  ⚠ DISABLED because:"
    for reason in "${DISABLED_REASONS[@]}"; do
        echo "    - $reason"
    done
    echo ""
    echo "  Fixes needed:"
    if [ "$LOCAL_DISPLAY" = "1" ]; then
        echo "    - Set local_display = 0"
    fi
    if [ "$AUDIOOUT" = "Bluetooth" ] && ([ "$ALSAEQUAL" != "Off" ] || [ "$EQFA12P" != "Off" ]); then
        echo "    - Disable EQ or switch audioout from Bluetooth"
    fi
else
    echo "  ✓ ENABLED (no conflicts)"
fi
echo ""

echo "=== Proper Fix ==="
echo ""

FIXES_NEEDED=0

# Fix 1: Ensure only one display is enabled
if [ "$PEPPY_DISPLAY" = "1" ] && [ "$LOCAL_DISPLAY" = "1" ]; then
    echo "Fixing: Disabling Local Display (keeping Peppy)..."
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"
    echo "  ✓ Fixed: local_display = 0"
    FIXES_NEEDED=1
fi

# Fix 2: Check if Peppy can be enabled
if [ "$LOCAL_DISPLAY" = "1" ]; then
    echo "Fixing: Disabling Local Display to enable Peppy button..."
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"
    echo "  ✓ Fixed: local_display = 0"
    FIXES_NEEDED=1
fi

if [ $FIXES_NEEDED -eq 0 ]; then
    echo "✓ No fixes needed - configuration is correct"
else
    echo ""
    echo "After fix:"
    echo "  peppy_display: $(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)"
    echo "  local_display: $(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)"
fi

echo ""
echo "=== Complete ==="
echo ""
echo "After fixes, refresh the Web UI (hard refresh: Cmd+Shift+R)"
echo "The buttons should now work correctly."

