# PCM5122 (U9) PIN-DIAGRAMM FÜR MULTIMETER-MESSUNG

## PCM5122 CHIP (U9) - QFN 32-PIN PACKAGE

### PIN-LAYOUT (LÄNGLICHES RECHTECK, PINS NUR LINKS/RECHTS):

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
- **IC ist länglich** (nicht quadratisch) ⚠️ KORRIGIERT!
- **Pins auf Längsseiten** (links und rechts) ⚠️ KORRIGIERT!
- **Pin 1**: Unten links (Circle/Markierung)
- **Pins 1-16**: Linke Seite (von unten nach oben)
- **Pins 17-32**: Rechte Seite (von oben nach unten)
- **Pin 8**: Reset-Pin (RST) - Linke Seite, 8. Pin von unten ⚠️ KORRIGIERT!

### RESET-PIN (RST):
- **Pin 8** = Reset-Pin (RST)
- **Polarität**: ACTIVE LOW
  - Reset = LOW (0V)
  - Normal = HIGH (3.3V)
- **Position**: Linke Seite, 8. Pin von unten (zwischen Pin 7 und Pin 9) ⚠️ KORRIGIERT!

---

## 3 LÖTPINLÖCHER AUF DEM AMP100 BOARD

### POSITION (relativ zum PCM5122 Chip):

```
                    [K1] ← Quadratisches Pad (oben rechts)
                     │
    ┌───────────────┼───────────────┐
    │               │               │
    │            [C61]              │
    │               │               │
    │            [C62]              │
    │               │               │
    │         [U9 PCM5122]          │
    │               │               │
    └───────────────┼───────────────┘
                    │
    [Oberes runde Pad] ← Zwischen C61/C62 und U9
    [Unteres runde Pad] ← Zwischen C61/C62 und U9
```

### LÖTPINLÖCHER:
1. **K1**: Quadratisches goldenes Pad (oben rechts)
2. **Oberes runde Pad**: Unter C61/C62, zwischen Kondensatoren und U9
3. **Unteres runde Pad**: Unter C61/C62, zwischen Kondensatoren und U9

---

## MULTIMETER-MESSUNG

### SCHRITT 1: Raspberry Pi Pin 8 → Gelötetes Loch
```
Multimeter: Durchgangsprüfung (Beep-Modus)
Spitze 1: Raspberry Pi Pin 8 (GPIO 14)
Spitze 2: Gelötetes Loch (mittleres)
Erwartung: ✅ BEEP (Durchgang vorhanden)
```

### SCHRITT 2: Gelötetes Loch → PCM5122 Pin 8 (RST)
```
Multimeter: Durchgangsprüfung (Beep-Modus)
Spitze 1: Gelötetes Loch (mittleres)
Spitze 2: PCM5122 Pin 8 (Reset-Pin)
Erwartung: ✅ BEEP (Durchgang vorhanden)
```

### SCHRITT 3: Alle 3 Löcher prüfen
```
Für jedes Loch (K1, oberes Pad, unteres Pad):
  Multimeter: Durchgangsprüfung
  Spitze 1: PCM5122 Pin 8 (Reset-Pin)
  Spitze 2: Eines der 3 Löcher
  ✅ BEEP = Dieses Loch führt zum Reset-Pin!
```

---

## RASPBERRY PI PIN 8 (GPIO 14)

### GPIO HEADER (von oben):
```
    3.3V  [1]  [2]  5V
   GPIO2  [3]  [4]  5V
   GPIO3  [5]  [6]  GND
   GPIO4  [7]  [8]  GPIO14 ← HIER LÖTEN!
     GND  [9] [10]  GPIO15
```

- **Pin 8** = GPIO 14
- **Position**: 4. Pin von oben, rechte Spalte

---

## ZUSAMMENFASSUNG

### ZU PRÜFEN:
1. ✅ Raspberry Pi Pin 8 → Gelötetes Loch (Durchgang?)
2. ✅ Gelötetes Loch → PCM5122 Pin 8 (Durchgang?)
3. ✅ Falls kein Durchgang: Andere Löcher prüfen

### WICHTIG:
- PCM5122 Pin 8 = Reset-Pin (RST)
- Reset ist ACTIVE LOW
- Pin-Nummerierung: Im Uhrzeigersinn von Pin 1 (Markierung)

