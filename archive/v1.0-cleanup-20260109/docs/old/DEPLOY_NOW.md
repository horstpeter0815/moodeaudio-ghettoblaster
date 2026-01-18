# Deployment auf moOde System

## Option 1: Via SSH (wenn Passwort funktioniert)

```bash
ssh pi@10.10.11.39
# Passwort eingeben

# Script ausführen:
sudo bash /boot/moode_deploy/deploy-on-moode.sh
```

## Option 2: Via Web Terminal (moOde Web UI)

1. Öffne moOde Web UI: `https://10.10.11.39:8443/`
2. Gehe zu **System** → **Terminal** (falls verfügbar)
3. Führe aus:
```bash
sudo bash /boot/moode_deploy/deploy-on-moode.sh
```

## Option 3: Manuell via Web File Manager

1. Öffne moOde Web UI: `https://10.10.11.39:8443/`
2. Gehe zu **File Manager** (falls verfügbar)
3. Navigiere zu `/boot/moode_deploy/`
4. Kopiere Dateien:
   - `fix-index-redirect.php` → `/var/www/html/`
   - `test-wizard/` → `/var/www/html/test-wizard/`
   - `command/room-correction-wizard.php` → `/var/www/html/command/`
5. Setze Berechtigungen:
   - Owner: `www-data:www-data`
   - Permissions: `644` für Dateien, `755` für Verzeichnisse

## Option 4: Via fix-index-redirect.php (nur für Redirect-Fix)

1. Kopiere `fix-index-redirect.php` manuell nach `/var/www/html/` (via File Manager)
2. Öffne: `https://10.10.11.39:8443/fix-index-redirect.php`
3. Klicke "Delete index.html"

## Option 5: Manuelle Befehle (wenn SSH funktioniert)

```bash
# 1. Fix redirect
sudo rm /var/www/html/index.html

# 2. Kopiere test-wizard
sudo mkdir -p /var/www/html/test-wizard
sudo cp -r /boot/moode_deploy/test-wizard/* /var/www/html/test-wizard/
sudo chown -R www-data:www-data /var/www/html/test-wizard
sudo chmod -R 644 /var/www/html/test-wizard/*

# 3. Kopiere room-correction-wizard.php
sudo mkdir -p /var/www/html/command
sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/
sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php
sudo chmod 644 /var/www/html/command/room-correction-wizard.php
```

## Testen nach Deployment

- **Player:** `https://10.10.11.39:8443/` (sollte jetzt funktionieren ohne Redirect)
- **Wizard Test:** `https://10.10.11.39:8443/test-wizard/index-simple.html`

