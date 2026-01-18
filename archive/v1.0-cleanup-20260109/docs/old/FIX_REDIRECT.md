# FIX: Haupt-URL leitet auf Wizard um

## Problem
`https://10.10.11.39:8443/` leitet auf `index-simple.html` um (Wizard)

## Lösung

### Option 1: index.html auf moOde löschen/umbenennen
```bash
# Am moOde-System (wenn SSH funktioniert):
sudo mv /var/www/html/index.html /var/www/html/index.html.backup
```

### Option 2: index-simple.html direkt aufrufen
```
https://10.10.11.39:8443/index-simple.html
```

### Option 3: index.php direkt aufrufen (Player)
```
https://10.10.11.39:8443/index.php
```

## Status
- `index.html` (Redirect) wurde aus dem Projekt gelöscht
- Muss noch auf moOde gelöscht/umbenannt werden
- Bis dahin: `index.php` oder `index-simple.html` direkt aufrufen

