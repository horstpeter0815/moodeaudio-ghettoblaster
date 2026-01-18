#!/bin/bash
################################################################################
# START FINAL BUILD - ALL FIXES APPLIED
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 FINAL BUILD - ALL FIXES APPLIED                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Verify all fixes are in place
echo "📋 Verifying fixes..."
echo ""

# 1. Check config file
if grep -q "FIRST_USER_NAME=andre" imgbuild/pi-gen-64/config && \
   grep -q "DISABLE_FIRST_BOOT_USER_RENAME=1" imgbuild/pi-gen-64/config; then
    echo "✅ config: FIRST_USER_NAME=andre, DISABLE_FIRST_BOOT_USER_RENAME=1"
else
    echo "❌ config: Missing user configuration!"
    exit 1
fi

# 2. Check cmdline.txt has fbcon=rotate:3
if grep -q "fbcon=rotate:3" imgbuild/pi-gen-64/stage1/00-boot-files/files/cmdline.txt; then
    echo "✅ cmdline.txt: fbcon=rotate:3 present"
else
    echo "❌ cmdline.txt: Missing fbcon=rotate:3!"
    exit 1
fi

# 3. Check config.txt.overwrite has display_rotate=2
if grep -q "display_rotate=2" moode-source/boot/firmware/config.txt.overwrite; then
    echo "✅ config.txt.overwrite: display_rotate=2 present"
else
    echo "❌ config.txt.overwrite: Missing display_rotate=2!"
    exit 1
fi

# 4. Check worker.php is patched
if grep -q "Required headers present.*FIX" moode-source/www/daemon/worker.php; then
    echo "✅ worker.php: Overwrite protection active"
else
    echo "❌ worker.php: Overwrite protection NOT active!"
    exit 1
fi

# 5. Check export-image/prerun.sh excludes config.txt
if grep -q "exclude config.txt" imgbuild/pi-gen-64/export-image/prerun.sh; then
    echo "✅ export-image/prerun.sh: config.txt excluded from rsync"
else
    echo "❌ export-image/prerun.sh: config.txt NOT excluded!"
    exit 1
fi

echo ""
echo "✅ ALL FIXES VERIFIED!"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "🐳 Starting Docker..."
    open -a Docker
    echo "⏳ Waiting for Docker to start..."
    sleep 10
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker failed to start!"
        exit 1
    fi
fi
echo "✅ Docker is running"
echo ""

# Clean up old containers
echo "🧹 Cleaning up old containers..."
docker-compose -f docker-compose.build.yml down --remove-orphans 2>/dev/null || true
docker rm -f moode-builder 2>/dev/null || true
echo "✅ Cleanup complete"
echo ""

# Start Docker build container
echo "🐳 Starting Docker build container..."
docker-compose -f docker-compose.build.yml up -d --build --remove-orphans
if [ $? -ne 0 ]; then
    echo "❌ Failed to start Docker container!"
    exit 1
fi
echo "✅ Docker container started"
echo ""

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 5

# Apply fixes inside container
echo "🔧 Applying fixes inside container..."
docker exec moode-builder git config --global --add safe.directory /workspace/imgbuild/pi-gen-64 2>/dev/null || true
docker exec moode-builder bash -c "apt-get update >/dev/null 2>&1 && apt-get install -y quilt parted qemu-user-static debootstrap zerofree dosfstools e2fsprogs libcap2-bin kmod pigz arch-test >/dev/null 2>&1" || true
docker exec moode-builder bash -c "if [ ! -f /etc/mtab ]; then ln -s /proc/mounts /etc/mtab; fi" || true
echo "✅ Fixes applied"
echo ""

# Start build
echo "🚀 Starting build..."
echo "   This will take 8-12 hours..."
echo "   Logs: docker-compose -f docker-compose.build.yml logs -f"
echo ""

BUILD_LOG="imgbuild/build-$(date +%Y%m%d_%H%M%S).log"
docker exec -d moode-builder bash -c "cd /workspace/imgbuild && sudo ./build.sh > $BUILD_LOG 2>&1"

if [ $? -eq 0 ]; then
    echo "✅ Build started successfully!"
    echo ""
    echo "📋 Monitor build progress:"
    echo "   docker-compose -f docker-compose.build.yml logs -f"
    echo ""
    echo "📁 Build log: $BUILD_LOG"
    echo ""
    echo "⏳ Build will complete in 8-12 hours"
    echo "   Image will be in: imgbuild/deploy/"
else
    echo "❌ Failed to start build!"
    exit 1
fi

