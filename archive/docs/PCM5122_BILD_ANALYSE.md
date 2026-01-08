# PCM5122 (U9) - BILD ANALYSE

## AUF DEM BILD SICHTBAR:

### CHIP POSITION:
- **U9 Markierung**: Im Silkscreen (zeigt wo der Chip ist)
- **Chip**: PCM5122 mit "PCM5122", "OCTC4", "CCOR", "BB" Logo
- **Position**: Links im Bild, wo "U9" steht

### CHIP ORIENTIERUNG:
- **Chip ist länglich**: Rechteckig, nicht quadratisch
- **Pins sichtbar**: Entlang der RECHTEN Kante des Chips (im Bild)
- **Das bedeutet**: 
  - Chip liegt horizontal (länglich)
  - Pins sind auf den Längsseiten
  - RECHTE Seite: Pins sichtbar (im Bild)
  - LINKE Seite: Pins auf der anderen Seite (nicht sichtbar)

### PIN-LAYOUT (basierend auf Bild):

```
    BILD-ANSICHT (von oben):
    
    ┌─────────────────────────────────┐
    │                                 │
    │  U9 (Silkscreen)                │
    │                                 │
[16]│  ┌───────────────────────┐     │
[15]│  │                       │     │
[14]│  │   PCM5122             │     │
[13]│  │   (Chip)              │     │
[12]│  │                       │     │
[11]│  │                       │     │
[10]│  │                       │     │
[ 9]│  │                       │     │
[ 8]│  │ ← RST                 │     │
[ 7]│  │                       │     │
[ 6]│  │                       │     │
[ 5]│  │                       │     │
[ 4]│  │                       │     │
[ 3]│  │                       │     │
[ 2]│  │                       │     │
[ 1]│○ │                       │     │
    │  └───────────────────────┘     │
    │                                 │
    └─────────────────────────────────┘
    
    Pins auf RECHTE Seite sichtbar
    Pins auf LINKE Seite (nicht sichtbar, andere Seite)
```

### WICHTIG:
- **Circle/Markierung**: Unten links (vom Chip aus gesehen)
- **Pin 1**: Unten links (wo Circle ist)
- **Pin 8**: Linke Seite, 8. Pin von unten (auf der Seite, die NICHT im Bild sichtbar ist!)

### FÜR MESSUNG:
- Pin 8 ist auf der LINKEN Seite des Chips (nicht sichtbar im Bild)
- Muss von der anderen Seite gemessen werden!

