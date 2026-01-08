#!/bin/bash
# Ghettoblaster - worker.php Patch für display_rotate=0 (Landscape)
WORKER_FILE="/var/www/daemon/worker.php"

# Prüfe ob Patch bereits angewendet wurde
if grep -q "Ghettoblaster: display_rotate=0" "$WORKER_FILE"; then
    exit 0
fi

# Patch anwenden
sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
		// Ghettoblaster: Stelle display_rotate=0 wieder her (Landscape)\
		sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
		sysCmd("echo \"display_rotate=0\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"

echo "✅ worker.php Patch angewendet"
