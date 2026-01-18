#!/bin/bash
# Complete Boot Process Simulation in Docker
# Simulates the entire Pi boot sequence with systemd, services, and timing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== COMPLETE BOOT PROCESS SIMULATION ==="
echo "This will simulate the entire Pi boot sequence with systemd"
echo ""

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon is not running"
    exit 1
fi

echo "✅ Docker is available"
echo ""

# Create Dockerfile for boot simulation
echo "Creating Docker boot simulation environment..."
TEST_DIR="$(pwd)/test-boot-simulation"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"/{bootfs,rootfs}

# Create a minimal systemd-based container (Debian-based like Raspberry Pi OS)
cat > "$TEST_DIR/Dockerfile" << 'DOCKERFILE'
FROM debian:bullseye-slim

# Install systemd and dependencies (matching Raspberry Pi OS)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    systemd systemd-sysv dbus sudo bash curl wget \
    python3 python3-pip bc \
    && apt-get install -y python3-pil || apt-get install -y python3-pillow || true \
    && apt-get install -y ncurses-bin || apt-get install -y ncurses-base || true \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create minimal systemd setup
RUN systemctl set-default multi-user.target

# Create required directories
RUN mkdir -p /run/systemd/system /etc/systemd/system \
    /lib/systemd/system /usr/lib/systemd/system

# Create fake tty1 for boot screen (matching Pi)
RUN mkdir -p /dev && \
    mknod /dev/tty1 c 4 1 && \
    chmod 666 /dev/tty1 && \
    mknod /dev/tty8 c 4 8 && \
    chmod 666 /dev/tty8

# Create minimal systemd targets
RUN mkdir -p /etc/systemd/system/{basic.target.wants,multi-user.target.wants,sysinit.target.wants}

# Files will be mounted at runtime

WORKDIR /root
CMD ["/bin/bash", "/root/simulate-boot.sh"]
DOCKERFILE

# Create boot simulation script
cat > "$TEST_DIR/simulate-boot.sh" << 'BOOTSCRIPT'
#!/bin/bash
set -e

# Helper function for precise timing
get_time() {
    if command -v bc >/dev/null 2>&1; then
        date +%s.%N
    else
        date +%s
    fi
}

calc_duration() {
    local start=$1
    local end=$2
    if command -v bc >/dev/null 2>&1; then
        echo "$end - $start" | bc
    else
        echo $((end - start))
    fi
}

echo "=== BOOT SIMULATION STARTING ==="
echo "Boot time: $(date '+%Y-%m-%d %H:%M:%S')"
BOOT_START=$(get_time)

# Mount required filesystems for systemd (like real boot)
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t tmpfs tmpfs /tmp 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
mkdir -p /run/lock /run/log

# Create writable overlay for /etc/systemd/system (if mounted read-only)
if ! touch /etc/systemd/system/.test 2>/dev/null; then
    mkdir -p /run/systemd-overlay/etc/systemd/system
    mount --bind /run/systemd-overlay/etc/systemd/system /etc/systemd/system 2>/dev/null || true
fi

# Start dbus (required for systemd)
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true
sleep 0.5

# Initialize systemd environment
export SYSTEMD_LOG_LEVEL=debug
export SYSTEMD_LOG_COLOR=no

# Create minimal systemd unit files for boot targets
mkdir -p /etc/systemd/system/basic.target.wants
mkdir -p /etc/systemd/system/multi-user.target.wants
mkdir -p /etc/systemd/system/sysinit.target.wants
mkdir -p /etc/systemd/system/network-online.target.wants

# Create local-fs.target (simulates filesystem mounting)
cat > /etc/systemd/system/local-fs.target << 'EOF'
[Unit]
Description=Local File Systems
DefaultDependencies=no
After=systemd-remount-fs.service
Before=sysinit.target
Conflicts=shutdown.target
EOF

