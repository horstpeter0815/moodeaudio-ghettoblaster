# LÖTANLEITUNG: GPIO 14 als Reset-Pin für AMP100

## ZIEL
GPIO 14 (Raspberry Pi Pin 8) direkt zum Reset-Pin des PCM5122 löten, um das AMP100-Board zu umgehen.

## HARDWARE-VERBINDUNG

### Raspberry Pi Seite:
- **GPIO 14** = **Physischer Pin 8** (GPIO Header)
- Pin 8 ist der 4. Pin von oben links (wenn Header oben ist)

### AMP100 / PCM5122 Seite:
- **Reset-Pin des PCM5122 Chips** (nicht über AMP100 Board)
- Der PCM5122 Chip ist auf dem AMP100 Board
- Reset-Pin ist normalerweise Pin 4 des PCM5122 (RST Pin)

## SCHRITTE

### 1. PCM5122 Reset-Pin finden:
- PCM5122 Chip auf AMP100 Board lokalisieren
- Reset-Pin (RST) ist normalerweise Pin 4 des PCM5122
- Oder: Prüfe das PCM5122 Datenblatt für genaue Pin-Nummer

### 2. Verbindung löten:
```
Raspberry Pi Pin 8 (GPIO 14)  ----->  PCM5122 Reset-Pin (RST)
```

### 3. WICHTIG:
- **NICHT** zum Reset-Pin über das AMP100 Board
- **DIREKT** zum PCM5122 Chip Reset-Pin
- Das umgeht das AMP100 Board und mögliche Konflikte mit DSP Add-on

## NACH DEM LÖTEN

1. Overlay aktivieren in `/boot/firmware/config.txt`:
   ```
   dtoverlay=hifiberry-amp100-pi5-gpio14
   ```

2. Altes Overlay entfernen:
   ```
   # dtoverlay=hifiberry-amp100-pi5  (auskommentieren oder löschen)
   ```

3. Reboot

## PRÜFUNG

Nach Reboot prüfen:
- `cat /proc/asound/cards` - sollte AMP100 zeigen
- `dmesg | grep pcm5122` - sollte keine Reset-Fehler zeigen

## HINWEIS

GPIO 14 ist normalerweise UART TXD, aber kann für Reset verwendet werden.
Das Overlay konfiguriert GPIO 14 als Reset-Pin.

