#!/bin/bash
################################################################################
#
# SETUP FRITZ NAS CONNECTION
# 
# Einfaches Setup für Fritz NAS Archivierung
#
################################################################################

set -e

NAS_HOST="fritz.box"
MOUNT_POINT="$HOME/fritz-nas-archive"

echo "=== FRITZ NAS SETUP ==="
echo ""
echo "Fritz Box erreichbar: $(ping -c 1 -W 1000 $NAS_HOST >/dev/null 2>&1 && echo '✅ Ja' || echo '❌ Nein')"
echo ""

# Prüfe verfügbare Shares
echo "Verfügbare Shares auf $NAS_HOST:"
smbutil view //$NAS_HOST 2>/dev/null | grep -E "^[[:space:]]*[A-Z]" | head -10 || echo "Konnte Shares nicht auflisten"

echo ""
echo "Bitte Share-Namen eingeben (z.B. 'fritz.nas', 'usb_storage', etc.):"
read -r NAS_SHARE

echo ""
echo "Benutzername (Enter für 'guest'):"
read -r NAS_USER
NAS_USER=${NAS_USER:-guest}

echo ""
if [ "$NAS_USER" != "guest" ]; then
    echo "Passwort:"
    read -rs NAS_PASS
    echo ""
fi

# Erstelle Mount-Point (im Home-Verzeichnis, kein sudo nötig)
mkdir -p "$MOUNT_POINT"

# Versuche zu mounten
echo "Versuche NAS zu mounten..."
MOUNT_SUCCESS=false

# Methode 1: Mit Passwort im Befehl
if [ "$NAS_USER" != "guest" ] && [ -n "$NAS_PASS" ]; then
    echo "Versuche Methode 1: Mit Passwort..."
    mount_smbfs "//$NAS_USER:$NAS_PASS@$NAS_HOST/$NAS_SHARE" "$MOUNT_POINT" 2>&1 && MOUNT_SUCCESS=true
fi

# Methode 2: Ohne Passwort (wird interaktiv abgefragt)
if [ "$MOUNT_SUCCESS" = false ]; then
    echo "Versuche Methode 2: Interaktive Passwort-Eingabe..."
    mount_smbfs "//$NAS_USER@$NAS_HOST/$NAS_SHARE" "$MOUNT_POINT" 2>&1 && MOUNT_SUCCESS=true
fi

# Methode 3: Mit Domain (falls Fritz Box das benötigt)
if [ "$MOUNT_SUCCESS" = false ]; then
    echo "Versuche Methode 3: Mit Domain..."
    mount_smbfs "//$NAS_USER@$NAS_HOST/$NAS_SHARE" "$MOUNT_POINT" -o domain=WORKGROUP 2>&1 && MOUNT_SUCCESS=true
fi

# Prüfe ob erfolgreich
if mount | grep -q "$MOUNT_POINT"; then
    echo "✅ NAS erfolgreich gemountet auf $MOUNT_POINT"
    echo ""
    echo "Verfügbarer Speicher:"
    df -h "$MOUNT_POINT" | tail -1
    echo ""
    echo "Sie können jetzt ARCHIVE_TO_NAS.sh verwenden!"
elif [ "$MOUNT_SUCCESS" = false ]; then
    echo ""
    echo "❌ Mount fehlgeschlagen - Mögliche Lösungen:"
    echo ""
    echo "1. Prüfen Sie Share-Name (aktuell: '$NAS_SHARE')"
    echo "   Verfügbare Shares:"
    smbutil view //$NAS_HOST 2>&1 | grep -E "^[[:space:]]*[A-Z]" | head -10 || echo "   Konnte Shares nicht auflisten"
    echo ""
    echo "2. Prüfen Sie Benutzername und Passwort"
    echo ""
    echo "3. Manuell mounten (wird Passwort interaktiv abfragen):"
    echo "   mount_smbfs //$NAS_USER@$NAS_HOST/$NAS_SHARE $MOUNT_POINT"
    echo ""
    echo "4. Alternative: Finder verwenden"
    echo "   - Finder öffnen"
    echo "   - Cmd+K (oder Gehe zu > Mit Server verbinden)"
    echo "   - smb://fritz.box/$NAS_SHARE eingeben"
    echo "   - Mit Benutzername 'Andre' verbinden"
fi

