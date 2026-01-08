#!/bin/bash
################################################################################
# VERIFY SSH INSTALLATION ON SD CARD
# 
# Verifies that all SSH components are correctly installed on the SD card
# before boot. This script checks:
# - SSH flag files exist
# - SSH activation script exists and is executable
# - Systemd service files are installed (if rootfs available)
# - rc.local exists and is executable (if rootfs available)
# - Permissions are correct
#
# Usage: ./verify-ssh-installation.sh [SD_MOUNT_POINT]
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

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 VERIFY SSH INSTALLATION ON SD CARD                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIND SD CARD
################################################################################

SD_MOUNT="${1:-}"

if [ -z "$SD_MOUNT" ]; then
    if [ -d "/Volumes/bootfs" ]; then
        SD_MOUNT="/Volumes/bootfs"
    elif [ -d "/Volumes/boot" ]; then
        SD_MOUNT="/Volumes/boot"
    else
        BOOT_PARTITION=$(diskutil list external 2>/dev/null | grep "Windows_FAT_32\|FAT32" | head -1 | awk '{print $NF}' || echo "")
        if [ -n "$BOOT_PARTITION" ]; then
            MOUNT_POINT=$(mount | grep "$BOOT_PARTITION" | awk '{print $3}' | head -1)
            if [ -n "$MOUNT_POINT" ]; then
                SD_MOUNT="$MOUNT_POINT"
            fi
        fi
    fi
fi

if [ -z "$SD_MOUNT" ] || [ ! -d "$SD_MOUNT" ]; then
    error "SD card not found!"
    echo ""
    info "Please insert SD card or specify mount point:"
    echo "  ./verify-ssh-installation.sh /Volumes/bootfs"
    exit 1
fi

log "SD card found: $SD_MOUNT"
echo ""

# Check if rootfs is available
ROOTFS_MOUNT=""
if [ -d "$SD_MOUNT/../rootfs" ]; then
    ROOTFS_MOUNT="$SD_MOUNT/../rootfs"
elif mount | grep -q "rootfs\|ext4.*on.*rootfs"; then
    ROOTFS_MOUNT=$(mount | grep "rootfs\|ext4" | awk '{print $3}' | head -1)
fi

ROOTFS_AVAILABLE=false
if [ -n "$ROOTFS_MOUNT" ]; then
    log "Root filesystem found: $ROOTFS_MOUNT"
    ROOTFS_AVAILABLE=true
else
    warn "Root filesystem not mounted (this is OK - will only check boot partition)"
fi
echo ""

################################################################################
# VERIFICATION CHECKS
################################################################################

VERIFICATION_PASSED=true
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

info "=== VERIFICATION CHECKS ==="
echo ""

# Check 1: SSH Flag File (Pi 4)
if [ -f "$SD_MOUNT/ssh" ]; then
    if [ -d "$SD_MOUNT/ssh" ]; then
        error "❌ $SD_MOUNT/ssh exists as DIRECTORY (should be file)"
        VERIFICATION_PASSED=false
        ((CHECKS_FAILED++))
    else
        log "✅ SSH flag file exists: $SD_MOUNT/ssh"
        ((CHECKS_PASSED++))
    fi
else
    warn "⚠️  SSH flag file missing: $SD_MOUNT/ssh (Pi 4 location)"
    ((CHECKS_WARNED++))
fi

# Check 2: SSH Flag File (Pi 5)
if [ -f "$SD_MOUNT/firmware/ssh" ]; then
    if [ -d "$SD_MOUNT/firmware/ssh" ]; then
        error "❌ $SD_MOUNT/firmware/ssh exists as DIRECTORY (should be file)"
        VERIFICATION_PASSED=false
        ((CHECKS_FAILED++))
    else
        log "✅ SSH flag file exists: $SD_MOUNT/firmware/ssh"
        ((CHECKS_PASSED++))
    fi
else
    if [ -d "$SD_MOUNT/firmware" ]; then
        warn "⚠️  SSH flag file missing: $SD_MOUNT/firmware/ssh (Pi 5 location)"
        ((CHECKS_WARNED++))
    fi
fi

# Check 3: SSH Activation Script
if [ -f "$SD_MOUNT/ssh-activate.sh" ]; then
    if [ -x "$SD_MOUNT/ssh-activate.sh" ]; then
        log "✅ SSH activation script exists and is executable: $SD_MOUNT/ssh-activate.sh"
        ((CHECKS_PASSED++))
    else
        error "❌ SSH activation script exists but is NOT executable: $SD_MOUNT/ssh-activate.sh"
        VERIFICATION_PASSED=false
        ((CHECKS_FAILED++))
    fi
