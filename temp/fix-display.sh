#!/bin/bash
# Fix display - set display_rotate=0 and ensure config.txt exists

CONFIG="/boot/firmware/config.txt"

# Ensure config.txt exists
if [ ! -f "$CONFIG" ]; then
    echo "# moOde config.txt" > "$CONFIG"
fi

# Remove any existing display_rotate line
sed -i '/^display_rotate=/d' "$CONFIG" 2>/dev/null || sed -i '' '/^display_rotate=/d' "$CONFIG" 2>/dev/null || true

# Add display_rotate=0 (landscape)
echo "display_rotate=0" >> "$CONFIG"

echo "✅ Display fixed: display_rotate=0"
