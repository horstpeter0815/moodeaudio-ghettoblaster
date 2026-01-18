#!/bin/bash
# COMPREHENSIVE boot dependency analysis - check EVERYTHING precisely

set -e

ROOTFS="${ROOTFS:-/Volumes/rootfs}"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root filesystem not found at $ROOTFS"
    echo "   Mount SD card or set ROOTFS environment variable"
    exit 1
fi

echo "=== COMPREHENSIVE BOOT DEPENDENCY ANALYSIS ==="
echo "Root filesystem: $ROOTFS"
echo ""

# Find all services
SERVICE_DIRS=(
    "$ROOTFS/lib/systemd/system"
    "$ROOTFS/usr/lib/systemd/system"
    "$ROOTFS/etc/systemd/system"
)

echo "=== 1. FINDING ALL SERVICES ==="
ALL_SERVICES=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null | sort -u)
TOTAL_COUNT=$(echo "$ALL_SERVICES" | wc -l | tr -d ' ')
echo "Total services found: $TOTAL_COUNT"
echo ""

# Find enabled services
echo "=== 2. ENABLED SERVICES ==="
ENABLED_SERVICES=$(find "$ROOTFS/etc/systemd/system" -type l -name "*.service" 2>/dev/null | sort -u)
ENABLED_COUNT=$(echo "$ENABLED_SERVICES" | wc -l | tr -d ' ')
echo "Enabled services: $ENABLED_COUNT"
echo "Listing enabled services:"
echo "$ENABLED_SERVICES" | while read service; do
    target=$(basename "$service")
    echo "  - $target"
done
echo ""

# Check for problematic dependencies
echo "=== 3. SERVICES WITH NETWORK-ONLINE DEPENDENCIES ==="
NETWORK_ONLINE_SERVICES=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "network-online.target" {} \; | sort -u)
NETWORK_COUNT=$(echo "$NETWORK_ONLINE_SERVICES" | wc -l | tr -d ' ')
echo "Found: $NETWORK_COUNT services"
if [ "$NETWORK_COUNT" -gt 0 ]; then
    echo "$NETWORK_ONLINE_SERVICES" | while read service_file; do
        service=$(basename "$service_file")
        deps=$(grep -E "After=.*network-online|Wants=.*network-online|Requires=.*network-online" "$service_file" 2>/dev/null || echo "  (dependency found)")
        echo "  ⚠️  $service: $deps"
    done
fi
echo ""

# Check for user slice dependencies
echo "=== 4. SERVICES WITH USER SLICE DEPENDENCIES ==="
USER_SLICE_SERVICES=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "user@\|user.slice\|systemd-user" {} \; | sort -u)
USER_COUNT=$(echo "$USER_SLICE_SERVICES" | wc -l | tr -d ' ')
echo "Found: $USER_COUNT services"
if [ "$USER_COUNT" -gt 0 ]; then
    echo "$USER_SLICE_SERVICES" | while read service_file; do
        service=$(basename "$service_file")
        deps=$(grep -E "After=.*user|Wants=.*user|Requires=.*user" "$service_file" 2>/dev/null | head -1 || echo "  (user dependency found)")
        echo "  ⚠️  $service: $deps"
    done
fi
echo ""

# Check for TTY dependencies
echo "=== 5. SERVICES WITH TTY DEPENDENCIES ==="
TTY_SERVICES=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "TTYPath\|tty1\|dev-tty1\|getty" {} \; | sort -u)
TTY_COUNT=$(echo "$TTY_SERVICES" | wc -l | tr -d ' ')
echo "Found: $TTY_COUNT services"
if [ "$TTY_COUNT" -gt 0 ]; then
    echo "$TTY_SERVICES" | while read service_file; do
        service=$(basename "$service_file")
        tty_deps=$(grep -E "TTYPath|tty1|dev-tty1|getty|Wants=.*tty|After=.*tty" "$service_file" 2>/dev/null | head -2 || echo "  (TTY dependency found)")
        echo "  ⚠️  $service:"
        echo "     $tty_deps"
    done
fi
echo ""

# Check for cloud-init dependencies
echo "=== 6. SERVICES WITH CLOUD-INIT DEPENDENCIES ==="
CLOUD_SERVICES=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "cloud-init" {} \; | sort -u)
CLOUD_COUNT=$(echo "$CLOUD_SERVICES" | wc -l | tr -d ' ')
echo "Found: $CLOUD_COUNT services"
if [ "$CLOUD_COUNT" -gt 0 ]; then
    echo "$CLOUD_SERVICES" | while read service_file; do
        service=$(basename "$service_file")
        deps=$(grep -E "After=.*cloud|Wants=.*cloud|Requires=.*cloud|Before=.*cloud" "$service_file" 2>/dev/null | head -1 || echo "  (cloud-init dependency found)")
        echo "  ⚠️  $service: $deps"
    done
fi
echo ""

# Check for long timeouts
echo "=== 7. SERVICES WITH LONG TIMEOUTS (>10s) ==="
find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null | while read service_file; do
    timeout_line=$(grep "TimeoutStartSec=" "$service_file" 2>/dev/null || echo "")
    if [ -n "$timeout_line" ]; then
        timeout_val=$(echo "$timeout_line" | grep -oE "TimeoutStartSec=[0-9]+" | cut -d= -f2)
        if [ -n "$timeout_val" ] && [ "$timeout_val" -gt 10 ]; then
            service=$(basename "$service_file")
            echo "  ⚠️  $service: TimeoutStartSec=$timeout_val"
        fi
    fi
