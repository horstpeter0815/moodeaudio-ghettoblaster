#!/bin/bash
################################################################################
# DIAGNOSE GHETTOBLASTER CONNECTION ISSUES
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 DIAGNOSING GHETTOBLASTER CONNECTION                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Check if Pi is reachable
echo "1. Checking if Pi is reachable..."
if ping -c 2 -W 2 GhettoBlaster.local >/dev/null 2>&1; then
    PI_IP=$(ping -c 1 GhettoBlaster.local 2>&1 | grep "bytes from" | awk '{print $4}' | tr -d ':')
    echo "✅ Pi is reachable at: $PI_IP"
elif ping -c 2 -W 2 192.168.10.2 >/dev/null 2>&1; then
    PI_IP="192.168.10.2"
    echo "✅ Pi is reachable at: $PI_IP"
else
    echo "❌ Pi is NOT reachable"
    echo "   - Check if Pi is booted"
    echo "   - Check network connection"
    echo "   - Try: ping GhettoBlaster.local"
    exit 1
fi

# 2. Check SMB port
echo ""
echo "2. Checking SMB port (445)..."
if nc -z -v "$PI_IP" 445 2>&1 | grep -q "succeeded"; then
    echo "✅ SMB port 445 is open"
else
    echo "❌ SMB port 445 is NOT accessible"
    echo "   - SMB service might not be running on Pi"
    echo "   - Firewall might be blocking"
fi

# 3. Check SSH (alternative access)
echo ""
echo "3. Checking SSH access..."
if nc -z -v "$PI_IP" 22 2>&1 | grep -q "succeeded"; then
    echo "✅ SSH port 22 is open"
    echo "   You can use SSH instead: ssh pi@$PI_IP"
else
    echo "❌ SSH port 22 is NOT accessible"
fi

# 4. Test SMB connection
echo ""
echo "4. Testing SMB connection..."
if command -v smbclient >/dev/null 2>&1; then
    echo "Testing anonymous connection..."
    smbclient -L "//$PI_IP" -N 2>&1 | head -5
else
    echo "⚠️  smbclient not installed (install with: brew install samba)"
fi

# 5. Suggestions
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  💡 SUGGESTIONS                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "If SMB doesn't work, try:"
echo ""
echo "1. SSH access (if SSH works):"
echo "   ssh pi@$PI_IP"
echo "   Password: raspberry"
echo ""
echo "2. moOde Web Interface:"
echo "   http://$PI_IP"
echo ""
echo "3. Check Pi SMB service (if you have SSH access):"
echo "   sudo systemctl status smbd"
echo "   sudo systemctl start smbd"
echo ""
echo "4. Try different credentials:"
echo "   - pi / raspberry"
echo "   - andre / 0815"
echo "   - moode / moodeaudio"
echo ""

