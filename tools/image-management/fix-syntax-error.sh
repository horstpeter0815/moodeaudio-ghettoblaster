#!/bin/bash
#########################################################################
# Fix Syntax Error at Line 152
# This tool helps identify and fix boot syntax errors
#########################################################################

set -e

echo "========================================="
echo "FIX SYNTAX ERROR AT LINE 152"
echo "========================================="
echo ""

# Check if SD card is mounted
if [ ! -d "/Volumes/rootfs" ]; then
    echo "Mounting SD card..."
    diskutil mount disk4s1
    diskutil mount disk4s2
    sleep 2
fi

echo "=== Searching for syntax errors ==="
echo ""

# Check all .sh files
FOUND=0
find /Volumes/rootfs -name "*.sh" -type f 2>/dev/null | while read script; do
    error=$(bash -n "$script" 2>&1)
    if [ -n "$error" ]; then
        echo "❌ ERROR in: $script"
        echo "$error"
        FOUND=1
        
        # Show the problematic area
        if echo "$error" | grep -q "line 152"; then
            echo ""
            echo "Content around line 152:"
            sed -n '148,156p' "$script" | cat -n
        fi
        echo ""
    fi
done

# If no errors found, check for other common issues
if [ $FOUND -eq 0 ]; then
    echo "No syntax errors found in shell scripts."
    echo ""
    echo "=== Other potential issues ==="
    echo ""
    
    # Check cmdline.txt has only one line
    echo "cmdline.txt lines:"
    wc -l /Volumes/bootfs/cmdline.txt
    
    # Check for weird characters
    echo ""
    echo "Checking for non-ASCII characters in cmdline.txt..."
    LC_ALL=C grep -n '[^[:print:][:space:]]' /Volumes/bootfs/cmdline.txt || echo "  None found (good)"
    
    echo ""
    echo "=== Possible fixes ==="
    echo "1. Disable X11 auto-start (boot to console)"
    echo "2. Reset .xinitrc to default"
    echo "3. Check systemd services"
    echo ""
    read -p "Try fix #1 (disable X11)? (yes/no): " FIX
    
    if [ "$FIX" = "yes" ]; then
        echo "Disabling local display..."
        sqlite3 /Volumes/rootfs/var/local/www/db/moode-sqlite3.db \
          "UPDATE cfg_system SET value='0' WHERE param='local_display';"
        echo "✅ Local display disabled - will boot to console"
        echo "   You can SSH in to debug further"
    fi
fi

echo ""
echo "========================================="
echo "Done! Eject SD card and try booting again"
echo "========================================="
