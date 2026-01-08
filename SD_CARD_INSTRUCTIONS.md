# SD-Karte Deployment - Anleitung

## Schritt 1: SD-Karte vorbereiten

1. **SD-Karte in Mac einstecken**
2. **SD-Karte sollte als `/Volumes/boot` oder `/Volumes/BOOT` erscheinen**

## Schritt 2: Dateien kopieren

Führe aus:
```bash
./copy-to-sd.sh
```

Das Script:
- Findet automatisch die SD-Karte
- Kopiert alle notwendigen Dateien nach `/Volumes/boot/moode_deploy/`
- Erstellt Installations-Anleitung

## Schritt 3: SD-Karte in Raspberry Pi

1. **SD-Karte auswerfen**
2. **SD-Karte in Raspberry Pi stecken**
3. **moOde booten**

## Schritt 4: Installation auf moOde

**Via SSH (wenn Passwort funktioniert):**
```bash
ssh pi@10.10.11.39
# Passwort eingeben

# Dann ausführen:
sudo cp /boot/moode_deploy/fix-index-redirect.php /var/www/html/
sudo chown www-data:www-data /var/www/html/fix-index-redirect.php
sudo chmod 644 /var/www/html/fix-index-redirect.php

sudo cp -r /boot/moode_deploy/test-wizard /var/www/html/
sudo chown -R www-data:www-data /var/www/html/test-wizard
sudo chmod -R 644 /var/www/html/test-wizard/*

sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/
sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php
sudo chmod 644 /var/www/html/command/room-correction-wizard.php

# Redirect fixen
sudo rm /var/www/html/index.html
```

**ODER via Web File Manager:**
1. Öffne moOde Web-UI
2. Gehe zu File Manager
3. Navigiere zu `/boot/moode_deploy/`
4. Kopiere Dateien nach `/var/www/html/`
5. Setze Berechtigungen (www-data:www-data, 644)

**ODER via Web Fix-Script:**
1. Kopiere `fix-index-redirect.php` manuell nach `/var/www/html/`
2. Öffne: `https://10.10.11.39:8443/fix-index-redirect.php`
3. Klicke "Delete index.html"

## Schritt 5: Testen

- **Player:** `https://10.10.11.39:8443/`
- **Wizard:** `https://10.10.11.39:8443/index-simple.html`

## Dateien auf SD-Karte

Nach `./copy-to-sd.sh` sind folgende Dateien auf der SD-Karte:

```
/boot/moode_deploy/
├── fix-index-redirect.php
├── test-wizard/
│   ├── index-simple.html
│   ├── wizard-functions.js
│   └── snd-config.html
├── command/
│   └── room-correction-wizard.php
└── INSTALL.txt
```

## Alternative: Manuelles Kopieren

Falls das Script nicht funktioniert, kopiere manuell:

1. Erstelle auf SD-Karte: `/boot/moode_deploy/`
2. Kopiere alle Dateien aus diesem Projekt:
   - `fix-index-redirect.php` → `/boot/moode_deploy/`
   - `test-wizard/*` → `/boot/moode_deploy/test-wizard/`
   - `moode-source/www/command/room-correction-wizard.php` → `/boot/moode_deploy/command/`

