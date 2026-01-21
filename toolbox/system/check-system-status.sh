#!/bin/bash
# Check System Status
# Quick system health check for moOde Ghettoblaster
# Part of: WISSENSBASIS/DEVELOPMENT_WORKFLOW.md tooling

set -e

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"

echo "========================================"
echo "moOde Ghettoblaster System Status"
echo "Target: $USER@$PI_IP"
echo "========================================"
echo ""

echo "=== Display Status ==="
ssh "$USER@$PI_IP" "systemctl status localdisplay 2>/dev/null | grep -E 'Active|Main PID' || echo 'Service not running'"
echo ""

echo "=== Audio Device ==="
ssh "$USER@$PI_IP" "cat /proc/asound/cards 2>/dev/null || echo 'No audio cards detected'"
echo ""

echo "=== Database Config (Display & Audio) ==="
ssh "$USER@$PI_IP" "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT param, value FROM cfg_system WHERE param IN ('local_display','peppy_display','hdmi_scn_orient','disable_gpu_chromium','volknob','audioout','cardnum','amixname') ORDER BY param\""
echo ""

echo "=== Recent Errors (Last 10) ==="
ssh "$USER@$PI_IP" "journalctl -p err -n 10 --no-pager 2>/dev/null || echo 'No recent errors'"
echo ""

echo "=== System Uptime ==="
ssh "$USER@$PI_IP" "uptime"
echo ""

echo "=== Disk Usage ==="
ssh "$USER@$PI_IP" "df -h / | tail -1"
echo ""

echo "========================================"
echo "Status check complete"
echo "========================================"
