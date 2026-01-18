#!/bin/bash
################################################################################
# COMPLETE SSH VERIFICATION SCRIPT
# 
# This script checks EVERY aspect of SSH configuration to identify why SSH
# is not working. Run this on the Pi after boot to get complete diagnostics.
#
# Usage: ./verify-ssh-complete.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
section() { echo ""; echo "╔══════════════════════════════════════════════════════════════╗"; echo "║  $1"; echo "╚══════════════════════════════════════════════════════════════╝"; echo ""; }

REPORT_FILE="/tmp/ssh-verification-report-$(date +%Y%m%d_%H%M%S).txt"

echo "" > "$REPORT_FILE"
echo "SSH VERIFICATION REPORT - $(date)" >> "$REPORT_FILE"
echo "=====================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

section "🔍 COMPLETE SSH VERIFICATION"

info "Report will be saved to: $REPORT_FILE"
echo ""

################################################################################
# CHECK 1: SSH SERVICE STATUS
################################################################################

section "CHECK 1: SSH SERVICE STATUS"

SSH_SERVICE_NAME=""
SSH_ENABLED=""
SSH_ACTIVE=""

# Check which SSH service exists
if systemctl list-unit-files | grep -q "^ssh.service"; then
    SSH_SERVICE_NAME="ssh"
elif systemctl list-unit-files | grep -q "^sshd.service"; then
    SSH_SERVICE_NAME="sshd"
else
    error "Neither ssh.service nor sshd.service found!"
    echo "ERROR: No SSH service found" >> "$REPORT_FILE"
fi

if [ -n "$SSH_SERVICE_NAME" ]; then
    info "Found SSH service: $SSH_SERVICE_NAME"
    echo "SSH Service: $SSH_SERVICE_NAME" >> "$REPORT_FILE"
    
    # Check if enabled
    SSH_ENABLED=$(systemctl is-enabled "$SSH_SERVICE_NAME" 2>/dev/null || echo "unknown")
    echo "Enabled Status: $SSH_ENABLED" >> "$REPORT_FILE"
    
    if [ "$SSH_ENABLED" = "enabled" ]; then
        log "✅ SSH service is enabled"
    elif [ "$SSH_ENABLED" = "masked" ]; then
        error "❌ SSH service is MASKED (cannot be enabled)"
    else
        error "❌ SSH service is NOT enabled (status: $SSH_ENABLED)"
    fi
    
    # Check if active
    SSH_ACTIVE=$(systemctl is-active "$SSH_SERVICE_NAME" 2>/dev/null || echo "inactive")
    echo "Active Status: $SSH_ACTIVE" >> "$REPORT_FILE"
    
    if [ "$SSH_ACTIVE" = "active" ]; then
        log "✅ SSH service is active (running)"
    else
        error "❌ SSH service is NOT active (status: $SSH_ACTIVE)"
    fi
    
    # Get full status
    info "Full service status:"
    systemctl status "$SSH_SERVICE_NAME" --no-pager -l | head -20
    echo "" >> "$REPORT_FILE"
    systemctl status "$SSH_SERVICE_NAME" --no-pager -l >> "$REPORT_FILE" 2>&1 || true
fi

################################################################################
# CHECK 2: SSH PROCESS
################################################################################

section "CHECK 2: SSH PROCESS"

SSH_PROCESS=$(ps aux | grep -E "[s]shd|[s]sh:" | grep -v grep || echo "")
echo "SSH Processes:" >> "$REPORT_FILE"
echo "$SSH_PROCESS" >> "$REPORT_FILE"

if [ -n "$SSH_PROCESS" ]; then
    log "✅ SSH process is running"
    info "SSH processes:"
    echo "$SSH_PROCESS"
else
    error "❌ SSH process is NOT running"
    warn "SSH service may be enabled but process is not running"
fi

################################################################################
# CHECK 3: PORT 22 LISTENING
################################################################################

section "CHECK 3: PORT 22 LISTENING"

PORT_22_LISTENING=""
if command -v netstat >/dev/null 2>&1; then
    PORT_22_LISTENING=$(netstat -tuln 2>/dev/null | grep ':22 ' || echo "")
