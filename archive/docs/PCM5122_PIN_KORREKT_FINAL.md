# PCM5122 (U9) PIN-DIAGRAMM - KORREKT (LÄNGLICH, PINS AUF LÄNGSSEITEN)

## IC-FORM: LÄNGLICH (NICHT QUADRATISCH)
## PINS: AUF DEN LÄNGSSEITEN (LINKS UND RECHTS)

### ORIENTIERUNG:
- **IC ist länglich**: Rechteckig, nicht quadratisch
- **Schrift lesbar**: "PCM5122" horizontal lesbar
- **Circle/Markierung**: Unten links
- **Pin 1**: Unten links (wo der Circle ist)
- **Pins auf Längsseiten**: Links und Rechts

### PIN-LAYOUT (von oben, Schrift lesbar, IC länglich):

```
                    PCM5122 (U9)
                    (länglich)
    ┌─────────────────────────────────────┐
    │                                     │
    │ [16]                          [17] │ ← Oben
    │ [15]                          [18] │
    │ [14]                          [19] │
    │ [13]                          [20] │
    │ [12]                          [21] │
    │ [11]                          [22] │
    │ [10]                          [23] │
    │  [9]                          [24] │
    │  [8] ← RST                    [25] │
    │  [7]                          [26] │
    │  [6]                          [27] │
    │  [5]                          [28] │
    │  [4]                          [29] │
    │  [3]                          [30] │
    │  [2]                          [31] │
    │  [1]○                         [32] │ ← Unten
    │                                     │
    └─────────────────────────────────────┘
     (Circle unten links = Pin 1)
     Linke Seite          Rechte Seite
```

### PIN-NUMMERIERUNG (32-Pin, länglich):
- **Pin 1**: Unten links (Circle/Markierung) ⚠️
- **Pins 1-16**: Linke Seite (von unten nach oben)
- **Pins 17-32**: Rechte Seite (von oben nach unten)

### RESET-PIN (RST):
- **Pin 8**: Linke Seite, 8. Pin von unten ⚠️
- **Position**: Linke Seite, zwischen Pin 7 und Pin 9
- **Polarität**: ACTIVE LOW

---

## KORRIGIERTE MESSUNG:

### SCHRITT 1: PCM5122 Pin 8 (Reset-Pin) FINDEN
```
1. IC so drehen, dass "PCM5122" lesbar ist (länglich)
2. Circle/Markierung ist UNTEN LINKS
3. Pin 1 = Unten links (wo Circle ist)
4. Pin 8 = Linke Seite, 8. Pin von unten (zwischen Pin 7 und Pin 9)
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
- **IC ist länglich** (nicht quadratisch)
- **Pins auf Längsseiten** (links und rechts)
- **Pin 1** = Unten links (Circle)
- **Pin 8** = Linke Seite, 8. Pin von unten

