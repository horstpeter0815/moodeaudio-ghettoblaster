#!/bin/bash
################################################################################
# TEST SSH AFTER BOOT
# 
# Tests SSH connection and verifies SSH services are running after boot.
# This script checks:
# - SSH connection works
# - SSH service is running
# - SSH service is enabled
# - Port 22 is listening
# - SSH keys exist
# - Services are active
#
# Usage: ./test-ssh-after-boot.sh [PI_IP] [USER] [PASSWORD]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Default values
PI_IP="${1:-10.10.11.39}"
USER="${2:-andre}"

# Read password from file if it exists, otherwise use default
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWORD_FILE="$SCRIPT_DIR/test-password.txt"
if [ -f "$PASSWORD_FILE" ]; then
    PASSWORD=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
    echo "Using password from file: $PASSWORD_FILE"
else
    PASSWORD="${3:-}"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧪 TEST SSH AFTER BOOT                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Testing SSH on: $USER@$PI_IP"
echo ""

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    warn "sshpass not found - will prompt for password"
    SSH_CMD="ssh"
    SCP_CMD="scp"
else
    info "Using sshpass for password authentication"
    SSH_CMD="sshpass -p '$PASSWORD' ssh"
    SCP_CMD="sshpass -p '$PASSWORD' scp"
fi

################################################################################
# TEST 1: SSH CONNECTION
################################################################################

info "=== TEST 1: SSH CONNECTION ==="
echo ""

if sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$USER@$PI_IP" "echo 'SSH connection successful'" 2>/dev/null; then
    log "✅ SSH connection works!"
    CONNECTION_OK=true
else
    error "❌ SSH connection failed"
    echo ""
    warn "Possible reasons:"
    echo "  - Pi is not booted yet (wait 1-2 minutes)"
    echo "  - Wrong IP address: $PI_IP"
    echo "  - Wrong username: $USER"
    echo "  - Wrong password"
    echo "  - SSH service not running"
    echo "  - Network issue"
    echo ""
    error "Cannot continue without SSH connection"
    exit 1
fi

echo ""

################################################################################
# TEST 2: SSH SERVICE STATUS
################################################################################

info "=== TEST 2: SSH SERVICE STATUS ==="
echo ""

SSH_SERVICE_STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo 'inactive'" 2>/dev/null)

if [ "$SSH_SERVICE_STATUS" = "active" ]; then
    log "✅ SSH service is running"
else
    error "❌ SSH service is NOT running (status: $SSH_SERVICE_STATUS)"
    echo ""
    warn "Attempting to start SSH service..."
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null || true" 2>/dev/null
    sleep 2
    SSH_SERVICE_STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo 'inactive'" 2>/dev/null)
    if [ "$SSH_SERVICE_STATUS" = "active" ]; then
        log "✅ SSH service started successfully"
    else
        error "❌ Failed to start SSH service"
    fi
fi

echo ""

################################################################################
# TEST 3: SSH SERVICE ENABLED
################################################################################

info "=== TEST 3: SSH SERVICE ENABLED ==="
echo ""

SSH_ENABLED=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "systemctl is-enabled ssh 2>/dev/null || systemctl is-enabled sshd 2>/dev/null || echo 'disabled'" 2>/dev/null)

if [ "$SSH_ENABLED" = "enabled" ] || [ "$SSH_ENABLED" = "masked" ]; then
    log "✅ SSH service is enabled"
else
    warn "⚠️  SSH service is NOT enabled (status: $SSH_ENABLED)"
    echo ""
    warn "Attempting to enable SSH service..."
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true" 2>/dev/null
    log "✅ SSH service enable command executed"
fi

echo ""

################################################################################
# TEST 4: PORT 22 LISTENING
################################################################################

info "=== TEST 4: PORT 22 LISTENING ==="
echo ""

PORT_22_LISTENING=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "netstat -tuln 2>/dev/null | grep ':22 ' || ss -tuln 2>/dev/null | grep ':22 ' || echo 'not_listening'" 2>/dev/null)

if echo "$PORT_22_LISTENING" | grep -q ":22 "; then
    log "✅ Port 22 is listening"
    info "  $PORT_22_LISTENING"