elif command -v ss >/dev/null 2>&1; then
    PORT_22_LISTENING=$(ss -tuln 2>/dev/null | grep ':22 ' || echo "")
fi

echo "Port 22 Status:" >> "$REPORT_FILE"
echo "$PORT_22_LISTENING" >> "$REPORT_FILE"

if echo "$PORT_22_LISTENING" | grep -q ":22 "; then
    log "✅ Port 22 is listening"
    info "Port 22 details:"
    echo "$PORT_22_LISTENING"
else
    error "❌ Port 22 is NOT listening"
    warn "SSH service may be running but not accepting connections"
fi

################################################################################
# CHECK 4: SSH KEYS
################################################################################

section "CHECK 4: SSH HOST KEYS"

SSH_KEYS=$(ls -1 /etc/ssh/ssh_host_*_key 2>/dev/null | wc -l)
SSH_KEY_LIST=$(ls -1 /etc/ssh/ssh_host_*_key 2>/dev/null || echo "none")

echo "SSH Keys Found: $SSH_KEYS" >> "$REPORT_FILE"
echo "SSH Key List:" >> "$REPORT_FILE"
echo "$SSH_KEY_LIST" >> "$REPORT_FILE"

if [ "$SSH_KEYS" -gt 0 ]; then
    log "✅ SSH host keys exist ($SSH_KEYS keys found)"
    info "SSH keys:"
    echo "$SSH_KEY_LIST"
else
    error "❌ SSH host keys are MISSING"
    warn "SSH cannot start without host keys"
    info "Attempting to generate SSH keys..."
    ssh-keygen -A 2>&1 | tee -a "$REPORT_FILE" || error "Failed to generate SSH keys"
fi

################################################################################
# CHECK 5: SSH CONFIG FILE
################################################################################

section "CHECK 5: SSH CONFIG FILE"

if [ -f /etc/ssh/sshd_config ]; then
    log "✅ SSH config file exists: /etc/ssh/sshd_config"
    echo "SSH Config File: EXISTS" >> "$REPORT_FILE"
    
    # Check config syntax
    if sshd -t 2>/dev/null; then
        log "✅ SSH config syntax is valid"
        echo "SSH Config Syntax: VALID" >> "$REPORT_FILE"
    else
        error "❌ SSH config syntax is INVALID"
        echo "SSH Config Syntax: INVALID" >> "$REPORT_FILE"
        sshd -t 2>&1 | tee -a "$REPORT_FILE" || true
    fi
    
    # Check important settings
    info "Checking SSH config settings:"
    PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
    echo "  Port: $PORT"
    echo "SSH Config Port: $PORT" >> "$REPORT_FILE"
    
    PERMIT_ROOT=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}' || echo "prohibit-password")
    echo "  PermitRootLogin: $PERMIT_ROOT"
    echo "SSH Config PermitRootLogin: $PERMIT_ROOT" >> "$REPORT_FILE"
    
    PASSWORD_AUTH=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}' || echo "yes")
    echo "  PasswordAuthentication: $PASSWORD_AUTH"
    echo "SSH Config PasswordAuthentication: $PASSWORD_AUTH" >> "$REPORT_FILE"
else
    error "❌ SSH config file is MISSING: /etc/ssh/sshd_config"
    echo "SSH Config File: MISSING" >> "$REPORT_FILE"
    warn "SSH cannot start without config file"
fi

################################################################################
# CHECK 6: SSH FLAG FILES
################################################################################

section "CHECK 6: SSH FLAG FILES"

SSH_FLAG1=""
SSH_FLAG2=""

if [ -f /boot/firmware/ssh ]; then
    SSH_FLAG1="exists"
    log "✅ SSH flag exists: /boot/firmware/ssh"
elif [ -f /boot/ssh ]; then
    SSH_FLAG2="exists"
    log "✅ SSH flag exists: /boot/ssh"
else
    warn "⚠️  SSH flag files not found"
fi

echo "SSH Flag /boot/firmware/ssh: ${SSH_FLAG1:-missing}" >> "$REPORT_FILE"
echo "SSH Flag /boot/ssh: ${SSH_FLAG2:-missing}" >> "$REPORT_FILE"

