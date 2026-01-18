#!/bin/bash
# Get boot logs from Pi to identify failing service
# Run this via SSH or copy to Pi

echo "=== GETTING BOOT LOGS FROM PI ==="
echo ""

echo "1. Failed services:"
echo "=================="
systemctl --failed --no-pager -l
echo ""

echo "2. Recent boot errors (last 50 lines):"
echo "======================================="
journalctl -b --no-pager -l | grep -i "fail\|error" | tail -50
echo ""

echo "3. All 'sys' related errors:"
echo "============================"
journalctl -b --no-pager -l | grep -i "failed to start.*sys" | head -20
echo ""

echo "4. Systemd services with 'sys' in name:"
echo "======================================="
systemctl list-units --all --no-pager | grep -i "sys" | grep -i "fail\|error" | head -20
echo ""

echo "5. Checking specific systemd services:"
echo "======================================"
for svc in systemd-timesyncd systemd-hostnamed systemd-logind systemd-resolved systemd-networkd; do
    echo ""
    echo "--- $svc.service ---"
    systemctl status "$svc.service" --no-pager -l | head -15
done
echo ""

echo "6. Checking if services are masked:"
echo "===================================="
for svc in systemd-resolved systemd-networkd; do
    echo "$svc.service: $(systemctl is-enabled $svc.service 2>&1)"
    echo "$svc.socket: $(systemctl is-enabled $svc.socket 2>&1)"
done
echo ""

echo "=== LOG COLLECTION COMPLETE ==="
