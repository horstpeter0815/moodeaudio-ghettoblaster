#!/bin/bash
################################################################################
# RESET GHETTOBLASTER CONNECTION
# Clears cached credentials so login window appears again
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 RESETTING GHETTOBLASTER CONNECTION                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Disconnect any active connections
echo "1. Disconnecting from GhettoBlaster..."
smbutil statshares -a 2>&1 | grep -i "ghetto" && {
    smbutil disconnect //GhettoBlaster.local 2>&1 || true
    smbutil disconnect //GhettoBlaster 2>&1 || true
    echo "✅ Disconnected"
} || echo "✅ No active connections"

# 2. Clear cached credentials
echo ""
echo "2. Clearing cached credentials..."
security delete-internet-password -s GhettoBlaster.local 2>&1 || true
security delete-internet-password -s GhettoBlaster 2>&1 || true
security delete-internet-password -s "//GhettoBlaster.local" 2>&1 || true
security delete-internet-password -s "//GhettoBlaster" 2>&1 || true
echo "✅ Credentials cleared"

# 3. Clear Keychain entries
echo ""
echo "3. Clearing Keychain entries..."
security find-internet-password -s GhettoBlaster.local 2>&1 | grep "keychain:" | awk '{print $2}' | tr -d '"' | while read keychain; do
    security delete-internet-password -s GhettoBlaster.local "$keychain" 2>&1 || true
done
echo "✅ Keychain cleared"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ RESET COMPLETE!                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Now try connecting again:"
echo "  1. Open Finder"
echo "  2. Click on GhettoBlaster in Network"
echo "  3. Login window should appear"
echo ""
echo "Or connect manually:"
echo "  Press Cmd+K in Finder"
echo "  Enter: smb://GhettoBlaster.local"
echo "  Click Connect"
echo "  Login window will appear"
echo ""

