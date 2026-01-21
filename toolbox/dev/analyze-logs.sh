#!/bin/bash
# Analyze Logs
# Parse and analyze system logs for common issues
# Part of: WISSENSBASIS/DEVELOPMENT_WORKFLOW.md tooling

set -e

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"

echo "========================================"
echo "System Log Analysis"
echo "Target: $USER@$PI_IP"
echo "========================================"
echo ""

echo "=== Errors (last 20) ==="
ssh "$USER@$PI_IP" "journalctl -p err -n 20 --no-pager" || echo "No errors"
echo ""

echo "=== Display Issues ==="
ssh "$USER@$PI_IP" "journalctl -u localdisplay -n 30 --no-pager | grep -i 'error\|fail\|crash' || echo 'No display issues'"
echo ""

echo "=== X Server Issues ==="
ssh "$USER@$PI_IP" "cat /var/log/Xorg.0.log 2>/dev/null | grep -i 'error\|EE' | tail -20 || echo 'No X server log or no errors'"
echo ""

echo "=== Audio Issues ==="
ssh "$USER@$PI_IP" "journalctl -u mpd -n 30 --no-pager | grep -i 'error\|fail' || echo 'No audio issues'"
echo ""

echo "=== Service Failures ==="
ssh "$USER@$PI_IP" "systemctl list-units --failed --no-pager" || echo "No failed services"
echo ""

echo "=== Boot Time Analysis ==="
ssh "$USER@$PI_IP" "systemd-analyze" || echo "systemd-analyze not available"
echo ""

echo "=== Slow Services (>5s) ==="
ssh "$USER@$PI_IP" "systemd-analyze blame | head -20" || echo "systemd-analyze not available"
echo ""

echo "========================================"
echo "Log analysis complete"
echo "========================================"
