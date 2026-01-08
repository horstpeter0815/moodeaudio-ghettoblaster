# PCM5122 (U9) PIN-DIAGRAMM - KORREKT

## PIN-1 MARKIERUNG: UNTEN LINKS (Circle)

### ORIENTIERUNG:
- **Schrift lesbar**: "PCM5122" horizontal lesbar
- **Circle/Markierung**: Unten links
- **Pin 1**: Unten links (wo der Circle ist)

### PIN-LAYOUT (von oben gesehen, Schrift lesbar):

```
                    PCM5122
                    (U9)
    ┌─────────────────────────────────────┐
    │                                     │
    │ [25] [24] [23] [22] [21] [20] [19] [18]│ ← Obere Kante
    │                                     │
    │ [26]                          [17] │
    │                                     │
    │ [27]                          [16] │
    │                                     │
    │ [28]                          [15] │
    │                                     │
    │ [29]  [30] [31] [32]  [1]  [2]  [3]  [4]│ ← Untere Kante
    │              ○                      │
    │            Pin 1                    │
    └─────────────────────────────────────┘
              (Circle unten links)
```

### PIN-NUMMERIERUNG (32-Pin QFN):
- **Pin 1**: Unten links (Circle/Markierung) ⚠️
- **Pins 1-8**: Untere Kante (von links nach rechts)
- **Pins 9-16**: Rechte Kante (von unten nach oben)
- **Pins 17-24**: Obere Kante (von rechts nach links)
- **Pins 25-32**: Linke Kante (von oben nach unten)

### RESET-PIN (RST):
- **Pin 8**: Unten rechts (letzter Pin auf der unteren Kante) ⚠️
- **Position**: Rechts von Pin 1, auf der unteren Kante
- **Polarität**: ACTIVE LOW

---

## KORRIGIERTE MESSUNG:

### SCHRITT 1: PCM5122 Pin 8 (Reset-Pin) FINDEN
```
1. Chip so drehen, dass "PCM5122" lesbar ist
2. Circle/Markierung ist UNTEN LINKS
3. Pin 1 = Unten links (wo Circle ist)
4. Pin 8 = Unten rechts (8. Pin von links auf der unteren Kante)
```

### SCHRITT 2: Prüfe die 3 goldenen Pads
```
Multimeter: Durchgangsprüfung
Spitze 1: PCM5122 Pin 8 (unten rechts, untere Kante)
Spitze 2: Eines der 3 goldenen Pads (K1, oberes/unteres runde Pad)

✅ BEEP = Dieses Pad führt zum Reset-Pin!
```

---

## WICHTIG:
- **Pin 1** = Unten links (Circle)
- **Pin 8** = Unten rechts (untere Kante)
- **NICHT** oben rechts!

