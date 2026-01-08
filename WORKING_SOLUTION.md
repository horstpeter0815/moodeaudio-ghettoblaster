# FUNKTIONIERENDE LÖSUNG - OHNE SSH

## Problem identifiziert
- `/var/www/html/index.html` auf moOde leitet auf Wizard um
- SSH funktioniert nicht für Deployment

## Lösung: Web-basiertes Fix-Script

### Schritt 1: Fix-Script hochladen
1. Datei `fix-index-redirect.php` auf moOde kopieren nach `/var/www/html/fix-index-redirect.php`
2. Über Web-UI File Manager (falls verfügbar)
3. ODER: Per USB-Stick/SD-Karte

### Schritt 2: Script ausführen
1. Öffne im Browser: `https://10.10.11.39:8443/fix-index-redirect.php`
2. Klicke auf "Delete index.html (Fix Redirect)"
3. index.html wird gelöscht/gesichert

### Schritt 3: Player-Zugriff
Nach dem Fix:
- **Player:** `https://10.10.11.39:8443/` (funktioniert jetzt)
- **Wizard:** `https://10.10.11.39:8443/index-simple.html`

## Alternative: Dateien direkt auf moOde erstellen

Falls File Manager verfügbar:
1. Gehe zu `/var/www/html/`
2. Lösche `index.html` manuell
3. Oder benenne um zu `index.html.backup`

## Status
✅ Fix-Script erstellt: `fix-index-redirect.php`
✅ Kann über Web-UI ausgeführt werden
✅ Kein SSH nötig