else
    warn "⚠️  SSH activation script missing: $SD_MOUNT/ssh-activate.sh (optional)"
    ((CHECKS_WARNED++))
fi

# Check 4: Systemd Service (if rootfs available)
if [ "$ROOTFS_AVAILABLE" = true ]; then
    SYSTEMD_DIR="$ROOTFS_MOUNT/etc/systemd/system"
    
    # Check for independent-ssh.service
    if [ -f "$SYSTEMD_DIR/independent-ssh.service" ]; then
        log "✅ Systemd service exists: independent-ssh.service"
        ((CHECKS_PASSED++))
        
        # Check if service is enabled (symlink exists)
        if [ -L "$ROOTFS_MOUNT/etc/systemd/system/local-fs.target.wants/independent-ssh.service" ] || \
           [ -L "$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants/independent-ssh.service" ] || \
           [ -L "$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants/independent-ssh.service" ]; then
            log "✅ Systemd service is enabled (symlink exists)"
            ((CHECKS_PASSED++))
        else
            warn "⚠️  Systemd service exists but may not be enabled (no symlink found)"
            ((CHECKS_WARNED++))
        fi
    else
        # Check for ssh-guaranteed.service
        if [ -f "$SYSTEMD_DIR/ssh-guaranteed.service" ]; then
            log "✅ Systemd service exists: ssh-guaranteed.service"
            ((CHECKS_PASSED++))
            
            # Check if service is enabled
            if [ -L "$ROOTFS_MOUNT/etc/systemd/system/sysinit.target.wants/ssh-guaranteed.service" ]; then
                log "✅ Systemd service is enabled (symlink exists)"
                ((CHECKS_PASSED++))
            else
                warn "⚠️  Systemd service exists but may not be enabled (no symlink found)"
                ((CHECKS_WARNED++))
            fi
        else
            warn "⚠️  No systemd SSH service found (optional if using flag file only)"
            ((CHECKS_WARNED++))
        fi
    fi
    
    # Check for watchdog service
    if [ -f "$SYSTEMD_DIR/ssh-watchdog.service" ]; then
        log "✅ SSH watchdog service exists: ssh-watchdog.service"
        ((CHECKS_PASSED++))
        
        if [ -L "$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants/ssh-watchdog.service" ]; then
            log "✅ Watchdog service is enabled (symlink exists)"
            ((CHECKS_PASSED++))
        else
            warn "⚠️  Watchdog service exists but may not be enabled"
            ((CHECKS_WARNED++))
        fi
    fi
else
    info "ℹ️  Root filesystem not available - skipping systemd service checks"
fi

# Check 5: rc.local (if rootfs available)
if [ "$ROOTFS_AVAILABLE" = true ]; then
    RCLOCAL="$ROOTFS_MOUNT/etc/rc.local"
    if [ -f "$RCLOCAL" ]; then
        if [ -x "$RCLOCAL" ]; then
            log "✅ rc.local exists and is executable: $RCLOCAL"
            ((CHECKS_PASSED++))
            
            # Check if it contains SSH activation
            if grep -q "ssh-activate\|ssh.*enable\|ssh.*start" "$RCLOCAL" 2>/dev/null; then
                log "✅ rc.local contains SSH activation code"
                ((CHECKS_PASSED++))
            else
                warn "⚠️  rc.local exists but may not contain SSH activation"
                ((CHECKS_WARNED++))
            fi
        else
            error "❌ rc.local exists but is NOT executable: $RCLOCAL"
            VERIFICATION_PASSED=false
            ((CHECKS_FAILED++))
        fi
    else
        warn "⚠️  rc.local missing (optional fallback)"
        ((CHECKS_WARNED++))
    fi
fi

echo ""
info "=== VERIFICATION SUMMARY ==="
echo "  ✅ Passed: $CHECKS_PASSED"
echo "  ⚠️  Warnings: $CHECKS_WARNED"
echo "  ❌ Failed: $CHECKS_FAILED"
echo ""

################################################################################
# FINAL RESULT
################################################################################

if [ "$VERIFICATION_PASSED" = true ]; then
    if [ $CHECKS_FAILED -eq 0 ]; then
        log "✅ VERIFICATION PASSED - SSH installation looks good!"
        echo ""
        info "SSH should be enabled on next boot."
        echo ""
        if [ $CHECKS_WARNED -gt 0 ]; then
            warn "Note: Some optional components are missing, but core SSH should work."
        fi
        exit 0
    else
        error "❌ VERIFICATION FAILED - Some critical checks failed"
        echo ""
        warn "SSH may not work correctly. Please review errors above."
        exit 1
    fi
else
    error "❌ VERIFICATION FAILED - Critical errors found"
    echo ""
    warn "SSH installation has problems. Please fix errors above before booting."
    exit 1
fi

