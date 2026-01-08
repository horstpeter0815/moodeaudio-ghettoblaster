# PCM5122 (U9) PIN-DIAGRAMM - ENDLICH RICHTIG!

## IC: LÄNGLICHES RECHTECK (NICHT QUADRATISCH!)
## PINS: NUR AUF LINKS UND RECHTS (KEINE OBEN/UNTEN!)

### ORIENTIERUNG:
- **IC ist länglich**: Rechteckig, breiter als hoch
- **Schrift lesbar**: "PCM5122" horizontal lesbar
- **Circle/Markierung**: Unten links
- **Pin 1**: Unten links (wo der Circle ist)
- **Pins NUR auf Längsseiten**: Links und Rechts (KEINE oben/unten!)

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
     (Circle unten links = Pin 1)
     
     Linke Seite:          Rechte Seite:
     Pins 1-16              Pins 17-32
     (von unten nach oben)  (von oben nach unten)
```

### PIN-NUMMERIERUNG:
- **Pin 1**: Unten links (Circle/Markierung)
- **Pins 1-16**: Linke Seite (von unten nach oben)
- **Pins 17-32**: Rechte Seite (von oben nach unten)
- **Pin 8**: Reset-Pin (RST) - Linke Seite, 8. Pin von unten

### RESET-PIN (RST):
- **Pin 8**: Linke Seite, 8. Pin von unten
- **Position**: Zwischen Pin 7 und Pin 9 auf der linken Seite
- **Polarität**: ACTIVE LOW

---

## MESSUNG:

### PCM5122 Pin 8 FINDEN:
1. IC so drehen, dass "PCM5122" lesbar ist (länglich, horizontal)
2. Circle ist UNTEN LINKS
3. Pin 1 = Unten links (wo Circle ist)
4. Pin 8 = Linke Seite, 8. Pin von unten

### Multimeter:
- Spitze 1: PCM5122 Pin 8 (linke Seite, 8. Pin von unten)
- Spitze 2: Eines der 3 goldenen Pads
- ✅ BEEP = Dieses Pad führt zum Reset-Pin!

