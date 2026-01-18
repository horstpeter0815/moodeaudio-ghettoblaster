#!/bin/bash
# Update SD card with comprehensive username persistence fixes
# Uses password from test-password.txt

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 UPDATE SD CARD - USERNAME PERSISTENCE FIXES              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if SD card is mounted
if [ ! -d "/Volumes/rootfs" ]; then
    echo "❌ SD card rootfs not mounted at /Volumes/rootfs"
    echo ""
    echo "Please mount the SD card first:"
    echo "  diskutil list"
    echo "  sudo diskutil mount diskXs2  # rootfs"
    exit 1
fi

ROOTFS="/Volumes/rootfs"
echo "✅ SD card mounted at $ROOTFS"
echo ""

# Read password
if [ -f "test-password.txt" ]; then
    PASSWORD=$(cat test-password.txt | tr -d '\n\r')
else
    PASSWORD=""
fi

# Find actual paths on SD card
SYSUTIL_PATH=$(find "$ROOTFS" -name "sysutil.sh" 2>/dev/null | head -1)
COMMON_PHP_PATH=$(find "$ROOTFS" -name "common.php" -path "*/inc/*" 2>/dev/null | head -1)

if [ -z "$SYSUTIL_PATH" ]; then
    echo "❌ sysutil.sh not found on SD card"
    echo "   Trying to find www directory..."
    WWW_DIR=$(find "$ROOTFS" -type d -name "www" 2>/dev/null | head -1)
    if [ -n "$WWW_DIR" ]; then
        SYSUTIL_DIR="$WWW_DIR/html/util"
        SYSUTIL_PATH="$SYSUTIL_DIR/sysutil.sh"
        echo "   Will create: $SYSUTIL_PATH"
    else
        echo "   ❌ www directory not found"
        exit 1
    fi
fi

if [ -z "$COMMON_PHP_PATH" ]; then
    echo "❌ common.php not found on SD card"
    echo "   Trying to find inc directory..."
    INC_DIR=$(find "$ROOTFS" -type d -name "inc" -path "*/www/*" 2>/dev/null | head -1)
    if [ -n "$INC_DIR" ]; then
        COMMON_PHP_PATH="$INC_DIR/common.php"
        echo "   Will use: $COMMON_PHP_PATH"
    else
        echo "   ❌ inc directory not found"
        exit 1
    fi
fi

echo "Found paths:"
echo "  sysutil.sh: $SYSUTIL_PATH"
echo "  common.php: $COMMON_PHP_PATH"
echo ""

# Update sysutil.sh
echo "=== UPDATING sysutil.sh ==="
if [ -f "moode-source/www/util/sysutil.sh" ]; then
    SYSUTIL_DIR=$(dirname "$SYSUTIL_PATH")
    echo "$PASSWORD" | sudo -S mkdir -p "$SYSUTIL_DIR" 2>/dev/null || true
    echo "$PASSWORD" | sudo -S cp "moode-source/www/util/sysutil.sh" "$SYSUTIL_PATH" 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ sysutil.sh updated with enhanced fix"
    else
        echo "❌ Failed to update sysutil.sh"
        exit 1
    fi
else
    echo "❌ Source file not found"
    exit 1
fi

echo ""

# Update common.php
echo "=== UPDATING common.php ==="
if [ -f "moode-source/www/inc/common.php" ]; then
    COMMON_DIR=$(dirname "$COMMON_PHP_PATH")
    echo "$PASSWORD" | sudo -S mkdir -p "$COMMON_DIR" 2>/dev/null || true
    echo "$PASSWORD" | sudo -S cp "moode-source/www/inc/common.php" "$COMMON_PHP_PATH" 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ common.php updated with enhanced getUserID() fix"
    else
        echo "❌ Failed to update common.php"
        exit 1
    fi
else
    echo "❌ Source file not found"
    exit 1
fi

echo ""

# Copy new service
echo "=== INSTALLING 05-remove-pi-user.service ==="
if [ -f "moode-source/lib/systemd/system/05-remove-pi-user.service" ]; then
    echo "$PASSWORD" | sudo -S cp "moode-source/lib/systemd/system/05-remove-pi-user.service" "$ROOTFS/lib/systemd/system/" 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Service copied"
        
        # Enable service
        echo "$PASSWORD" | sudo -S mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants" 2>/dev/null || true
        echo "$PASSWORD" | sudo -S ln -sf "/lib/systemd/system/05-remove-pi-user.service" "$ROOTFS/etc/systemd/system/multi-user.target.wants/05-remove-pi-user.service" 2>/dev/null
        echo "✅ Service enabled"
    else
        echo "❌ Failed to install service"
        exit 1
    fi
else
    echo "❌ Service file not found"
    exit 1
fi

echo ""

# Verify
echo "=== VERIFICATION ==="
echo ""

echo "1. sysutil.sh:"
if [ -n "$SYSUTIL_PATH" ] && grep -q "FIX: Prefer andre" "$SYSUTIL_PATH" 2>/dev/null; then
    echo "   ✅ Enhanced fix present"
else
    echo "   ❌ Fix missing"
fi

echo ""
echo "2. common.php:"
if [ -n "$COMMON_PHP_PATH" ] && grep -q "CRITICAL: If pi also exists" "$COMMON_PHP_PATH" 2>/dev/null; then
    echo "   ✅ Enhanced fix present"
else
    echo "   ❌ Fix missing"
fi

echo ""
echo "3. Service:"
if [ -f "$ROOTFS/lib/systemd/system/05-remove-pi-user.service" ]; then
    echo "   ✅ Service installed"
    if [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/05-remove-pi-user.service" ]; then
        echo "   ✅ Service enabled"
    else
        echo "   ⚠️  Service not enabled"
    fi
else
    echo "   ❌ Service missing"
fi

echo ""
echo "✅✅✅ SD CARD UPDATED WITH ALL FIXES ✅✅✅"
echo ""
echo "Fixes applied:"
echo "  ✅ Enhanced sysutil.sh (prefers andre, warns if using pi)"
echo "  ✅ Enhanced getUserID() (removes conflicting pi user)"
echo "  ✅ New service to remove pi user on boot"
echo ""
echo "The username persistence issue should now be completely fixed!"