################################################################################
# CHECK 7: SSH SERVICES STATUS
################################################################################

section "CHECK 7: SSH SERVICES STATUS"

SSH_SERVICES=(
    "ssh-guaranteed.service"
    "boot-complete-minimal.service"
    "enable-ssh-early.service"
    "ssh-asap.service"
    "independent-ssh.service"
    "fix-ssh-sudoers.service"
)

echo "SSH Services Status:" >> "$REPORT_FILE"

for service in "${SSH_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}"; then
        STATUS=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
        ENABLED=$(systemctl is-enabled "$service" 2>/dev/null || echo "unknown")
        
        if [ "$STATUS" = "active" ]; then
            log "✅ $service is active"
        else
            warn "⚠️  $service is $STATUS"
        fi
        
        echo "  $service: $STATUS (enabled: $ENABLED)" >> "$REPORT_FILE"
    else
        info "ℹ️  $service not found (may not be installed)"
        echo "  $service: NOT FOUND" >> "$REPORT_FILE"
    fi
done

################################################################################
# CHECK 8: SSH SERVICE LOGS
################################################################################

section "CHECK 8: SSH SERVICE LOGS"

echo "SSH Service Logs:" >> "$REPORT_FILE"

if [ -n "$SSH_SERVICE_NAME" ]; then
    info "Recent logs for $SSH_SERVICE_NAME:"
    journalctl -u "$SSH_SERVICE_NAME" --no-pager -n 20 | tail -20
    echo "" >> "$REPORT_FILE"
    journalctl -u "$SSH_SERVICE_NAME" --no-pager -n 50 >> "$REPORT_FILE" 2>&1 || true
fi

# Check SSH-related service logs
for service in "${SSH_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}"; then
        info "Recent logs for $service:"
        journalctl -u "$service" --no-pager -n 10 | tail -10
        echo "" >> "$REPORT_FILE"
        echo "=== $service logs ===" >> "$REPORT_FILE"
        journalctl -u "$service" --no-pager -n 20 >> "$REPORT_FILE" 2>&1 || true
    fi
done

################################################################################
# CHECK 9: NETWORK STATUS
################################################################################

section "CHECK 9: NETWORK STATUS"

