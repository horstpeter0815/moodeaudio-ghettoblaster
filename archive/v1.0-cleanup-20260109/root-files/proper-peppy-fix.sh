#!/bin/bash
# Proper Peppy Display Fix - Based on moOde's actual logic

DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Proper Peppy Display Configuration Fix ==="
echo ""

# Check current state
PEPPY_DISPLAY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)
LOCAL_DISPLAY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null)
ALSAEQUAL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsaequal';" 2>/dev/null)
EQFA12P=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='eqfa12p';" 2>/dev/null)
CAMILLADSP=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)

echo "Current Configuration:"
echo "  peppy_display: $PEPPY_DISPLAY"
echo "  local_display: $LOCAL_DISPLAY"
echo "  alsa_output_mode: $ALSA_MODE"
echo "  alsaequal: $ALSAEQUAL"
echo "  eqfa12p: $EQFA12P"
echo "  camilladsp: $CAMILLADSP"
echo ""

# According to moOde logic (per-config.php line 229):
# $_peppy_on_off_disable = ($_SESSION['local_display'] == '1' || allowPeppyInAlsaChain() == false) ? 'disabled' : '';
# allowPeppyInAlsaChain() checks: audioout != Bluetooth && !(alsaequal != Off || eqfa12p != Off) && alsa_output_mode != plughw

echo "=== Checking Requirements ==="
echo ""

ISSUES=0

# Issue 1: Both displays enabled
if [ "$PEPPY_DISPLAY" = "1" ] && [ "$LOCAL_DISPLAY" = "1" ]; then
    echo "⚠ Issue 1: Both Peppy and Local Display are enabled"
    echo "  Fix: Disabling Local Display..."
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"
    echo "  ✓ Fixed: local_display = 0"
    ISSUES=1
fi

# Issue 2: ALSA output mode conflict
# Peppy requires alsa_output_mode != plughw (should be hw)
if [ "$PEPPY_DISPLAY" = "1" ] && [ "$ALSA_MODE" = "plughw" ]; then
    echo "⚠ Issue 2: ALSA output mode is 'plughw' but Peppy requires 'hw'"
    echo "  Note: This may be intentional if using CamillaDSP"
    if [ "$CAMILLADSP" = "off" ] || [ "$CAMILLADSP" = "" ]; then
        echo "  ⚠ CamillaDSP is off - Peppy may not work correctly with plughw"
    else
        echo "  ✓ CamillaDSP is active - plughw is OK"
    fi
fi

# Issue 3: EQ conflicts
if [ "$PEPPY_DISPLAY" = "1" ]; then
    if [ "$ALSAEQUAL" != "Off" ] || [ "$EQFA12P" != "Off" ]; then
        echo "⚠ Issue 3: EQ is active - Peppy may have conflicts"
        echo "  alsaequal: $ALSAEQUAL"
        echo "  eqfa12p: $EQFA12P"
    fi
fi

# Issue 4: CamillaDSP and Peppy conflict
if [ "$PEPPY_DISPLAY" = "1" ] && [ "$CAMILLADSP" != "off" ] && [ "$CAMILLADSP" != "" ]; then
    echo "⚠ Issue 4: Both Peppy Display and CamillaDSP are active"
    echo "  This can cause conflicts - check CamillaDSP config device setting"
fi

echo ""
echo "=== Verifying Fix ==="
echo ""

LOCAL_DISPLAY_NEW=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)
echo "After fix:"
echo "  peppy_display: $PEPPY_DISPLAY"
echo "  local_display: $LOCAL_DISPLAY_NEW"
echo ""

if [ "$PEPPY_DISPLAY" = "1" ] && [ "$LOCAL_DISPLAY_NEW" = "0" ]; then
    echo "✓ Configuration is correct - only Peppy Display is enabled"
    echo ""
    echo "The UI buttons should now work correctly."
    echo ""
    echo "Note: If buttons still don't work, try:"
    echo "  1. Hard refresh the Web UI (Cmd+Shift+R / Ctrl+Shift+R)"
    echo "  2. Clear browser cache"
    echo "  3. Check browser console for JavaScript errors"
else
    echo "⚠ Configuration may still have issues"
fi

echo ""
echo "=== Complete ==="

