#!/bin/bash
# Deploy fix-index-redirect.php to moOde
# This script copies the fix script that can be run via web browser

MOODE_IP="${1:-10.10.11.39}"
MOODE_USER="${2:-pi}"

echo "Deploying fix-index-redirect.php to moOde..."

# Copy fix script
scp fix-index-redirect.php ${MOODE_USER}@${MOODE_IP}:/tmp/
ssh ${MOODE_USER}@${MOODE_IP} "sudo mv /tmp/fix-index-redirect.php /var/www/html/fix-index-redirect.php && sudo chown www-data:www-data /var/www/html/fix-index-redirect.php && sudo chmod 644 /var/www/html/fix-index-redirect.php"

echo ""
echo "Fix script deployed!"
echo "Now open in browser: https://${MOODE_IP}:8443/fix-index-redirect.php"
echo "Click 'Delete index.html' to fix the redirect issue."