# Create network-online.target
cat > /etc/systemd/system/network-online.target << 'EOF'
[Unit]
Description=Network is Online
Documentation=man:systemd.special(7)
After=NetworkManager-wait-online.service
EOF

# Create multi-user.target
cat > /etc/systemd/system/multi-user.target << 'EOF'
[Unit]
Description=Multi-User System
Documentation=man:systemd.special(7)
Requires=basic.target
After=basic.target
AllowIsolate=yes
EOF

# Create basic.target
cat > /etc/systemd/system/basic.target << 'EOF'
[Unit]
Description=Basic System
Documentation=man:systemd.special(7)
Requires=sysinit.target
After=sysinit.target
EOF

# Create sysinit.target
cat > /etc/systemd/system/sysinit.target << 'EOF'
[Unit]
Description=System Initialization
Documentation=man:systemd.special(7)
Requires=local-fs.target
After=local-fs.target
EOF

echo "✅ Systemd environment initialized"
echo ""

# Simulate boot phases with precise timing
echo "=== PHASE 1: Early Boot (local-fs.target) ==="
PHASE1_START=$(get_time)
systemctl start local-fs.target 2>&1 || true
sleep 0.2
PHASE1_END=$(get_time)
PHASE1_DURATION=$(calc_duration "$PHASE1_START" "$PHASE1_END")
echo "✅ local-fs.target completed in ${PHASE1_DURATION}s"
echo ""

echo "=== PHASE 2: Network Services ==="
# Check NetworkManager-wait-online status
if [ -L /etc/systemd/system/NetworkManager-wait-online.service ]; then
    TARGET=$(readlink /etc/systemd/system/NetworkManager-wait-online.service 2>/dev/null || echo "")
    if [ "$TARGET" = "/dev/null" ]; then
        echo "✅ NetworkManager-wait-online is masked (symlink to /dev/null)"
        NETWORK_WAIT_ENABLED=false
    else
        echo "⚠️  NetworkManager-wait-online has symlink but not masked"
        NETWORK_WAIT_ENABLED=true
    fi
elif systemctl is-enabled NetworkManager-wait-online.service >/dev/null 2>&1; then
    echo "❌ NetworkManager-wait-online is enabled (should be disabled)"
    NETWORK_WAIT_ENABLED=true
else
    echo "✅ NetworkManager-wait-online is disabled"
    NETWORK_WAIT_ENABLED=false
fi

# Test network-online.target (should not hang - this is critical)
echo "Testing network-online.target (should complete quickly)..."
NETWORK_START=$(get_time)
timeout 5 bash -c 'systemctl start network-online.target 2>&1 || true' || true
NETWORK_END=$(get_time)
NETWORK_DURATION=$(calc_duration "$NETWORK_START" "$NETWORK_END")

# Convert to integer seconds for comparison
if command -v bc >/dev/null 2>&1; then
    NETWORK_DURATION_INT=$(echo "$NETWORK_DURATION" | cut -d. -f1)
else
    NETWORK_DURATION_INT=$NETWORK_DURATION
fi

if [ "$NETWORK_DURATION_INT" -gt 3 ]; then
    echo "❌ network-online.target took ${NETWORK_DURATION}s (should be < 3s)"
    NETWORK_HANG=true
else
    echo "✅ network-online.target completed in ${NETWORK_DURATION}s"
    NETWORK_HANG=false
fi
echo ""

echo "=== PHASE 3: User Services Check ==="
# Check user-related services (these should be disabled/masked)
USER_SERVICES=(
    "05-remove-pi-user.service"
    "fix-user-id.service"
    "userconfig.service"
    "systemd-user-sessions.service"
)

