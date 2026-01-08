#!/bin/bash
# Deploy Room Correction Wizard to SD Card
# Run: sudo ./deploy-wizard-to-sd.sh

set -e

ROOTFS_MOUNT="/Volumes/rootfs"
BOOTFS_MOUNT="/Volumes/bootfs"

echo "=== Room Correction Wizard Deployment ==="
echo ""

# Check if SD card is mounted
if [ ! -d "$ROOTFS_MOUNT" ]; then
    echo "❌ ERROR: SD card rootfs not mounted at $ROOTFS_MOUNT"
    echo "Please mount the SD card first"
    exit 1
fi

echo "✅ SD card rootfs found at: $ROOTFS_MOUNT"
echo ""

# Create directories if they don't exist
echo "📁 Creating directories..."
mkdir -p "$ROOTFS_MOUNT/var/www/html/test-wizard"
mkdir -p "$ROOTFS_MOUNT/var/www/html/command"
mkdir -p "$ROOTFS_MOUNT/var/www/html/templates"
mkdir -p "$ROOTFS_MOUNT/usr/local/bin"
echo "✅ Directories created"
echo ""

# Copy wizard files
echo "📋 Copying wizard files..."

# 1. Wizard JavaScript functions
if [ -f "test-wizard/wizard-functions.js" ]; then
    echo "  → Copying wizard-functions.js..."
    cp "test-wizard/wizard-functions.js" "$ROOTFS_MOUNT/var/www/html/test-wizard/wizard-functions.js"
    chmod 644 "$ROOTFS_MOUNT/var/www/html/test-wizard/wizard-functions.js"
    echo "  ✅ wizard-functions.js copied"
else
    echo "  ⚠️  WARNING: test-wizard/wizard-functions.js not found"
fi

# 2. Backend PHP
if [ -f "moode-source/www/command/room-correction-wizard.php" ]; then
    echo "  → Copying room-correction-wizard.php..."
    cp "moode-source/www/command/room-correction-wizard.php" "$ROOTFS_MOUNT/var/www/html/command/room-correction-wizard.php"
    chmod 644 "$ROOTFS_MOUNT/var/www/html/command/room-correction-wizard.php"
    echo "  ✅ room-correction-wizard.php copied"
else
    echo "  ⚠️  WARNING: moode-source/www/command/room-correction-wizard.php not found"
fi

# 3. Wizard HTML template (if exists)
if [ -f "moode-source/www/templates/snd-config.html" ]; then
    echo "  → Copying snd-config.html..."
    cp "moode-source/www/templates/snd-config.html" "$ROOTFS_MOUNT/var/www/html/templates/snd-config.html"
    chmod 644 "$ROOTFS_MOUNT/var/www/html/templates/snd-config.html"
    echo "  ✅ snd-config.html copied"
else
    echo "  ⚠️  WARNING: moode-source/www/templates/snd-config.html not found"
fi

# 4. Python scripts
if [ -f "moode-source/usr/local/bin/generate-camilladsp-eq.py" ]; then
    echo "  → Copying generate-camilladsp-eq.py..."
    cp "moode-source/usr/local/bin/generate-camilladsp-eq.py" "$ROOTFS_MOUNT/usr/local/bin/generate-camilladsp-eq.py"
    chmod 755 "$ROOTFS_MOUNT/usr/local/bin/generate-camilladsp-eq.py"
    echo "  ✅ generate-camilladsp-eq.py copied"
else
    echo "  ⚠️  WARNING: generate-camilladsp-eq.py not found"
fi

if [ -f "moode-source/usr/local/bin/analyze-measurement.py" ]; then
    echo "  → Copying analyze-measurement.py..."
    cp "moode-source/usr/local/bin/analyze-measurement.py" "$ROOTFS_MOUNT/usr/local/bin/analyze-measurement.py"
    chmod 755 "$ROOTFS_MOUNT/usr/local/bin/analyze-measurement.py"
    echo "  ✅ analyze-measurement.py copied"
else
    echo "  ⚠️  WARNING: analyze-measurement.py not found"
fi

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "✅ Files copied to SD card"
echo ""
echo "📋 Next Steps:"
echo "1. Eject SD card safely: diskutil eject /dev/disk4"
echo "2. Boot Raspberry Pi"
echo "3. Access moOde web interface"
echo "4. Test wizard: Audio page → Run Wizard"
echo ""
echo "🎯 Files deployed:"
echo "  - /var/www/html/test-wizard/wizard-functions.js"
echo "  - /var/www/html/command/room-correction-wizard.php"
echo "  - /var/www/html/templates/snd-config.html (if exists)"
echo "  - /usr/local/bin/generate-camilladsp-eq.py"
echo "  - /usr/local/bin/analyze-measurement.py"
echo ""

