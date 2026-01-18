# Build Status

**Letzte Aktualisierung:** $(date)

## ✅ Was wurde behoben:

1. ✅ **ssh-asap.service** - Nach moode-source kopiert
2. ✅ **boot-debug-logger.sh** - Erstellt (fehlte)
3. ✅ **boot-debug-logger.service** - Anführungszeichen korrigiert
4. ✅ **ssh-guaranteed.service** - Before=cloud-init.target hinzugefügt
5. ✅ **ssh-watchdog.service** - Timing optimiert

## 📊 Build-Status prüfen:

```bash
# Container-Status
docker ps | grep moode-builder

# Build-Prozess
docker exec moode-builder bash -c 'ps aux | grep build.sh'

# Build-Logs (Live)
docker exec moode-builder bash -c 'tail -f /workspace/imgbuild/build-*.log'

# Neuestes Log
docker exec moode-builder bash -c 'ls -t /workspace/imgbuild/build-*.log | head -1 | xargs tail -50'
```

## ⏱️ Geschätzte Build-Zeit:

**8-12 Stunden**

## 📁 Image-Location nach Build:

`imgbuild/deploy/moode-r1001-arm64-*.img`

## 🔍 Wenn Build fehlschlägt:

```bash
# Fehler-Logs ansehen
docker exec moode-builder bash -c 'tail -100 /workspace/imgbuild/build-*.log | grep -A 10 -B 10 "error\|Error\|ERROR\|failed\|Failed\|FAILED"'

# Build neu starten
./RESTART_BUILD.sh
```

