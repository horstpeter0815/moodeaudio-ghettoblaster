#!/bin/bash
# Test Image in Docker Container

IMAGE_PATH=$(docker exec moode-builder bash -c "find /tmp/pi-gen-work -name '*.img' -size +100M 2>/dev/null | head -1")

if [ -z "$IMAGE_PATH" ]; then
    echo "❌ Image nicht gefunden im Container"
    exit 1
fi

echo "✅ Image gefunden: $IMAGE_PATH"
echo ""

# Create test script in container
docker exec moode-builder bash -c 'cat > /tmp/test-image.sh << '\''TESTEOF'\''
#!/bin/bash
IMAGE_PATH="$1"
LOOP=$(losetup -f)
losetup -P $LOOP "$IMAGE_PATH"

if [ ! -e ${LOOP}p1 ] || [ ! -e ${LOOP}p2 ]; then
    echo "❌ Partitionen nicht gefunden"
    losetup -d $LOOP 2>/dev/null || true
    exit 1
fi

BOOT_TMP=$(mktemp -d)
ROOT_TMP=$(mktemp -d)
mount ${LOOP}p1 $BOOT_TMP
mount ${LOOP}p2 $ROOT_TMP

echo "=== TEST ERGEBNISSE ==="
echo ""

echo "📋 Boot-Partition (config.txt.overwrite):"
if [ -f $BOOT_TMP/config.txt.overwrite ]; then
    echo "✅ config.txt.overwrite gefunden"
    grep -E "display_rotate|hdmi_force_mode|Ghettoblaster" $BOOT_TMP/config.txt.overwrite | head -5
else
    echo "❌ config.txt.overwrite NICHT gefunden"
fi

echo ""
echo "📋 Root-Partition (Services):"
ls -la $ROOT_TMP/lib/systemd/system/ 2>/dev/null | grep -E "localdisplay|fix-ssh|enable-ssh|fix-user|disable-console" | head -10

echo ""
echo "📋 Root-Partition (Scripts):"
ls -la $ROOT_TMP/usr/local/bin/ 2>/dev/null | grep -E "start-chromium|xserver-ready|worker-php-patch" | head -10

echo ""
echo "📋 User andre:"
if [ -d $ROOT_TMP/home/andre ]; then
    echo "✅ /home/andre gefunden"
    ls -la $ROOT_TMP/home/andre | head -5
else
    echo "❌ /home/andre NICHT gefunden"
fi

umount $BOOT_TMP $ROOT_TMP 2>/dev/null || true
rmdir $BOOT_TMP $ROOT_TMP 2>/dev/null || true
losetup -d $LOOP 2>/dev/null || true
TESTEOF
chmod +x /tmp/test-image.sh
'

# Run test
docker exec moode-builder bash -c "/tmp/test-image.sh '$IMAGE_PATH'"

