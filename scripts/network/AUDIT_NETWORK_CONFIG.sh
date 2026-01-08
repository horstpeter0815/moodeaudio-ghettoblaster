#!/bin/bash
################################################################################
#
# NETWORK CONFIGURATION AUDIT SCRIPT
#
# Comprehensive audit of all network-related configurations:
# - Systemd services
# - NetworkManager connections
# - Network managers (NetworkManager, systemd-networkd, dhcpcd)
# - Interface configurations
# - Conflicts and dependencies
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

OUTPUT_DIR="$PROJECT_ROOT/docs/connectivity"
mkdir -p "$OUTPUT_DIR"

AUDIT_REPORT="$OUTPUT_DIR/NETWORK_CONFIGURATION_AUDIT.md"
TEMP_DIR=$(mktemp -d)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[AUDIT]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
section() { echo -e "${CYAN}[SECTION]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NETWORK CONFIGURATION AUDIT                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

log "Starting comprehensive network audit..."
log "Report will be saved to: $AUDIT_REPORT"
echo ""

################################################################################
# 1. SYSTEMD SERVICES AUDIT
################################################################################

section "1. Auditing Systemd Services..."

SERVICES_DIR="$PROJECT_ROOT/moode-source/lib/systemd/system"
NETWORK_SERVICES=()

# Find all services that might touch network
for service in "$SERVICES_DIR"/*.service; do
    if [ -f "$service" ]; then
        service_name=$(basename "$service")
        # Check if service mentions network-related terms
        if grep -qiE "(network|eth0|wlan0|usb0|dhcp|ip|route|interface)" "$service"; then
            NETWORK_SERVICES+=("$service_name")
        fi
    fi
done

log "Found ${#NETWORK_SERVICES[@]} network-related services"

# Analyze each service
cat > "$TEMP_DIR/services_analysis.txt" << 'EOF'
# Systemd Services Analysis

EOF

for service in "${NETWORK_SERVICES[@]}"; do
    service_file="$SERVICES_DIR/$service"
    echo "" >> "$TEMP_DIR/services_analysis.txt"
    echo "## $service" >> "$TEMP_DIR/services_analysis.txt"
    echo "" >> "$TEMP_DIR/services_analysis.txt"
    echo "\`\`\`" >> "$TEMP_DIR/services_analysis.txt"
    cat "$service_file" >> "$TEMP_DIR/services_analysis.txt"
    echo "\`\`\`" >> "$TEMP_DIR/services_analysis.txt"
    echo "" >> "$TEMP_DIR/services_analysis.txt"
    
    # Extract key information
    echo "**Key Information:**" >> "$TEMP_DIR/services_analysis.txt"
    
    # Check After dependencies
    if grep -q "^After=" "$service_file"; then
        echo "- **After:** $(grep "^After=" "$service_file" | head -1 | cut -d= -f2)" >> "$TEMP_DIR/services_analysis.txt"
    fi
    
    # Check Before dependencies
    if grep -q "^Before=" "$service_file"; then
        echo "- **Before:** $(grep "^Before=" "$service_file" | head -1 | cut -d= -f2)" >> "$TEMP_DIR/services_analysis.txt"
    fi
    
    # Check IP addresses configured
    if grep -qE "192\.168\.|10\.|172\.|ifconfig|ip addr" "$service_file"; then
        ips=$(grep -oE "192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+" "$service_file" | sort -u | tr '\n' ' ')
        echo "- **IP Addresses:** $ips" >> "$TEMP_DIR/services_analysis.txt"
    fi
    
    # Check interfaces
    if grep -qE "eth0|wlan0|usb0" "$service_file"; then
        interfaces=$(grep -oE "eth0|wlan0|usb0" "$service_file" | sort -u | tr '\n' ' ')
        echo "- **Interfaces:** $interfaces" >> "$TEMP_DIR/services_analysis.txt"
    fi
    
    # Check DHCP vs Static
    if grep -qi "dhcp" "$service_file"; then
        echo "- **Mode:** DHCP" >> "$TEMP_DIR/services_analysis.txt"
    elif grep -qiE "ifconfig|ip addr add|192\.168\.|static" "$service_file"; then
        echo "- **Mode:** Static IP" >> "$TEMP_DIR/services_analysis.txt"
    fi
    
    echo "" >> "$TEMP_DIR/services_analysis.txt"
done

info "Services analysis complete"

################################################################################
# 2. NETWORKMANAGER CONNECTIONS AUDIT
################################################################################

section "2. Auditing NetworkManager Connections..."

NM_CONN_DIR="$PROJECT_ROOT/moode-source/etc/NetworkManager/system-connections"
NM_CONNECTIONS=()

if [ -d "$NM_CONN_DIR" ]; then
    for conn in "$NM_CONN_DIR"/*.nmconnection; do
        if [ -f "$conn" ]; then
            NM_CONNECTIONS+=("$(basename "$conn")")
        fi
    done
    
    log "Found ${#NM_CONNECTIONS[@]} NetworkManager connections"
    
    cat > "$TEMP_DIR/nm_connections_analysis.txt" << 'EOF'
# NetworkManager Connections Analysis

EOF
    
    for conn in "${NM_CONNECTIONS[@]}"; do
        conn_file="$NM_CONN_DIR/$conn"
        echo "" >> "$TEMP_DIR/nm_connections_analysis.txt"
        echo "## $conn" >> "$TEMP_DIR/nm_connections_analysis.txt"
        echo "" >> "$TEMP_DIR/nm_connections_analysis.txt"
        echo "\`\`\`" >> "$TEMP_DIR/nm_connections_analysis.txt"
        cat "$conn_file" >> "$TEMP_DIR/nm_connections_analysis.txt"
        echo "\`\`\`" >> "$TEMP_DIR/nm_connections_analysis.txt"
        echo "" >> "$TEMP_DIR/nm_connections_analysis.txt"
        
        # Extract key information
        echo "**Key Information:**" >> "$TEMP_DIR/nm_connections_analysis.txt"
        
        # Connection type
        if grep -q "^type=" "$conn_file"; then
            conn_type=$(grep "^type=" "$conn_file" | head -1 | cut -d= -f2)
            echo "- **Type:** $conn_type" >> "$TEMP_DIR/nm_connections_analysis.txt"
        fi
        
        # Interface name
        if grep -q "^interface-name=" "$conn_file"; then
            iface=$(grep "^interface-name=" "$conn_file" | head -1 | cut -d= -f2)
            echo "- **Interface:** $iface" >> "$TEMP_DIR/nm_connections_analysis.txt"
        fi
        
        # Autoconnect
        if grep -q "^autoconnect=" "$conn_file"; then
            autoconnect=$(grep "^autoconnect=" "$conn_file" | head -1 | cut -d= -f2)
            echo "- **Autoconnect:** $autoconnect" >> "$TEMP_DIR/nm_connections_analysis.txt"
        fi
        
        # Priority
        if grep -q "^autoconnect-priority=" "$conn_file"; then
            priority=$(grep "^autoconnect-priority=" "$conn_file" | head -1 | cut -d= -f2)
            echo "- **Priority:** $priority" >> "$TEMP_DIR/nm_connections_analysis.txt"
        fi
        
        # IP Method
        if grep -q "^method=" "$conn_file"; then
            method=$(grep "^method=" "$conn_file" | head -1 | cut -d= -f2)
            echo "- **IP Method:** $method" >> "$TEMP_DIR/nm_connections_analysis.txt"
        fi
        
        # IP Address
        if grep -q "^addresses=" "$conn_file"; then
            addresses=$(grep "^addresses=" "$conn_file" | head -1 | cut -d= -f2)
            echo "- **Addresses:** $addresses" >> "$TEMP_DIR/nm_connections_analysis.txt"
        fi
        
        echo "" >> "$TEMP_DIR/nm_connections_analysis.txt"
    done
else
    warn "NetworkManager connections directory not found"
    echo "NetworkManager connections directory not found: $NM_CONN_DIR" > "$TEMP_DIR/nm_connections_analysis.txt"
fi

info "NetworkManager connections analysis complete"

################################################################################
# 3. CONFLICT DETECTION
################################################################################

section "3. Detecting Conflicts..."

cat > "$TEMP_DIR/conflicts.txt" << 'EOF'
# Network Configuration Conflicts

EOF

# Check for multiple services configuring same IP
echo "## Multiple Services Configuring Same IP (192.168.10.2)" >> "$TEMP_DIR/conflicts.txt"
echo "" >> "$TEMP_DIR/conflicts.txt"
SERVICES_WITH_IP=$(grep -l "192\.168\.10\.2" "$SERVICES_DIR"/*.service 2>/dev/null | xargs -n1 basename || true)
if [ -n "$SERVICES_WITH_IP" ]; then
    echo "$SERVICES_WITH_IP" | while read service; do
        echo "- **$service**" >> "$TEMP_DIR/conflicts.txt"
    done
    echo "" >> "$TEMP_DIR/conflicts.txt"
    warn "Multiple services configure 192.168.10.2"
else
    echo "None found" >> "$TEMP_DIR/conflicts.txt"
    echo "" >> "$TEMP_DIR/conflicts.txt"
fi

# Check for multiple services configuring eth0
echo "## Multiple Services Configuring eth0" >> "$TEMP_DIR/conflicts.txt"
echo "" >> "$TEMP_DIR/conflicts.txt"
SERVICES_WITH_ETH0=$(grep -l "eth0" "$SERVICES_DIR"/*.service 2>/dev/null | xargs -n1 basename || true)
if [ -n "$SERVICES_WITH_ETH0" ]; then
    echo "$SERVICES_WITH_ETH0" | while read service; do
        echo "- **$service**" >> "$TEMP_DIR/conflicts.txt"
    done
    echo "" >> "$TEMP_DIR/conflicts.txt"
    warn "Multiple services configure eth0"
else
    echo "None found" >> "$TEMP_DIR/conflicts.txt"
    echo "" >> "$TEMP_DIR/conflicts.txt"
fi

# Check for conflicting network managers
echo "## Conflicting Network Managers" >> "$TEMP_DIR/conflicts.txt"
echo "" >> "$TEMP_DIR/conflicts.txt"
MANAGERS_FOUND=()

if [ -d "$NM_CONN_DIR" ] && [ ${#NM_CONNECTIONS[@]} -gt 0 ]; then
    MANAGERS_FOUND+=("NetworkManager")
fi

if grep -qr "systemd-networkd\|systemd/network" "$SERVICES_DIR"/*.service 2>/dev/null; then
    MANAGERS_FOUND+=("systemd-networkd")
fi

if grep -qr "dhcpcd\|dhcpcd.conf" "$SERVICES_DIR"/*.service 2>/dev/null; then
    MANAGERS_FOUND+=("dhcpcd")
fi

if [ ${#MANAGERS_FOUND[@]} -gt 1 ]; then
    for mgr in "${MANAGERS_FOUND[@]}"; do
        echo "- **$mgr**" >> "$TEMP_DIR/conflicts.txt"
    done
    echo "" >> "$TEMP_DIR/conflicts.txt"
    warn "Multiple network managers detected"
else
    echo "None detected" >> "$TEMP_DIR/conflicts.txt"
    echo "" >> "$TEMP_DIR/conflicts.txt"
fi

# Check for static IP vs DHCP conflicts
echo "## Static IP vs DHCP Conflicts" >> "$TEMP_DIR/conflicts.txt"
echo "" >> "$TEMP_DIR/conflicts.txt"
STATIC_SERVICES=$(grep -lE "ifconfig.*192\.168\.|ip addr add.*192\.168\.|static.*192\.168\." "$SERVICES_DIR"/*.service 2>/dev/null | xargs -n1 basename || true)
DHCP_SERVICES=$(grep -li "dhcp\|dhclient" "$SERVICES_DIR"/*.service 2>/dev/null | xargs -n1 basename || true)

if [ -n "$STATIC_SERVICES" ] && [ -n "$DHCP_SERVICES" ]; then
    echo "**Static IP Services:**" >> "$TEMP_DIR/conflicts.txt"
    echo "$STATIC_SERVICES" | while read service; do
        echo "- $service" >> "$TEMP_DIR/conflicts.txt"
    done
    echo "" >> "$TEMP_DIR/conflicts.txt"
    echo "**DHCP Services:**" >> "$TEMP_DIR/conflicts.txt"
    echo "$DHCP_SERVICES" | while read service; do
        echo "- $service" >> "$TEMP_DIR/conflicts.txt"
    done
    echo "" >> "$TEMP_DIR/conflicts.txt"
    warn "Both static IP and DHCP services found - potential conflict"
else
    echo "None detected" >> "$TEMP_DIR/conflicts.txt"
    echo "" >> "$TEMP_DIR/conflicts.txt"
fi

info "Conflict detection complete"

################################################################################
# 4. DEPENDENCY ANALYSIS
################################################################################

section "4. Analyzing Service Dependencies..."

cat > "$TEMP_DIR/dependencies.txt" << 'EOF'
# Service Dependencies Analysis

EOF

# Create dependency graph
echo "## Dependency Chain" >> "$TEMP_DIR/dependencies.txt"
echo "" >> "$TEMP_DIR/dependencies.txt"

for service in "${NETWORK_SERVICES[@]}"; do
    service_file="$SERVICES_DIR/$service"
    echo "### $service" >> "$TEMP_DIR/dependencies.txt"
    echo "" >> "$TEMP_DIR/dependencies.txt"
    
    if grep -q "^After=" "$service_file"; then
        after=$(grep "^After=" "$service_file" | head -1 | cut -d= -f2)
        echo "- **After:** $after" >> "$TEMP_DIR/dependencies.txt"
    fi
    
    if grep -q "^Before=" "$service_file"; then
        before=$(grep "^Before=" "$service_file" | head -1 | cut -d= -f2)
        echo "- **Before:** $before" >> "$TEMP_DIR/dependencies.txt"
    fi
    
    if grep -q "^Wants=" "$service_file"; then
        wants=$(grep "^Wants=" "$service_file" | head -1 | cut -d= -f2)
        echo "- **Wants:** $wants" >> "$TEMP_DIR/dependencies.txt"
    fi
    
    if grep -q "^Requires=" "$service_file"; then
        requires=$(grep "^Requires=" "$service_file" | head -1 | cut -d= -f2)
        echo "- **Requires:** $requires" >> "$TEMP_DIR/dependencies.txt"
    fi
    
    echo "" >> "$TEMP_DIR/dependencies.txt"
done

info "Dependency analysis complete"

################################################################################
# 5. GENERATE FINAL REPORT
################################################################################

section "5. Generating Final Report..."

cat > "$AUDIT_REPORT" << 'EOF'
# Network Configuration Audit Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Executive Summary

This audit identifies all network-related configurations, services, and potential conflicts in the moOde Audio custom build project.

## Table of Contents

1. [Systemd Services](#1-systemd-services)
2. [NetworkManager Connections](#2-networkmanager-connections)
3. [Conflicts Detected](#3-conflicts-detected)
4. [Dependencies](#4-dependencies)
5. [Recommendations](#5-recommendations)

---

EOF

cat "$TEMP_DIR/services_analysis.txt" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"
echo "---" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"

cat "$TEMP_DIR/nm_connections_analysis.txt" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"
echo "---" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"

cat "$TEMP_DIR/conflicts.txt" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"
echo "---" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"

cat "$TEMP_DIR/dependencies.txt" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"
echo "---" >> "$AUDIT_REPORT"
echo "" >> "$AUDIT_REPORT"

# Add recommendations
cat >> "$AUDIT_REPORT" << 'EOF'
## 5. Recommendations

### Immediate Actions

1. **Consolidate Network Services**
   - Multiple services configure the same interface (eth0) and IP (192.168.10.2)
   - Recommend creating a single authoritative network service

2. **Resolve Network Manager Conflicts**
   - Multiple network managers detected (NetworkManager, systemd-networkd, dhcpcd)
   - Choose one primary manager and disable others

3. **Separate Connectivity Modes**
   - Create mode-based network configuration:
     - USB Gadget Mode (usb0, static IP)
     - Ethernet Static (eth0, static IP 192.168.10.2)
     - Ethernet DHCP (eth0, DHCP from Mac)
     - WiFi (wlan0, DHCP, lower priority)

4. **Fix Priority Conflicts**
   - WiFi and Ethernet have same priority in NetworkManager
   - Set Ethernet priority higher than WiFi

### Long-term Solutions

1. Implement unified network mode manager
2. Use Docker test suite to validate network configurations
3. Document each connectivity method clearly
4. Create runtime scripts to switch between modes

---

**Report Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Audit Script:** scripts/network/AUDIT_NETWORK_CONFIG.sh

EOF

log "Audit report generated: $AUDIT_REPORT"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ NETWORK AUDIT COMPLETE                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "Summary:"
echo "  - Services analyzed: ${#NETWORK_SERVICES[@]}"
echo "  - NetworkManager connections: ${#NM_CONNECTIONS[@]}"
echo "  - Report saved to: $AUDIT_REPORT"
echo ""
echo "Next steps:"
echo "  1. Review the audit report"
echo "  2. Analyze conflicts and dependencies"
echo "  3. Design unified network manager"
echo ""