done
echo ""

# Check for services without timeouts (may hang indefinitely)
echo "=== 8. SERVICES WITHOUT TIMEOUT (May hang indefinitely) ==="
NO_TIMEOUT_COUNT=0
find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null | while read service_file; do
    if ! grep -q "TimeoutStartSec" "$service_file" 2>/dev/null; then
        service=$(basename "$service_file")
        # Skip template services (@.service) as they're not individual services
        if [[ ! "$service" =~ @ ]]; then
            echo "  ⚠️  $service: No timeout specified"
            NO_TIMEOUT_COUNT=$((NO_TIMEOUT_COUNT + 1))
        fi
    fi
done
echo ""

# Check for dependencies on problematic targets
echo "=== 9. SERVICES DEPENDING ON PROBLEMATIC TARGETS ==="
PROBLEMATIC_TARGETS=(
    "network-online.target"
    "cloud-init.target"
    "graphical.target"
    "multi-user.target"
    "basic.target"
)

for target in "${PROBLEMATIC_TARGETS[@]}"; do
    target_deps=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "After=.*${target}\|Wants=.*${target}\|Requires=.*${target}" {} \; | wc -l | tr -d ' ')
    if [ "$target_deps" -gt 0 ]; then
        echo "  ⚠️  $target: $target_deps services depend on it"
        find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "After=.*${target}\|Wants=.*${target}\|Requires=.*${target}" {} \; | head -5 | while read service_file; do
            service=$(basename "$service_file")
            echo "     - $service"
        done
    fi
done
echo ""

# Check for ExecStart commands that might hang
echo "=== 10. SERVICES WITH POTENTIALLY HANGING COMMANDS ==="
HANGING_COMMANDS=(
    "nm-online"
    "network-online"
    "wait"
    "sleep.*[6-9][0-9]"
)

for cmd in "${HANGING_COMMANDS[@]}"; do
    matching_services=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "ExecStart=.*${cmd}" {} \; | sort -u)
    if [ -n "$matching_services" ]; then
        echo "  ⚠️  Services using '$cmd':"
        echo "$matching_services" | while read service_file; do
            service=$(basename "$service_file")
            cmd_line=$(grep "ExecStart=.*${cmd}" "$service_file" 2>/dev/null | head -1)
            echo "     - $service: $cmd_line"
        done
    fi
done
echo ""

# Check for circular dependencies (simple check)
echo "=== 11. POTENTIAL CIRCULAR DEPENDENCIES ==="
echo "  (Checking for services that depend on each other)"
# This is simplified - full analysis would need graph traversal
find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null | while read service1_file; do
    service1=$(basename "$service1_file")
    # Check if this service is mentioned in other services' dependencies
    deps_on_service1=$(find "${SERVICE_DIRS[@]}" -name "*.service" 2>/dev/null -exec grep -l "After=.*${service1}\|Wants=.*${service1}\|Requires=.*${service1}" {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [ "$deps_on_service1" -gt 5 ]; then
        echo "  ⚠️  $service1: $deps_on_service1 other services depend on it (potential bottleneck)"
    fi
done
echo ""

# Check for services that should be disabled but are still enabled
echo "=== 12. SERVICES THAT SHOULD BE DISABLED BUT ARE ENABLED ==="
SHOULD_DISABLE=(
    "05-remove-pi-user.service"
    "fix-user-id.service"
    "userconfig.service"
    "systemd-user-sessions.service"
    "systemd-statcollect.service"
    "NetworkManager-wait-online.service"
    "first-boot-setup.service"
    "cloud-init.service"
    "getty@tty1.service"
)

for service in "${SHOULD_DISABLE[@]}"; do
    if [ -L "$ROOTFS/etc/systemd/system/$service" ] && [ ! -L "$ROOTFS/etc/systemd/system/$service" ] || [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/$service" ]; then
        link_target=$(readlink "$ROOTFS/etc/systemd/system/$service" 2>/dev/null || readlink "$ROOTFS/etc/systemd/system/multi-user.target.wants/$service" 2>/dev/null || echo "")
        if [ "$link_target" != "/dev/null" ] && [ -n "$link_target" ]; then
            echo "  ❌ $service: Still enabled (should be disabled)"
        fi
    fi
done
echo ""

# Summary
echo "=== SUMMARY ==="
echo "Total services: $TOTAL_COUNT"
echo "Enabled services: $ENABLED_COUNT"
echo "Services with network-online: $NETWORK_COUNT"
echo "Services with user slice: $USER_COUNT"
echo "Services with TTY: $TTY_COUNT"
echo "Services with cloud-init: $CLOUD_COUNT"
echo ""
echo "⚠️  Review the issues above - any of these can cause boot hangs or delays"
echo ""
echo "=== RECOMMENDATIONS ==="
echo "1. Disable ALL services with network-online dependencies"
echo "2. Disable ALL services with user slice dependencies"
echo "3. Set timeout on ALL services (max 10s)"
echo "4. Disable TTY dependencies where not needed"
echo "5. Disable cloud-init completely"
echo "6. Review and consolidate redundant services"
echo ""