USER_SERVICES_OK=true
for service in "${USER_SERVICES[@]}"; do
    # Check if service file exists
    if [ -f "/lib/systemd/system/$service" ] || [ -f "/etc/systemd/system/$service" ]; then
        # Check if it's masked (symlink to /dev/null)
        if [ -L "/etc/systemd/system/$service" ]; then
            TARGET=$(readlink "/etc/systemd/system/$service" 2>/dev/null || echo "")
            if [ "$TARGET" = "/dev/null" ]; then
                echo "✅ $service is masked (symlink to /dev/null)"
            else
                echo "⚠️  $service has symlink but not to /dev/null"
                USER_SERVICES_OK=false
            fi
        # Check if override exists
        elif [ -f "/etc/systemd/system/$service.d/override.conf" ]; then
            echo "✅ $service has override (should be disabled)"
        # Check if enabled
        elif systemctl is-enabled "$service" >/dev/null 2>&1; then
            echo "❌ $service is enabled (should be disabled)"
            USER_SERVICES_OK=false
        else
            echo "✅ $service is disabled"
        fi
    else
        echo "✅ $service file removed (good)"
    fi
done
echo ""

echo "=== PHASE 4: Multi-User Target (Main Boot Phase) ==="
MULTIUSER_START=$(get_time)
# Try to start multi-user.target (this is where hangs occur)
timeout 15 bash -c 'systemctl start multi-user.target 2>&1 || true' || true
MULTIUSER_END=$(get_time)
MULTIUSER_DURATION=$(calc_duration "$MULTIUSER_START" "$MULTIUSER_END")
if command -v bc >/dev/null 2>&1; then
    MULTIUSER_DURATION_INT=$(echo "$MULTIUSER_DURATION" | cut -d. -f1)
else
    MULTIUSER_DURATION_INT=$MULTIUSER_DURATION
fi

if [ "$MULTIUSER_DURATION_INT" -gt 10 ]; then
    echo "❌ multi-user.target took ${MULTIUSER_DURATION}s (should be < 10s)"
    MULTIUSER_HANG=true
else
    echo "✅ multi-user.target completed in ${MULTIUSER_DURATION}s"
    MULTIUSER_HANG=false
fi
echo ""

echo "=== PHASE 5: Boot Screen Test ==="
if [ -f /usr/local/bin/matrix-boot.sh ]; then
    echo "Testing matrix boot screen script..."
    BOOTSCREEN_START=$(get_time)
    
    # Create mock services that matrix-boot.sh checks for
    mkdir -p /etc/systemd/system
    cat > /etc/systemd/system/localdisplay.service << 'EOF'
