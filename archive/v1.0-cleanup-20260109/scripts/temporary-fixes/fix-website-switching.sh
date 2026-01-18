#!/bin/bash
# Fix Website Switching Issue - Remove index.html that blocks index.php
# Run on Pi: sudo bash fix-website-switching.sh

WEB_ROOT="/var/www/html"

echo "Fixing website switching issue..."

# Check if index.html exists
if [ -f "$WEB_ROOT/index.html" ]; then
    echo "Found index.html - removing it..."
    rm -f "$WEB_ROOT/index.html"
    echo "✅ Removed index.html"
    
    # Verify index.php exists
    if [ -f "$WEB_ROOT/index.php" ]; then
        echo "✅ index.php is present - website switching should work now"
    else
        echo "⚠️  index.php not found!"
    fi
else
    echo "✅ No index.html found - website switching should work"
fi

# Restart nginx to ensure changes take effect
systemctl restart nginx 2>/dev/null && echo "✅ nginx restarted" || echo "⚠️  Could not restart nginx"

echo ""
echo "Done! Try switching between pages now."
