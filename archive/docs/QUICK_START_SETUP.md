# Quick Start - System Setup

## Schnellstart (3 Schritte)

### 1. Script auf Pi kopieren

```bash
scp SETUP_ON_PI.sh andre@192.168.178.162:/tmp/
```

### 2. Auf Pi ausführen

```bash
ssh andre@192.168.178.162
sudo bash /tmp/SETUP_ON_PI.sh
```

### 3. Reboot

```bash
sudo reboot
```

## Nach Reboot

### Video-Test ausführen (sicher, überschreibt nichts)

```bash
# Test-Script auf Pi kopieren:
scp VIDEO_PIPELINE_TEST_SAFE.sh andre@192.168.178.162:/tmp/

# Auf Pi ausführen:
ssh andre@192.168.178.162
bash /tmp/VIDEO_PIPELINE_TEST_SAFE.sh
```

## Was wird konfiguriert?

✅ Display: 1280x400 Landscape  
✅ Touchscreen: Korrekte Transformation  
✅ Chromium: Kiosk-Mode mit Moode Audio UI  
✅ X11: Automatischer Start  

## Backup

Das Setup-Script erstellt automatisch ein Backup in:
`/home/andre/backup_YYYYMMDD_HHMMSS/`

---

**Fertig!** Das System sollte jetzt vollständig funktionieren.

