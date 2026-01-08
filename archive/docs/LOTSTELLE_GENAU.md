# GENAUE LÖTSTELLE - GPIO 14 zu PCM5122 Reset

## BASIEREND AUF DEM BILD

### PCM5122 CHIP FINDEN:
1. **Kleiner quadratischer IC** auf dem AMP100 Board
2. Normalerweise **in der Nähe der GPIO Header**
3. Größe: ca. 5x5mm oder 6x6mm (QFN Package)
4. Hat eine **Markierung für Pin 1** (Punkt oder Kerbe in einer Ecke)

### RESET-PIN (RST) LOKALISIEREN:
- **Pin 1** = Ecke mit Markierung (Punkt/Kerbe)
- **Pin-Nummerierung** = im Uhrzeigersinn von Pin 1
- **Pin 8** = Reset-Pin (RST) - laut PCM5122 Datenblatt
- **Position**: 8. Pin im Uhrzeigersinn von Pin 1 (erste Reihe, letzter Pin)

### PCM5122 QFN PACKAGE (32-Pin):
```
Pin-Layout (von oben, Pin 1 oben links):
[1]  [2]  [3]  [4]  [5]  [6]  [7]  [8] ← RST (Reset-Pin)
[32]                          [9]
[31]                          [10]
[30]                          [11]
[29]  [28] [27] [26] [25] [24] [23] [22]
[21]  [20] [19] [18] [17] [16] [15] [14] [13]
```

**Pin 8 = Reset-Pin (RST)** - letzter Pin in der ersten Reihe (oben rechts)

### ALTERNATIVE METHODE - 3 LÖTPINLÖCHER:
Auf dem Board gibt es **3 Lötpinlöcher**, die viel einfacher zu löten sind:

1. **K1 (oben rechts):**
   - Goldenes quadratisches Pad mit Loch
   - Markiert als "K1"
   - Könnte ein Testpunkt oder Lötstelle sein

2. **Zwei goldene runde Pads (unter C61/C62):**
   - Zwei runde Pads mit Löchern
   - Vertikal angeordnet
   - Könnten Testpunkte für Reset oder andere Signale sein

**PRÜFUNG MIT MULTIMETER:**
- Eines dieser Löcher könnte direkt zum Reset-Pin (Pin 8) des PCM5122 führen
- Mit Multimeter Durchgang prüfen: Von Pin 8 des PCM5122 zu jedem der 3 Löcher
- Das Loch mit Durchgang = Reset-Pin Lötstelle!

**VORTEIL:**
- Viel einfacher zu löten als direkt am Chip
- Größere Lötfläche
- Weniger Risiko, andere Pins zu beschädigen

### LÖTVERBINDUNG:
```
Raspberry Pi Pin 8 (GPIO 14)  ----->  PCM5122 Pin 8 (RST)
```

**WICHTIG:** 
- Raspberry Pi Pin 8 = GPIO 14
- PCM5122 Pin 8 = Reset-Pin (RST)
- Beide sind "Pin 8", aber an unterschiedlichen Stellen!

**WICHTIG:**
- Sehr dünnes Kabel verwenden (z.B. 30 AWG)
- Vorsichtig löten, um andere Pins nicht zu berühren
- Isolierung sicherstellen

