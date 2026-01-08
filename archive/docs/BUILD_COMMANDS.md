# GHETTOBLASTER BUILD - WICHTIGE BEFEHLE

## Projekt-Pfad
```
/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor
```

## Build-Status prüfen
```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
./check-build-status.sh
```

## Build-Log ansehen

### Letzte 50 Zeilen
```bash
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
docker exec moode-builder tail -50 /tmp/build.log
```

### Live-Log (folgt dem Log)
```bash
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
docker exec -it moode-builder tail -f /tmp/build.log
```

## Container betreten
```bash
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
docker exec -it moode-builder bash
```

## Build neu starten (falls nötig)
```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
docker exec -d moode-builder bash -c "cd /workspace/imgbuild && nohup ./build.sh > /tmp/build.log 2>&1 &"
```

## Docker-Status prüfen
```bash
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
docker ps
docker exec moode-builder echo "Container läuft"
```

## Build-Verzeichnis im Container
```
/workspace/imgbuild
```

## Log-Datei im Container
```
/tmp/build.log
```

