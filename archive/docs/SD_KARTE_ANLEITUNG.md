# SD-Karte Brennen - Anleitung

## ✅ Status

- **SD-Karte:** Im Mac eingesteckt (`/dev/disk4` oder `/dev/disk5`)
- **Image:** `imgbuild/deploy/moode-r1001-arm64-20251208_101237-lite.img` (5.0GB)
- **Script:** `BURN_IMAGE_TO_SD.sh` (bereit)

## 🚀 Image auf SD-Karte brennen

### Automatisch (empfohlen):

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
./BURN_IMAGE_TO_SD.sh
```

Das Script:
1. Findet automatisch die SD-Karte
2. Findet automatisch das neueste Image
3. Fragt nach Bestätigung (eingeben: `j`)
4. Fragt nach sudo-Passwort
5. Brennt das Image (5-10 Minuten)
6. Prüft das Ergebnis

### Manuell:

```bash
# 1. SD-Karte finden
diskutil list

# 2. SD-Karte unmounten (z.B. /dev/disk4)
diskutil unmountDisk /dev/disk4

# 3. Image brennen
sudo dd if=imgbuild/deploy/moode-r1001-arm64-20251208_101237-lite.img \
        of=/dev/rdisk4 bs=1m status=progress

# 4. Synchronisieren
sync
```

## ⚠️ Wichtig

- **Alle Daten auf der SD-Karte werden gelöscht!**
- Verwende `rdisk` statt `disk` für schnellere Schreibgeschwindigkeit
- Das Brennen dauert 5-10 Minuten (je nach SD-Karte)
- Warte bis `dd` fertig ist, bevor du die SD-Karte entfernst

## ✅ Nach dem Brennen

1. SD-Karte in Pi einstecken
2. Pi booten lassen
3. Serial Console überwachen (falls Debugger verbunden)
4. Pi-Verbindung prüfen (SSH auf 192.168.178.143)

## 🔧 Troubleshooting

### SD-Karte wird nicht gefunden:
- SD-Karte richtig einstecken
- `diskutil list` ausführen und prüfen

### Image brennt nicht:
- Prüfe ob Image vorhanden: `ls -lh imgbuild/deploy/*.img`
- Prüfe SD-Karte: `diskutil info /dev/diskX`
- Stelle sicher, dass SD-Karte unmounted ist

### Pi bootet nicht:
- Prüfe Serial Console
- Prüfe ob Image korrekt gebrannt wurde
- Prüfe SD-Karte auf Fehler

