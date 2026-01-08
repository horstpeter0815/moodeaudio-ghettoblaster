# DMG zu IMG Konvertierung - HiFiBerryOS Pi4 Wave

## Durchgeführte Konvertierung

**Quelldatei:**
- `/Users/andrevollmer/Desktop/hifiberryos pi4 wave.dmg` (16MB, komprimiert)

**Zieldatei:**
- `hifiberryos-pi4-wave-final.img` (256MB, UDRW Format)

## Format
- **Format:** UDRW (uncompressed read/write)
- **Größe:** 256MB
- **Typ:** DOS/MBR boot sector, FAT16

## Hinweis
Die DMG enthält nur die Boot-Partition (FAT16). Falls ein vollständiges Image mit Root-Partition benötigt wird, muss die Original-DMG möglicherweise anders extrahiert werden.

## Brennen auf SD-Karte

Die IMG-Datei kann mit folgenden Tools gebrannt werden:

1. **Raspberry Pi Imager** (empfohlen)
   - Öffne Raspberry Pi Imager
   - Wähle "Use custom image"
   - Wähle `hifiberryos-pi4-wave-final.img`
   - Wähle SD-Karte
   - Klicke "Write"

2. **balenaEtcher**
   - Öffne balenaEtcher
   - Wähle "Flash from file"
   - Wähle `hifiberryos-pi4-wave-final.img`
   - Wähle SD-Karte
   - Klicke "Flash"

3. **dd (Terminal)**
   ```bash
   sudo dd if=hifiberryos-pi4-wave-final.img of=/dev/diskX bs=1m
   ```
   ⚠️ **WICHTIG:** Ersetze `diskX` mit der richtigen SD-Karte (z.B. `disk2`)

## Datei-Pfad
```
/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/hifiberryos-pi4-wave-final.img
```

