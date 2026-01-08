#!/bin/bash
# Script Inventory Tool - Categorize all scripts in root directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

OUTPUT_FILE="$PROJECT_ROOT/SCRIPT_INVENTORY.md"

echo "# Script Inventory" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Generated:** $(date)" >> "$OUTPUT_FILE"
echo "**Total Scripts:** $(find . -maxdepth 1 -name "*.sh" -type f | wc -l | tr -d ' ')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Categories
declare -A categories
categories[network]="NETWORK|WIFI|ETHERNET|WLAN|DHCP|IP|CONNECTION|GHETTOBLASTER"
categories[build]="BUILD|START_BUILD|MONITOR_BUILD|CLEANUP.*BUILD"
categories[fix]="FIX|APPLY|RESTORE|REPAIR"
categories[test]="TEST|VERIFY|CHECK|VALIDATE"
categories[monitor]="MONITOR|STATUS|WATCH"
categories[deploy]="DEPLOY|BURN|COPY.*SD|INSTALL"
categories[wizard]="WIZARD|ROOM.*CORRECTION"
categories[setup]="SETUP|CONFIGURE|CREATE.*USER|ENABLE"
categories[audio]="AUDIO|CAMILLADSP|AMP100|PEPPY|SOUND"
categories[display]="DISPLAY|XINITRC|ROTATION|SCREEN"
categories[archive]="OLD|BACKUP|LEGACY|DEPRECATED"

echo "## Categories" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for category in "${!categories[@]}"; do
    pattern="${categories[$category]}"
    matches=$(find . -maxdepth 1 -name "*.sh" -type f | grep -iE "$pattern" | wc -l | tr -d ' ')
    echo "### $category: $matches scripts" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    find . -maxdepth 1 -name "*.sh" -type f | grep -iE "$pattern" | while read script; do
        basename_script=$(basename "$script")
        echo "- \`$basename_script\`" >> "$OUTPUT_FILE"
    done
    echo "" >> "$OUTPUT_FILE"
done

echo "## Uncategorized Scripts" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Find scripts that don't match any category
all_scripts=$(find . -maxdepth 1 -name "*.sh" -type f)
categorized=""
for category in "${!categories[@]}"; do
    pattern="${categories[$category]}"
    categorized="$categorized $(find . -maxdepth 1 -name "*.sh" -type f | grep -iE "$pattern")"
done

echo "$all_scripts" | while read script; do
    if ! echo "$categorized" | grep -q "$script"; then
        basename_script=$(basename "$script")
        echo "- \`$basename_script\`" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "**Next Steps:**" >> "$OUTPUT_FILE"
echo "1. Review categorized scripts" >> "$OUTPUT_FILE"
echo "2. Move to appropriate directories" >> "$OUTPUT_FILE"
echo "3. Archive old/unused scripts" >> "$OUTPUT_FILE"

echo "✅ Inventory created: $OUTPUT_FILE"

