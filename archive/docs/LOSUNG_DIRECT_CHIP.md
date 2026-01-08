# LÖSUNG: DIREKT ZUM CHIP-PIN 8 LÖTEN

## PROBLEM:
- ❌ Keines der 3 goldenen Pads hat Durchgang zu PCM5122 Pin 8
- ❌ Die Pads führen NICHT zum Reset-Pin
- ❌ Externe Lötpunkte können nicht verwendet werden

## LÖSUNG: DIREKT ZUM CHIP-PIN 8

### VORBEREITUNG:
1. **Sehr dünnes Kabel**: 30 AWG oder dünner
2. **Lötkolben**: Feine Spitze, ca. 300-350°C
3. **Flussmittel**: Für saubere Lötstelle
4. **Lupe**: Um Pin 8 genau zu sehen

### SCHRITTE:

#### 1. PCM5122 Pin 8 FINDEN:
```
- IC so drehen, dass "PCM5122" lesbar ist
- Circle ist unten links = Pin 1
- Pin 8 = Linke Seite, 8. Pin von unten
- Pin 8 ist zwischen Pin 7 und Pin 9
```

#### 2. LÖTEN:
```
1. Kabel vorbereiten (ca. 5-10cm, abisolieren)
2. Pin 8 vorsichtig mit Flussmittel behandeln
3. Kabel an Pin 8 anlöten (sehr schnell, 1-2 Sekunden)
4. Andere Pins NICHT berühren!
5. Kabel zum Raspberry Pi Pin 8 (GPIO 14) führen
```

#### 3. PRÜFUNG:
```
Multimeter: Durchgangsprüfung
Spitze 1: Raspberry Pi Pin 8
Spitze 2: Gelötetes Kabel am PCM5122 Pin 8
✅ BEEP = Verbindung OK!
```

---

## ALTERNATIVE: ANDERER GPIO-PIN

Falls direktes Löten zu schwierig ist:
- **GPIO 18** (Pin 12) verwenden
- **GPIO 23** (Pin 16) verwenden
- **GPIO 24** (Pin 18) verwenden
- Neues Overlay erstellen

---

## WICHTIG:
- **Sehr vorsichtig**: Pin 8 ist sehr klein
- **Nur Pin 8**: Andere Pins nicht berühren
- **Kurze Lötzeit**: 1-2 Sekunden max
- **Prüfung**: Nach dem Löten mit Multimeter prüfen

