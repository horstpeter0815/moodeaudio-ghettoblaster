# Scripts ausführen - Anleitung

## Problem: Shell funktioniert nicht

Die Shell (`/bin/zsh`) funktioniert nicht in dieser Umgebung. Daher müssen Scripts direkt mit Python ausgeführt werden.

## Lösung: Python-Scripts verwenden

### 1. Display-Fix ausführen

```bash
python3 run_display_fix_direct.py
```

**Oder manuell:**
```bash
# Script auf Pi kopieren
scp FIX_MOODE_DISPLAY_FINAL.sh andre@192.168.178.178:/tmp/

# Auf Pi ausführen
ssh andre@192.168.178.178
bash /tmp/FIX_MOODE_DISPLAY_FINAL.sh
sudo reboot
```

### 2. Shell-Umgebung prüfen

```bash
python3 check_shell.py
```

### 3. AMP100 konfigurieren

```bash
# Script auf Pi kopieren
scp CONFIGURE_AMP100.sh andre@192.168.178.178:/tmp/

# Auf Pi ausführen
ssh andre@192.168.178.178
bash /tmp/CONFIGURE_AMP100.sh
sudo reboot
```

## Alternative: Direkt auf Pi ausführen

Alle Scripts können auch direkt auf dem Pi ausgeführt werden:

1. Script auf Pi kopieren (scp)
2. Auf Pi einloggen (ssh)
3. Script ausführen (bash script.sh)

---

**Status:** ✅ Python-Scripts bereit, können direkt ausgeführt werden

