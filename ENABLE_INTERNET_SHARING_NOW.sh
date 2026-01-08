#!/bin/bash
# ENABLE INTERNET SHARING - GIVES PI AN IP ADDRESS
# This enables Internet Sharing so Pi gets an IP via Ethernet cable

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🌐 ENABLE INTERNET SHARING - GIB PI EINE IP                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "Problem: Pi zeigt 127.0.0.1 (localhost) = KEINE Netzwerk-IP!"
echo ""
echo "Lösung: Internet Sharing aktivieren"
echo ""

# Enable Internet Sharing via defaults
echo "=== AKTIVIERE INTERNET SHARING ==="
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add Enabled -int 1

# Try to start natd (if available)
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.natd.plist 2>/dev/null || true

echo ""
echo "✅ Internet Sharing aktiviert (falls möglich)"
echo ""
echo "⚠️  WICHTIG: Prüfe manuell in System Settings:"
echo "   System Settings → General → Sharing → Internet Sharing"
echo "   - Share from: Wi-Fi"
echo "   - To: Ethernet (en4)"
echo "   - Status: AN"
echo ""
echo "Nach Aktivierung:"
echo "  1. Warte 30 Sekunden"
echo "  2. Pi sollte IP bekommen: 192.168.2.x"
echo "  3. Prüfe Pi IP mit: arp -a | grep -i 'b8:27:eb\|dc:a6:32'"
echo ""

