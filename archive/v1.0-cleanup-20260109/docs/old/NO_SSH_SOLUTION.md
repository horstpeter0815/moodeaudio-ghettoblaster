# Lösung OHNE SSH

## Problem: SSH funktioniert nicht - wir verschwenden zu viel Zeit

## Lösung 1: Prüfe ob Dateien schon auf moOde sind

Öffne im Browser:
```
https://10.10.11.39:8443/index-simple.html
```

**Falls die Seite lädt:** Dateien sind bereits da! Kein Deployment nötig.

**Falls 404 Error:** Dateien fehlen noch.

## Lösung 2: SD-Karte direkt bearbeiten

1. Raspberry ausschalten
2. SD-Karte entfernen
3. SD-Karte in Mac einlesen
4. Dateien kopieren nach:
   - `/var/www/html/index-simple.html`
   - `/var/www/html/test-wizard/wizard-functions.js`
   - `/var/www/html/test-wizard/snd-config.html`
   - `/var/www/html/command/room-correction-wizard.php`

## Lösung 3: Web-UI File Manager

Falls moOde einen File Manager hat:
1. Öffne https://10.10.11.39:8443/
2. Suche nach "File Manager" oder "Admin"
3. Lade Dateien hoch

## Lösung 4: Später deployen

**Die Dateien sind fertig im Projekt:**
- `test-wizard/index-simple.html`
- `test-wizard/wizard-functions.js`
- `test-wizard/snd-config.html`
- `moode-source/www/command/room-correction-wizard.php`

**Deployment kann später gemacht werden, wenn SSH funktioniert.**

## WICHTIG: Teste zuerst ob es schon funktioniert!

Öffne: https://10.10.11.39:8443/index-simple.html

Falls die Seite lädt → **FERTIG! Kein Deployment nötig!**

