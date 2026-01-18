#!/bin/bash
# Fix Radio Station Display and Logo Issues
# Run this on the Pi: sudo bash fix-radio-display.sh

set -e

echo "================================================"
echo "  Fixing Radio Station Display Issues"
echo "================================================"
echo ""

MOODE_DB="/var/local/www/db/moode-sqlite3.db"
RADIO_LOGOS_DIR="/var/local/www/imagesw/radio-logos"
THUMBS_DIR="$RADIO_LOGOS_DIR/thumbs"

# Fix 1: Create directories if missing
echo "1. Creating directories..."
mkdir -p "$RADIO_LOGOS_DIR"
mkdir -p "$THUMBS_DIR"
echo "✅ Directories created"

# Fix 2: Fix permissions
echo "2. Fixing permissions..."
chown -R www-data:www-data /var/local/www/imagesw/radio-logos
chmod -R 755 /var/local/www/imagesw/radio-logos
echo "✅ Permissions fixed"

# Fix 3: Check database and fix logo paths
echo "3. Checking database..."
if [ -f "$MOODE_DB" ]; then
    # Count stations
    RADIO_COUNT=$(sqlite3 "$MOODE_DB" "SELECT COUNT(*) FROM cfg_radio;" 2>/dev/null || echo "0")
    echo "Found $RADIO_COUNT radio stations"
    
    # Check for stations with missing logos
    MISSING_LOGOS=$(sqlite3 "$MOODE_DB" "SELECT name FROM cfg_radio WHERE logo = '' OR logo IS NULL;" 2>/dev/null || echo "")
    
    if [ -n "$MISSING_LOGOS" ]; then
        echo "Stations with missing logos:"
        echo "$MISSING_LOGOS"
        echo ""
        echo "⚠️  These stations need logos added via moOde Web UI"
    fi
    
    # Check for stations with local logos that don't exist
    sqlite3 "$MOODE_DB" "SELECT name, logo FROM cfg_radio WHERE logo LIKE 'local%' OR logo LIKE 'imagesw%';" 2>/dev/null | while IFS='|' read name logo; do
        if [ -n "$name" ] && [ -n "$logo" ]; then
            # Check if logo file exists
            if [[ "$logo" == "local" ]]; then
                LOGO_FILE="$THUMBS_DIR/${name}.jpg"
                if [ ! -f "$LOGO_FILE" ]; then
                    echo "⚠️  Missing logo for: $name (expected: $LOGO_FILE)"
                fi
            fi
        fi
    done
    
    echo "✅ Database checked"
else
    echo "❌ Database not found"
fi
echo ""

# Fix 4: Restart web services
echo "4. Restarting web services..."
systemctl restart nginx 2>/dev/null || echo "⚠️  Could not restart nginx"
systemctl restart php8.4-fpm 2>/dev/null || systemctl restart php*-fpm 2>/dev/null || echo "⚠️  Could not restart PHP-FPM"
echo "✅ Web services restarted"
echo ""

# Fix 5: Clear browser cache recommendation
echo "================================================"
echo "  Fix Complete"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Clear your browser cache (Ctrl+Shift+Delete)"
echo "  2. Hard refresh moOde web interface (Ctrl+F5)"
echo "  3. Check radio stations display"
echo ""
echo "If logos are still missing:"
echo "  - Logos may download automatically when stations are played"
echo "  - Or add logos manually via moOde Web UI → Radio → Edit station"
echo ""
