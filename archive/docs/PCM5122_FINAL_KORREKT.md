# PCM5122 (U9) - FINALE KORREKTE VERSION

## BASIEREND AUF DEM BILD:

### CHIP (U9):
- **Form**: Länglich (rechteckig, nicht quadratisch)
- **Markierung**: "PCM5122", "OCTG4", "CCOR", "BB" Logo
- **Position**: Zentral auf dem Board
- **Pins**: Auf den LÄNGSSEITEN (links und rechts)

### ORIENTIERUNG:
- **IC liegt horizontal**: Länglich, breiter als hoch
- **Schrift lesbar**: "PCM5122" horizontal lesbar
- **Circle/Markierung**: Unten links (vom Chip aus gesehen)
- **Pin 1**: Unten links (wo Circle ist)

### PIN-LAYOUT (längliches Rechteck, Pins nur links/rechts):

```
    ┌─────────────────────────────────────────────┐
    │                                             │
[16]│                                             │[17]
[15]│                                             │[18]
[14]│                                             │[19]
[13]│                                             │[20]
[12]│                                             │[21]
[11]│                                             │[22]
[10]│                                             │[23]
[ 9]│                                             │[24]
[ 8]│ ← RST (Reset-Pin)                          │[25]
[ 7]│                                             │[26]
[ 6]│                                             │[27]
[ 5]│                                             │[28]
[ 4]│                                             │[29]
[ 3]│                                             │[30]
[ 2]│                                             │[31]
[ 1]│○                                            │[32]
    └─────────────────────────────────────────────┘
     
     Linke Seite:          Rechte Seite:
     Pins 1-16              Pins 17-32
     (von unten nach oben)  (von oben nach unten)
     
     Circle unten links = Pin 1
```

### PIN-NUMMERIERUNG:
- **Pin 1**: Unten links (Circle/Markierung)
- **Pins 1-16**: Linke Seite (von unten nach oben)
- **Pins 17-32**: Rechte Seite (von oben nach unten)
- **Pin 8**: Reset-Pin (RST) - Linke Seite, 8. Pin von unten

### RESET-PIN (RST) FÜR MESSUNG:
- **Position**: Linke Seite des Chips, 8. Pin von unten
- **Polarität**: ACTIVE LOW
- **Zu messen**: Von der linken Seite des Chips (nicht sichtbar im Bild)

---

## MULTIMETER-MESSUNG:

### SCHRITT 1: PCM5122 Pin 8 FINDEN
```
1. Chip so drehen, dass "PCM5122" lesbar ist
2. Circle ist UNTEN LINKS
3. Pin 1 = Unten links (wo Circle ist)
4. Pin 8 = Linke Seite, 8. Pin von unten
5. Pin 8 ist auf der LINKEN Seite (nicht sichtbar im Bild)
```

### SCHRITT 2: Prüfe die 3 goldenen Pads
```
Multimeter: Durchgangsprüfung
Spitze 1: PCM5122 Pin 8 (linke Seite, 8. Pin von unten)
Spitze 2: Eines der 3 goldenen Pads (K1, oberes/unteres runde Pad)

✅ BEEP = Dieses Pad führt zum Reset-Pin!
```

---

## WICHTIG:
- **IC ist länglich** (rechteckig, nicht quadratisch)
- **Pins nur auf Längsseiten** (links und rechts, KEINE oben/unten)
- **Pin 1** = Unten links (Circle)
- **Pin 8** = Linke Seite, 8. Pin von unten (Reset-Pin)

