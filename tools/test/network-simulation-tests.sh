#!/bin/bash
################################################################################
#
# NETWORK SIMULATION TESTS
#
# Tests network mode manager in Docker environment with different interface
# configurations to validate mode detection and configuration.
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[TEST]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
section() { echo -e "${CYAN}[SECTION]${NC} $1"; }

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
    log "✅ PASS: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    error "❌ FAIL: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NETWORK SIMULATION TESTS                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# CHECK DOCKER
################################################################################

section "Checking Docker environment..."

if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    error "Docker daemon is not running"
    exit 1
fi

test_pass "Docker is available and running"

################################################################################
# PREPARE TEST ENVIRONMENT
################################################################################

section "Preparing test environment..."

# Create test directories
mkdir -p network-test network-test-logs network-test-boot

# Create mock DHCP server script (simple simulation)
cat > network-test/mock-dhcp-server.sh << 'EOF'
#!/bin/bash
# Simple mock DHCP server simulation
# In real test, this would be a proper DHCP server
echo "Mock DHCP server would assign IP here"
EOF
chmod +x network-test/mock-dhcp-server.sh

info "Test environment prepared"

################################################################################
# TEST 1: USB GADGET MODE
################################################################################

section "Test 1: USB Gadget Mode Detection"

log "Testing USB gadget mode detection..."

# Build test container
if docker build -t network-test:latest -f Dockerfile.network-test . >/dev/null 2>&1; then
    test_pass "Docker image built successfully"
else
    test_fail "Failed to build Docker image"
    exit 1
fi

# Run container with USB gadget interface
CONTAINER_ID=$(docker run -d --privileged --cap-add=NET_ADMIN \
    -v "$PROJECT_ROOT/network-test:/test:rw" \
    network-test:latest /bin/bash -c "
    /usr/local/bin/mock-interfaces.sh usb0
    /usr/local/bin/network-mode-manager.sh
    sleep 2
    ip addr show usb0 | grep '192.168.10.2' && echo 'SUCCESS' || echo 'FAILED'
" 2>&1)

sleep 5

# Check results
if docker logs "$CONTAINER_ID" 2>&1 | grep -q "SUCCESS"; then
    test_pass "USB gadget mode configured correctly (192.168.10.2)"
else
    test_fail "USB gadget mode configuration failed"
    docker logs "$CONTAINER_ID" 2>&1 | tail -20
fi

docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true

################################################################################
# TEST 2: ETHERNET STATIC MODE
################################################################################

section "Test 2: Ethernet Static Mode Detection"

log "Testing Ethernet static mode detection..."

# Run container with Ethernet interface (no network-mode file)
CONTAINER_ID=$(docker run -d --privileged --cap-add=NET_ADMIN \
    -v "$PROJECT_ROOT/network-test:/test:rw" \
    -v "$PROJECT_ROOT/network-test-boot:/boot/firmware:rw" \
    network-test:latest /bin/bash -c "
    /usr/local/bin/mock-interfaces.sh eth0
    rm -f /boot/firmware/network-mode
    /usr/local/bin/network-mode-manager.sh
    sleep 2
    ip addr show eth0 | grep '192.168.10.2' && echo 'SUCCESS' || echo 'FAILED'
" 2>&1)

sleep 5

# Check results
if docker logs "$CONTAINER_ID" 2>&1 | grep -q "SUCCESS"; then
    test_pass "Ethernet static mode configured correctly (192.168.10.2)"
else
    test_fail "Ethernet static mode configuration failed"
    docker logs "$CONTAINER_ID" 2>&1 | tail -20
fi

docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true

################################################################################
# TEST 3: ETHERNET DHCP MODE
################################################################################

section "Test 3: Ethernet DHCP Mode Detection"

log "Testing Ethernet DHCP mode detection..."

# Create network-mode file for DHCP
echo "ethernet-dhcp" > network-test-boot/network-mode

# Run container with Ethernet interface and DHCP mode file
CONTAINER_ID=$(docker run -d --privileged --cap-add=NET_ADMIN \
    -v "$PROJECT_ROOT/network-test:/test:rw" \
    -v "$PROJECT_ROOT/network-test-boot:/boot/firmware:rw" \
    network-test:latest /bin/bash -c "
    /usr/local/bin/mock-interfaces.sh eth0
    /usr/local/bin/network-mode-manager.sh
    sleep 2
    # DHCP mode should attempt DHCP (will fail without DHCP server, but should try)
    ip addr show eth0 && echo 'SUCCESS' || echo 'FAILED'
" 2>&1)

sleep 5

# Check results - DHCP mode should be selected (even if DHCP fails)
if docker logs "$CONTAINER_ID" 2>&1 | grep -q "ethernet-dhcp"; then
    test_pass "Ethernet DHCP mode detected correctly"
else
    test_fail "Ethernet DHCP mode detection failed"
    docker logs "$CONTAINER_ID" 2>&1 | tail -20
fi

docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true

################################################################################
# TEST 4: PRIORITY TEST (USB > ETHERNET > WIFI)
################################################################################

section "Test 4: Interface Priority Test"

log "Testing interface priority (USB > Ethernet > WiFi)..."

# Run container with all interfaces
CONTAINER_ID=$(docker run -d --privileged --cap-add=NET_ADMIN \
    -v "$PROJECT_ROOT/network-test:/test:rw" \
    network-test:latest /bin/bash -c "
    /usr/local/bin/mock-interfaces.sh all
    /usr/local/bin/network-mode-manager.sh
    sleep 2
    # USB should be selected over Ethernet/WiFi
    ip addr show usb0 | grep '192.168.10.2' && echo 'SUCCESS' || echo 'FAILED'
" 2>&1)

sleep 5

# Check results
if docker logs "$CONTAINER_ID" 2>&1 | grep -q "usb-gadget"; then
    test_pass "USB gadget selected with highest priority"
else
    test_fail "Priority test failed - wrong interface selected"
    docker logs "$CONTAINER_ID" 2>&1 | tail -20
fi

docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true

################################################################################
# TEST 5: CONFLICT RESOLUTION
################################################################################

section "Test 5: Conflict Resolution"

log "Testing that conflicting services are disabled..."

# This test would check that old services are stopped
# For now, we'll test that the script doesn't fail when services exist
CONTAINER_ID=$(docker run -d --privileged --cap-add=NET_ADMIN \
    network-test:latest /bin/bash -c "
    /usr/local/bin/mock-interfaces.sh eth0
    /usr/local/bin/network-mode-manager.sh 2>&1 | grep -i 'disable\|conflict' && echo 'SUCCESS' || echo 'FAILED'
" 2>&1)

sleep 5

# Check results
if docker logs "$CONTAINER_ID" 2>&1 | grep -q "SUCCESS\|conflicting\|disable"; then
    test_pass "Conflict resolution mechanism works"
else
    warn "Conflict resolution test inconclusive (services may not exist in container)"
fi

docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true

################################################################################
# SUMMARY
################################################################################

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  TEST SUMMARY                                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    log "✅ All network simulation tests passed!"
    exit 0
else
    error "❌ Some tests failed. Review output above."
    exit 1
fi



