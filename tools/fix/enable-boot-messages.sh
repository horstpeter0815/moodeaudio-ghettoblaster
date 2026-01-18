#!/bin/bash
################################################################################
# Enable Boot Messages for Debugging
# 
# Removes 'quiet' and changes loglevel to show boot messages
# Useful when boot screen appears blank
################################################################################

set -e

BOOTFS="${1:-/Volumes/bootfs}"
CMDLINE="$BOOTFS/cmdline.txt"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ ERROR: Boot partition not found at $BOOTFS"
    echo "   Please insert SD card or specify path: $0 /path/to/bootfs"
    exit 1
fi

if [ ! -f "$CMDLINE" ]; then
    echo "❌ ERROR: cmdline.txt not found at $CMDLINE"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 ENABLE BOOT MESSAGES FOR DEBUGGING                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Backup
BACKUP="$CMDLINE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CMDLINE" "$BACKUP"
echo "✅ Backup created: $BACKUP"
echo ""

echo "Current cmdline.txt:"
cat "$CMDLINE"
echo ""

# Remove quiet, change loglevel to 7 (verbose)
python3 << 'PYTHON'
import sys
import re

cmdline_file = sys.argv[1]

with open(cmdline_file, 'r') as f:
    cmdline = f.read().strip()

# Remove quiet
cmdline = re.sub(r'\bquiet\b', '', cmdline)

# Change loglevel to 7 (verbose)
cmdline = re.sub(r'\bloglevel=\d+\b', 'loglevel=7', cmdline)
if 'loglevel=' not in cmdline:
    cmdline = cmdline + ' loglevel=7'

# Remove logo.nologo (optional - keep if you want)
# cmdline = re.sub(r'\blogo\.nologo\b', '', cmdline)

# Clean up multiple spaces
cmdline = re.sub(r'\s+', ' ', cmdline).strip()

with open(cmdline_file, 'w') as f:
    f.write(cmdline + '\n')

print("✅ Removed 'quiet', set loglevel=7 (verbose)")
print("")
print("New cmdline.txt:")
print(cmdline)

PYTHON
"$CMDLINE"

echo ""
echo "✅ Boot messages enabled!"
echo ""
echo "Next steps:"
echo "  1. Eject SD card: diskutil eject /dev/disk4"
echo "  2. Insert SD card into Pi"
echo "  3. Boot Pi - you should now see boot messages"
echo ""
