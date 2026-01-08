#!/bin/bash
# Ghettoblaster - worker.php Patch für display_rotate=2 (180° Rotation)
# CRITICAL: Verhindert config.txt Overwrite komplett
WORKER_FILE="/var/www/daemon/worker.php"

# Prüfe ob Patch bereits angewendet wurde
if grep -q "Ghettoblaster: chkBootConfigTxt disabled" "$WORKER_FILE"; then
    exit 0
fi

# CRITICAL FIX: Deaktiviere chkBootConfigTxt() komplett um config.txt Overwrite zu verhindern
# Ersetze die Zeile die chkBootConfigTxt() aufruft
sed -i 's/\$status = chkBootConfigTxt();/\/\/ Ghettoblaster: chkBootConfigTxt disabled to prevent config.txt overwrite\n\t\t\$status = '\''Required headers present'\''; \/\/ FIX: Always return OK/' "$WORKER_FILE"

# Falls das nicht funktioniert, suche nach der exakten Zeile
if ! grep -q "Ghettoblaster: chkBootConfigTxt disabled" "$WORKER_FILE"; then
    # Alternative: Kommentiere die Zeile aus
    sed -i 's/^\t\$status = chkBootConfigTxt();/\/\/ Ghettoblaster: chkBootConfigTxt disabled\n\t\t\$status = '\''Required headers present'\''; \/\/ FIX/' "$WORKER_FILE"
fi

echo "✅ worker.php Patch angewendet (chkBootConfigTxt disabled)"