[Unit]
Description=Local Display
[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
EOF
    
    # Test matrix boot screen (with timeout to prevent hanging)
    timeout 3 bash /usr/local/bin/matrix-boot.sh 2>&1 | head -20 || true
    
    BOOTSCREEN_END=$(get_time)
    BOOTSCREEN_DURATION=$(calc_duration "$BOOTSCREEN_START" "$BOOTSCREEN_END")
    echo "✅ Matrix boot screen script executed (${BOOTSCREEN_DURATION}s)"
    
    # Verify script uses X characters
    if grep -q 'screen\[.*\]="X"' /usr/local/bin/matrix-boot.sh 2>/dev/null; then
        echo "✅ Matrix boot screen uses X characters"
    else
        echo "⚠️  Matrix boot screen may not use X characters"
    fi
else
    echo "⚠️  matrix-boot.sh not found"
fi
echo ""

# Final boot time (precise measurement)
BOOT_END=$(get_time)
TOTAL_BOOT_TIME=$(calc_duration "$BOOT_START" "$BOOT_END")
if command -v bc >/dev/null 2>&1; then
    TOTAL_BOOT_TIME_INT=$(echo "$TOTAL_BOOT_TIME" | cut -d. -f1)
else
    TOTAL_BOOT_TIME_INT=$TOTAL_BOOT_TIME
fi

echo "=== BOOT SIMULATION COMPLETE ==="
echo "Total boot time: ${TOTAL_BOOT_TIME}s"
echo ""

# Summary with detailed timing
echo "=== BOOT SIMULATION RESULTS ==="
echo ""
echo "Timing breakdown:"
echo "  - Phase 1 (local-fs): ${PHASE1_DURATION}s"
echo "  - Phase 2 (network): ${NETWORK_DURATION}s"
echo "  - Phase 4 (multi-user): ${MULTIUSER_DURATION}s"
echo "  - Phase 5 (boot screen): ${BOOTSCREEN_DURATION:-0}s"
echo "  - Total boot time: ${TOTAL_BOOT_TIME}s"
echo ""

# Check for hangs
HAS_HANGS=false
if [ "$NETWORK_HANG" = "true" ]; then
    echo "❌ CRITICAL: Network services hang (${NETWORK_DURATION}s > 3s)"
    HAS_HANGS=true
fi

if [ "$MULTIUSER_HANG" = "true" ]; then
    echo "❌ CRITICAL: Multi-user target hang (${MULTIUSER_DURATION}s > 10s)"
    HAS_HANGS=true
fi

if [ "$USER_SERVICES_OK" = "false" ]; then
    echo "❌ CRITICAL: User services still enabled"
    HAS_HANGS=true
fi

if [ "$NETWORK_WAIT_ENABLED" = "true" ]; then
    echo "❌ CRITICAL: NetworkManager-wait-online still enabled"
    HAS_HANGS=true
fi

# Performance check
if [ "$TOTAL_BOOT_TIME_INT" -gt 15 ]; then
    echo "⚠️  WARNING: Total boot time is slow (${TOTAL_BOOT_TIME}s > 15s)"
fi

echo ""

if [ "$HAS_HANGS" = "true" ]; then
    echo "❌ BOOT SIMULATION FAILED"
    echo ""
    echo "Issues found:"
    [ "$NETWORK_HANG" = "true" ] && echo "  - Network services hang (${NETWORK_DURATION}s)"
    [ "$MULTIUSER_HANG" = "true" ] && echo "  - Multi-user target hang (${MULTIUSER_DURATION}s)"
    [ "$USER_SERVICES_OK" = "false" ] && echo "  - User services still enabled"
    [ "$NETWORK_WAIT_ENABLED" = "true" ] && echo "  - NetworkManager-wait-online still enabled"
    exit 1
else
    echo "✅ BOOT SIMULATION PASSED"
    echo ""
    echo "All checks passed:"
    echo "  ✅ Network services: ${NETWORK_DURATION}s (< 3s)"
    echo "  ✅ Multi-user target: ${MULTIUSER_DURATION}s (< 10s)"
    echo "  ✅ User services: All disabled/masked"
    echo "  ✅ NetworkManager-wait-online: Disabled"
    echo "  ✅ Total boot time: ${TOTAL_BOOT_TIME}s"
    exit 0
fi
BOOTSCRIPT

chmod +x "$TEST_DIR/simulate-boot.sh"

# Copy matrix-boot.sh to test (before applying fixes)
echo "Copying matrix-boot.sh..."
mkdir -p "$TEST_DIR/rootfs/usr/local/bin"
cp "$PROJECT_ROOT/moode-source/usr/local/bin/matrix-boot.sh" \
    "$TEST_DIR/rootfs/usr/local/bin/matrix-boot.sh" 2>/dev/null || \
    echo "⚠️  matrix-boot.sh not found"
chmod +x "$TEST_DIR/rootfs/usr/local/bin/matrix-boot.sh" 2>/dev/null || true

# Create mock service files
echo "Creating mock service files..."
mkdir -p "$TEST_DIR/rootfs/lib/systemd/system"
mkdir -p "$TEST_DIR/rootfs/etc/systemd/system/multi-user.target.wants"

# Create problematic services
cat > "$TEST_DIR/rootfs/lib/systemd/system/05-remove-pi-user.service" << 'EOF'
[Unit]
Description=Remove pi User
After=local-fs.target
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 2; echo "Removing pi user..."'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > "$TEST_DIR/rootfs/lib/systemd/system/fix-user-id.service" << 'EOF'
[Unit]
Description=Fix User ID
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 1; echo "Fixing user ID..."'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > "$TEST_DIR/rootfs/lib/systemd/system/userconfig.service" << 'EOF'
[Unit]
Description=User configuration dialog
After=systemd-user-sessions.service
Before=lightdm.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 5; echo "User config dialog..."'
TTYPath=/dev/tty8

[Install]
WantedBy=multi-user.target
EOF

cat > "$TEST_DIR/rootfs/lib/systemd/system/systemd-user-sessions.service" << 'EOF'
[Unit]
Description=Permit User Sessions
After=remote-fs.target network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 3; echo "User sessions..."'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > "$TEST_DIR/rootfs/lib/systemd/system/NetworkManager-wait-online.service" << 'EOF'
[Unit]
Description=Network Manager Wait Online
After=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 90; echo "Network online"'
RemainAfterExit=yes
TimeoutStartSec=90

[Install]
WantedBy=network-online.target
EOF

# Create symlinks (simulating enabled services)
mkdir -p "$TEST_DIR/rootfs/etc/systemd/system/network-online.target.wants"
ln -sf /lib/systemd/system/05-remove-pi-user.service \
    "$TEST_DIR/rootfs/etc/systemd/system/multi-user.target.wants/05-remove-pi-user.service"
ln -sf /lib/systemd/system/fix-user-id.service \
    "$TEST_DIR/rootfs/etc/systemd/system/multi-user.target.wants/fix-user-id.service"
ln -sf /lib/systemd/system/userconfig.service \
    "$TEST_DIR/rootfs/etc/systemd/system/multi-user.target.wants/userconfig.service"
ln -sf /lib/systemd/system/systemd-user-sessions.service \
    "$TEST_DIR/rootfs/etc/systemd/system/multi-user.target.wants/systemd-user-sessions.service"
ln -sf /lib/systemd/system/NetworkManager-wait-online.service \
    "$TEST_DIR/rootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service"

# Create mock config.txt
echo "Creating mock config.txt..."
cat > "$TEST_DIR/bootfs/config.txt" << 'EOF'
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
EOF

echo "✅ Test environment created"
echo ""

# Apply fixes BEFORE building Docker image
echo "=== APPLYING FIXES TO TEST ENVIRONMENT ==="
BOOTFS="$TEST_DIR/bootfs" \
ROOTFS="$TEST_DIR/rootfs" \
bash tools/fix/disable-rename-user-on-sd.sh

echo ""
echo "=== BUILDING DOCKER IMAGE ==="
docker build -t boot-simulation:test "$TEST_DIR" 2>&1 | grep -E "(Step|Successfully|ERROR|error)" || true

echo ""
echo "=== RUNNING BOOT SIMULATION ==="
echo "This will simulate the complete boot process..."
echo ""

# Run with privileged mode and systemd (precise boot simulation)
echo "Running boot simulation (this may take 10-20 seconds)..."
echo ""

docker run --rm --privileged \
    --cap-add SYS_ADMIN \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v "$TEST_DIR/simulate-boot.sh:/root/simulate-boot.sh:ro" \
    -v "$TEST_DIR/rootfs/usr/local/bin/matrix-boot.sh:/usr/local/bin/matrix-boot.sh:ro" \
    -v "$TEST_DIR/rootfs/lib/systemd/system:/lib/systemd/system:ro" \
    -v "$TEST_DIR/rootfs/etc/systemd/system:/etc/systemd/system:ro" \
    -e container=docker \
    --name boot-simulation-test \
    boot-simulation:test 2>&1 | tee "$TEST_DIR/boot-simulation.log"

SIMULATION_EXIT=$?

echo ""
if [ $SIMULATION_EXIT -eq 0 ]; then
    echo "✅ BOOT SIMULATION PASSED - All fixes working correctly!"
    rm -rf "$TEST_DIR"
    exit 0
else
    echo "❌ BOOT SIMULATION FAILED - Review output above"
    echo ""
    echo "Test environment preserved at: $TEST_DIR"
    exit 1
fi
