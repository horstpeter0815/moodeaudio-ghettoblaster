# PCM5122 (U9) MESSUNG - BASIEREND AUF BILD

## AUF DEM BILD SICHTBAR:

### PCM5122 CHIP (U9):
- **Position**: Links im Bild
- **Markierung**: "PCM5122", "OCTC4", "CCOR", "BB" Logo
- **Pins**: Sichtbar entlang der rechten Kante des Chips
- **Pin 1**: Ecke mit Markierung (normalerweise oben links)
- **Pin 8 (Reset-Pin)**: Letzter Pin in der ersten Reihe (oben rechts)

### 3 GOLDENE PADS (K1 BEREICH):
- **Position**: Rechts im Bild, bei "K1" Markierung
- **1. Quadratisches Pad** (oben): Einzelnes quadratisches Pad mit Loch
- **2. Oberes runde Pad** (Mitte): Runde Pad mit Loch
- **3. Unteres runde Pad** (unten): Runde Pad mit Loch

### KOMPONENTEN IN DER NÄHE:
- **C61, C62**: Kondensatoren oberhalb der runden Pads
- **C60**: Kondensator rechts neben U9
- **R37, R36**: Widerstände oberhalb von C60

---

## MULTIMETER-MESSUNG - SCHRITT FÜR SCHRITT:

### SCHRITT 1: PCM5122 Pin 8 (Reset-Pin) IDENTIFIZIEREN
```
1. Finde U9 Chip (links im Bild)
2. Finde Pin 1 (Ecke mit Markierung - oben links)
3. Zähle im Uhrzeigersinn: Pin 1, 2, 3, 4, 5, 6, 7, 8
4. Pin 8 = Reset-Pin (RST) - oben rechts, letzter Pin in der ersten Reihe
```

### SCHRITT 2: Prüfe JEDES der 3 goldenen Pads
```
Für jedes Pad (quadratisch, oberes rund, unteres rund):
  
  Multimeter: Durchgangsprüfung (Beep-Modus)
  Spitze 1: PCM5122 Pin 8 (Reset-Pin) - vorsichtig am Pin berühren
  Spitze 2: Eines der 3 goldenen Pads
  
  ✅ BEEP = Dieses Pad führt zum Reset-Pin!
  ❌ Kein BEEP = Dieses Pad führt NICHT zum Reset-Pin
```

### SCHRITT 3: Raspberry Pi Pin 8 → Gelötetes Pad
```
Multimeter: Durchgangsprüfung
Spitze 1: Raspberry Pi Pin 8 (GPIO 14)
Spitze 2: Gelötetes Pad (eines der 3)
Erwartung: ✅ BEEP (Durchgang vorhanden)
```

---

## WICHTIGE HINWEISE:

### PCM5122 PIN 8 FINDEN:
- **Chip**: U9, links im Bild
- **Pin 1**: Ecke mit Markierung (Punkt/Kerbe) - oben links
- **Pin 8**: Im Uhrzeigersinn von Pin 1, letzter Pin in der ersten Reihe
- **Position**: Oben rechts am Chip

### GOLDENE PADS:
- **Quadratisches Pad**: Oben bei K1
- **Oberes runde Pad**: Mitte, unter dem quadratischen
- **Unteres runde Pad**: Unten, unter dem oberen runden

### MESSUNG:
- **Vorsichtig**: PCM5122 Pins sind sehr klein und dicht beieinander
- **Präzise**: Stelle sicher, dass du wirklich Pin 8 triffst
- **Systematisch**: Prüfe jedes der 3 Pads einzeln

---

## ERGEBNIS:

Nach der Messung solltest du wissen:
- ✅ Welches der 3 Pads zum Reset-Pin führt
- ✅ Ob das gelötete Pad das richtige ist
- ✅ Ob die Lötverbindung korrekt ist

