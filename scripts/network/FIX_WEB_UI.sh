#!/bin/bash
################################################################################
#
# Fix Web UI Access
#
# Checks and fixes network, web server, and Chromium issues
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[FIX]${NC} $1"; }
error() { echo -e "\033[0;31m[ERROR]${NC} $1" >&2; }
warn() { echo -e "\033[0;33m[WARN]${NC} $1"; }

echo "=== Web UI Fix ==="
echo ""

# 1. Check network
echo "1. Checking network..."
if ip addr show eth0 2>/dev/null | grep -q "inet "; then
    ETH_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    log "Ethernet IP: $ETH_IP"
else
    warn "Ethernet not configured"
fi

if ip addr show wlan0 2>/dev/null | grep -q "inet "; then
    WLAN_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    log "WiFi IP: $WLAN_IP"
else
    warn "WiFi not configured"
fi

echo ""

# 2. Check web server
echo "2. Checking web server..."
if systemctl is-active --quiet httpd 2>/dev/null; then
    log "httpd is running"
    WEB_SERVICE="httpd"
elif systemctl is-active --quiet apache2 2>/dev/null; then
    log "apache2 is running"
    WEB_SERVICE="apache2"
elif systemctl is-active --quiet nginx 2>/dev/null; then
    log "nginx is running"
    WEB_SERVICE="nginx"
else
    warn "Web server not found - checking moOde services..."
    # moOde uses lighttpd typically
    if systemctl is-active --quiet lighttpd 2>/dev/null; then
        log "lighttpd is running"
        WEB_SERVICE="lighttpd"
    else
        error "No web server found running"
        echo "Trying to start lighttpd..."
        sudo systemctl start lighttpd 2>/dev/null && sleep 2 && log "lighttpd started" || warn "Could not start lighttpd"
    fi
fi

echo ""

# 3. Test web server
echo "3. Testing web server..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    log "Web server responding: HTTP $HTTP_CODE"
else
    warn "Web server not responding: HTTP $HTTP_CODE"
    echo "Restarting web server..."
    sudo systemctl restart "$WEB_SERVICE" 2>/dev/null || sudo systemctl restart lighttpd 2>/dev/null
    sleep 3
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        log "Web server now responding"
    else
        error "Web server still not responding"
    fi
fi

echo ""

# 4. Check Chromium
echo "4. Checking Chromium..."
if pgrep -f chromium >/dev/null 2>&1; then
    log "Chromium is running"
else
    warn "Chromium not running"
    echo "Restarting display service..."
    sudo systemctl restart localdisplay.service 2>/dev/null && sleep 5 && log "Display service restarted" || warn "Could not restart display"
fi

echo ""
echo "=== Summary ==="
if [ -n "${ETH_IP:-}" ]; then
    echo "Ethernet: http://$ETH_IP/"
fi
if [ -n "${WLAN_IP:-}" ]; then
    echo "WiFi: http://$WLAN_IP/"
fi
echo ""
echo "If still not accessible, check:"
echo "  sudo systemctl status lighttpd"
echo "  sudo systemctl status localdisplay"
echo "  sudo journalctl -u lighttpd -n 50"
