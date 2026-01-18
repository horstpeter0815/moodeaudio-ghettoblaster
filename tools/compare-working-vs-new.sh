#!/bin/bash
# Compare Working SD Card vs New Build
# Professional approach: Baseline comparison

set -e

echo "=== COMPARING WORKING vs NEW BUILD ==="
echo ""

# Detect SD cards
WORKING_MOUNT=""
NEW_MOUNT=""

echo "Detecting SD cards..."
for mount in /Volumes/*; do
    if [ -d "$mount/etc/systemd" ]; then
        if [ -z "$WORKING_MOUNT" ]; then
            WORKING_MOUNT="$mount"
            echo "✅ Found SD card 1: $WORKING_MOUNT"
        elif [ -z "$NEW_MOUNT" ]; then
            NEW_MOUNT="$mount"
            echo "✅ Found SD card 2: $NEW_MOUNT"
        fi
    fi
done

if [ -z "$WORKING_MOUNT" ] || [ -z "$NEW_MOUNT" ]; then
    echo "❌ ERROR: Need 2 SD cards mounted"
    echo "   Working SD card: ${WORKING_MOUNT:-NOT FOUND}"
    echo "   New build SD card: ${NEW_MOUNT:-NOT FOUND}"
    echo ""
    echo "Please mount both SD cards and try again"
    exit 1
fi

echo ""
echo "Which is the WORKING one? (1 or 2)"
echo "  1: $WORKING_MOUNT"
echo "  2: $NEW_MOUNT"
read -p "Enter 1 or 2: " choice

if [ "$choice" = "2" ]; then
    TEMP="$WORKING_MOUNT"
    WORKING_MOUNT="$NEW_MOUNT"
    NEW_MOUNT="$TEMP"
fi

echo ""
echo "Working SD card: $WORKING_MOUNT"
echo "New build SD card: $NEW_MOUNT"
echo ""

OUTPUT_DIR="comparison-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "=== COMPARING SYSTEMD CONFIGURATIONS ==="
echo ""

echo "1. Comparing /etc/systemd/system..."
diff -r "$WORKING_MOUNT/etc/systemd/system" "$NEW_MOUNT/etc/systemd/system" > "$OUTPUT_DIR/systemd-etc.diff" 2>&1 || true
if [ -s "$OUTPUT_DIR/systemd-etc.diff" ]; then
    echo "   ⚠️  Differences found (saved to $OUTPUT_DIR/systemd-etc.diff)"
    echo "   Key differences:"
    grep -E "^Only in|^diff|systemd-networkd-wait-online|network-online" "$OUTPUT_DIR/systemd-etc.diff" | head -20
else
    echo "   ✅ No differences"
fi

echo ""
echo "2. Comparing /lib/systemd/system (source files)..."
diff -r "$WORKING_MOUNT/lib/systemd/system" "$NEW_MOUNT/lib/systemd/system" > "$OUTPUT_DIR/systemd-lib.diff" 2>&1 || true
if [ -s "$OUTPUT_DIR/systemd-lib.diff" ]; then
    echo "   ⚠️  Differences found (saved to $OUTPUT_DIR/systemd-lib.diff)"
    grep -E "^Only in|^diff|systemd-networkd-wait-online" "$OUTPUT_DIR/systemd-lib.diff" | head -20
else
    echo "   ✅ No differences"
fi

echo ""
echo "3. Comparing network-online.target configuration..."
if [ -f "$WORKING_MOUNT/etc/systemd/system/network-online.target.d/override.conf" ]; then
    echo "   Working override:"
    cat "$WORKING_MOUNT/etc/systemd/system/network-online.target.d/override.conf"
    echo ""
fi
if [ -f "$NEW_MOUNT/etc/systemd/system/network-online.target.d/override.conf" ]; then
    echo "   New override:"
    cat "$NEW_MOUNT/etc/systemd/system/network-online.target.d/override.conf"
    echo ""
fi

echo ""
echo "4. Comparing systemd-networkd-wait-online service..."
echo "   Working:"
ls -la "$WORKING_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service" 2>/dev/null || echo "   Not found"
if [ -f "$WORKING_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf" ]; then
    echo "   Working override:"
    cat "$WORKING_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf"
fi
echo ""
echo "   New:"
ls -la "$NEW_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service" 2>/dev/null || echo "   Not found"
if [ -f "$NEW_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf" ]; then
    echo "   New override:"
    cat "$NEW_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf"
fi

echo ""
echo "5. Checking network-online.target.wants..."
echo "   Working:"
ls -la "$WORKING_MOUNT/etc/systemd/system/network-online.target.wants/" 2>/dev/null || echo "   Directory doesn't exist (good)"
echo "   New:"
ls -la "$NEW_MOUNT/etc/systemd/system/network-online.target.wants/" 2>/dev/null || echo "   Directory doesn't exist (good)"

echo ""
echo "6. Comparing multi-user.target override..."
if [ -f "$WORKING_MOUNT/etc/systemd/system/multi-user.target.d/override.conf" ]; then
    echo "   Working:"
    cat "$WORKING_MOUNT/etc/systemd/system/multi-user.target.d/override.conf"
    echo ""
fi
if [ -f "$NEW_MOUNT/etc/systemd/system/multi-user.target.d/override.conf" ]; then
    echo "   New:"
    cat "$NEW_MOUNT/etc/systemd/system/multi-user.target.d/override.conf"
    echo ""
fi

echo ""
echo "=== SUMMARY ==="
echo "Comparison saved to: $OUTPUT_DIR/"
echo ""
echo "Key files:"
echo "  - systemd-etc.diff: Differences in /etc/systemd/system"
echo "  - systemd-lib.diff: Differences in /lib/systemd/system"
echo ""
echo "Next steps:"
echo "  1. Review differences"
echo "  2. Apply working configuration to new build"
echo "  3. Test new build"