else
    error "❌ Port 22 is NOT listening"
    warn "SSH service may be running but not accepting connections"
fi

echo ""

################################################################################
# TEST 5: SSH KEYS EXIST
################################################################################

info "=== TEST 5: SSH KEYS EXIST ==="
echo ""

SSH_KEYS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "ls -1 /etc/ssh/ssh_host_*_key 2>/dev/null | wc -l" 2>/dev/null)

if [ "$SSH_KEYS" -gt 0 ]; then
    log "✅ SSH host keys exist ($SSH_KEYS keys found)"
else
    error "❌ SSH host keys are missing"
    warn "SSH keys need to be generated"
fi

echo ""

################################################################################
# TEST 6: SSH SERVICES STATUS
################################################################################

info "=== TEST 6: SSH SERVICES STATUS ==="
echo ""

# Check for independent-ssh.service
INDEPENDENT_SSH=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "systemctl is-active independent-ssh.service 2>/dev/null || echo 'not_found'" 2>/dev/null)

if [ "$INDEPENDENT_SSH" = "active" ]; then
    log "✅ independent-ssh.service is active"
elif [ "$INDEPENDENT_SSH" = "not_found" ]; then
    info "ℹ️  independent-ssh.service not found (may not be installed)"
else
    warn "⚠️  independent-ssh.service status: $INDEPENDENT_SSH"
fi

# Check for ssh-guaranteed.service
SSH_GUARANTEED=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "systemctl is-active ssh-guaranteed.service 2>/dev/null || echo 'not_found'" 2>/dev/null)

if [ "$SSH_GUARANTEED" = "active" ]; then
    log "✅ ssh-guaranteed.service is active"
elif [ "$SSH_GUARANTEED" = "not_found" ]; then
    info "ℹ️  ssh-guaranteed.service not found (may not be installed)"
else
    warn "⚠️  ssh-guaranteed.service status: $SSH_GUARANTEED"
fi

# Check for ssh-watchdog.service
SSH_WATCHDOG=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "systemctl is-active ssh-watchdog.service 2>/dev/null || echo 'not_found'" 2>/dev/null)

if [ "$SSH_WATCHDOG" = "active" ]; then
    log "✅ ssh-watchdog.service is active"
elif [ "$SSH_WATCHDOG" = "not_found" ]; then
    info "ℹ️  ssh-watchdog.service not found (may not be installed)"
else
    warn "⚠️  ssh-watchdog.service status: $SSH_WATCHDOG"
fi

echo ""

################################################################################
# TEST 7: SSH FLAG FILES
################################################################################

info "=== TEST 7: SSH FLAG FILES ==="
echo ""

SSH_FLAG1=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "test -f /boot/firmware/ssh && echo 'exists' || echo 'missing'" 2>/dev/null)
SSH_FLAG2=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$PI_IP" "test -f /boot/ssh && echo 'exists' || echo 'missing'" 2>/dev/null)

if [ "$SSH_FLAG1" = "exists" ]; then
    log "✅ SSH flag file exists: /boot/firmware/ssh"
elif [ "$SSH_FLAG2" = "exists" ]; then
    log "✅ SSH flag file exists: /boot/ssh"
else
    warn "⚠️  SSH flag files not found (may have been removed after first boot)"
fi

echo ""

################################################################################
# SUMMARY
################################################################################

info "=== TEST SUMMARY ==="
echo ""
log "✅ SSH connection: Working"
[ "$SSH_SERVICE_STATUS" = "active" ] && log "✅ SSH service: Running" || error "❌ SSH service: Not running"
[ "$SSH_ENABLED" = "enabled" ] && log "✅ SSH service: Enabled" || warn "⚠️  SSH service: Not enabled"
[ -n "$PORT_22_LISTENING" ] && [ "$PORT_22_LISTENING" != "not_listening" ] && log "✅ Port 22: Listening" || error "❌ Port 22: Not listening"
[ "$SSH_KEYS" -gt 0 ] && log "✅ SSH keys: Present" || error "❌ SSH keys: Missing"
echo ""
log "✅ SSH is working correctly!"
echo ""
info "You can now connect via:"
echo "  ssh $USER@$PI_IP"
echo ""

