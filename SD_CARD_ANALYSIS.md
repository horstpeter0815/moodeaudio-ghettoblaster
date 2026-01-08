# SD-Karte Analyse

**Datum:** $(date)

## 📊 SD-Karte Status:

### Gerät:
- **Device:** /dev/disk4
- **Größe:** 63.9 GB
- **Partitionen:** 4 (ungewöhnlich für Moode Image!)

### Partitionen:
1. **disk4s1:** Windows_FAT_32 (268.4 MB) - Boot-Partition
2. **disk4s2:** Linux (8.2 GB) - Root-Partition 1?
3. **disk4s3:** Linux (8.2 GB) - Root-Partition 2?
4. **disk4s4:** Linux (47.2 GB) - Data-Partition?

## ⚠️ Problem:

**SD-Karte hat 4 Partitionen statt 2!**

Ein normales Moode Image sollte nur haben:
- 1x Boot-Partition (FAT32, ~268MB)
- 1x Root-Partition (ext4, ~4-5GB)

**Mögliche Ursachen:**
1. Altes Image noch auf SD-Karte
2. Image wurde nicht erfolgreich geschrieben
3. SD-Karte hatte vorher ein anderes System (z.B. DietPi mit mehreren Partitionen)

## ✅ Lösung:

**SD-Karte komplett neu beschreiben:**
1. SD-Karte sicher auswerfen
2. Image komplett neu schreiben (überschreibt alle Partitionen)
3. Danach sollte nur noch 2 Partitionen vorhanden sein

## 📋 Nächste Schritte:

1. **SD-Karte auswerfen:**
   ```bash
   diskutil eject /dev/disk4
   ```

2. **Image neu schreiben:**
   ```bash
   ./WRITE_IMAGE_TO_SD.sh
   ```

3. **Nach dem Schreiben prüfen:**
   ```bash
   diskutil list /dev/disk4
   ```
   Sollte nur 2 Partitionen zeigen!


