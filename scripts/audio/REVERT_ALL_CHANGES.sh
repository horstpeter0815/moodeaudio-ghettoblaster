#!/bin/bash
################################################################################
#
# Revert All Debug Changes
# 
# Removes instrumentation and restores original configuration
#
################################################################################

PI_HOST="${1:-192.168.2.3}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

echo "🔄 Reverting all debug changes..."
echo ""

# 1. Restore nginx config
echo "1. Restoring nginx config..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "sudo cp /etc/nginx/sites-available/moode-https.conf.backup /etc/nginx/sites-available/moode-https.conf 2>/dev/null && echo '  ✅ Nginx config restored' || echo '  ⚠️  No backup found'"

# 2. Check if we have clean copies of JS files
echo "2. Checking for original JS files..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "ls -la /var/www/js/*.min.js | head -3"

# 3. Restart nginx
echo "3. Restarting nginx..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "sudo systemctl restart nginx && echo '  ✅ Nginx restarted'"

# 4. Test access
echo "4. Testing web access..."
HTTP_CODE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost/")

if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ Web interface responding (HTTP $HTTP_CODE)"
else
    echo "  ⚠️  Web interface issue (HTTP $HTTP_CODE)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Revert complete. Try accessing: http://$PI_HOST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