NETWORK_INTERFACES=$(ip addr show 2>/dev/null | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//' || echo "")
NETWORK_ROUTES=$(ip route show 2>/dev/null || echo "")

echo "Network Interfaces:" >> "$REPORT_FILE"
echo "$NETWORK_INTERFACES" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Network Routes:" >> "$REPORT_FILE"
echo "$NETWORK_ROUTES" >> "$REPORT_FILE"

if [ -n "$NETWORK_INTERFACES" ]; then
    log "✅ Network interfaces found"
    info "Network interfaces:"
    echo "$NETWORK_INTERFACES"
    
    # Check if we can ping
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Network connectivity works"
        echo "Network Connectivity: OK" >> "$REPORT_FILE"
    else
        warn "⚠️  Network connectivity may be limited"
        echo "Network Connectivity: LIMITED" >> "$REPORT_FILE"
    fi
else
    error "❌ No network interfaces found"
    echo "Network Interfaces: NONE" >> "$REPORT_FILE"
fi

################################################################################
# CHECK 10: MOODE WORKER CHECK
################################################################################

section "CHECK 10: MOODE WORKER CHECK"

if [ -f /var/www/daemon/worker.php ]; then
    info "Checking worker.php for SSH disable commands..."
    
    SSH_DISABLE_IN_WORKER=$(grep -i "disable.*ssh\|ssh.*disable" /var/www/daemon/worker.php || echo "")
    
    if [ -n "$SSH_DISABLE_IN_WORKER" ]; then
        error "❌ Found SSH disable commands in worker.php!"
        echo "SSH Disable Commands in worker.php:" >> "$REPORT_FILE"
        echo "$SSH_DISABLE_IN_WORKER" >> "$REPORT_FILE"
        warn "moOde worker.php may be disabling SSH"
    else
        log "✅ No SSH disable commands found in worker.php"
        echo "SSH Disable Commands in worker.php: NONE" >> "$REPORT_FILE"
    fi
    
    # Check moOde log
    if [ -f /var/log/moode.log ]; then
        info "Checking moOde log for SSH-related messages..."
        MOODE_SSH_LOG=$(grep -i "ssh" /var/log/moode.log | tail -10 || echo "")
        if [ -n "$MOODE_SSH_LOG" ]; then
            echo "moOde SSH Log Entries:" >> "$REPORT_FILE"
            echo "$MOODE_SSH_LOG" >> "$REPORT_FILE"
        fi
    fi
else
    info "ℹ️  worker.php not found (moOde may not be installed)"
fi

################################################################################
# SUMMARY
################################################################################

section "📊 VERIFICATION SUMMARY"

echo "" >> "$REPORT_FILE"
echo "=== SUMMARY ===" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

ISSUES=0

echo "SSH Service: ${SSH_SERVICE_NAME:-NOT FOUND}"
[ -z "$SSH_SERVICE_NAME" ] && ISSUES=$((ISSUES + 1))

echo "SSH Enabled: ${SSH_ENABLED:-unknown}"
[ "$SSH_ENABLED" != "enabled" ] && [ -n "$SSH_SERVICE_NAME" ] && ISSUES=$((ISSUES + 1))

echo "SSH Active: ${SSH_ACTIVE:-unknown}"
[ "$SSH_ACTIVE" != "active" ] && [ -n "$SSH_SERVICE_NAME" ] && ISSUES=$((ISSUES + 1))

if [ -z "$SSH_PROCESS" ]; then
    echo "SSH Process: NOT RUNNING"
    ISSUES=$((ISSUES + 1))
else
    echo "SSH Process: RUNNING"
fi

if echo "$PORT_22_LISTENING" | grep -q ":22 "; then
    echo "Port 22: LISTENING"
else
    echo "Port 22: NOT LISTENING"
    ISSUES=$((ISSUES + 1))
fi

if [ "$SSH_KEYS" -gt 0 ]; then
    echo "SSH Keys: PRESENT ($SSH_KEYS keys)"
else
    echo "SSH Keys: MISSING"
    ISSUES=$((ISSUES + 1))
fi

echo "" >> "$REPORT_FILE"
echo "Total Issues Found: $ISSUES" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ $ISSUES -eq 0 ]; then
    log "✅ ALL CHECKS PASSED - SSH should be working!"
    echo "STATUS: ALL CHECKS PASSED" >> "$REPORT_FILE"
else
    error "❌ $ISSUES ISSUES FOUND - SSH may not be working"
    echo "STATUS: $ISSUES ISSUES FOUND" >> "$REPORT_FILE"
fi

echo ""
info "Full report saved to: $REPORT_FILE"
echo ""
info "To view the report:"
echo "  cat $REPORT_FILE"
echo ""

################################################################################
# RECOMMENDATIONS
################################################################################

section "💡 RECOMMENDATIONS"

if [ "$SSH_ACTIVE" != "active" ] && [ -n "$SSH_SERVICE_NAME" ]; then
    echo "1. Try starting SSH manually:"
    echo "   sudo systemctl start $SSH_SERVICE_NAME"
    echo ""
fi

if [ "$SSH_ENABLED" != "enabled" ] && [ -n "$SSH_SERVICE_NAME" ]; then
    echo "2. Try enabling SSH manually:"
    echo "   sudo systemctl enable $SSH_SERVICE_NAME"
    echo ""
fi

if [ "$SSH_KEYS" -eq 0 ]; then
    echo "3. Generate SSH keys:"
    echo "   sudo ssh-keygen -A"
    echo ""
fi

if echo "$PORT_22_LISTENING" | grep -qv ":22 "; then
    echo "4. Check firewall:"
    echo "   sudo iptables -L -n | grep 22"
    echo "   sudo ufw status"
    echo ""
fi

echo "5. Check service logs for errors:"
echo "   journalctl -u $SSH_SERVICE_NAME -n 50"
echo ""

echo "6. Try restarting SSH:"
echo "   sudo systemctl restart $SSH_SERVICE_NAME"
echo ""

