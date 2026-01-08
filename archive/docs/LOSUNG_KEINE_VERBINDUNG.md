# LÖSUNG: KEINE VERBINDUNG ZU DEN 3 PADS

## PROBLEM:
- ❌ Keines der 3 goldenen Pads hat Durchgang zu PCM5122 Pin 8
- ❌ Die Pads führen NICHT zum Reset-Pin

## MÖGLICHE LÖSUNGEN:

### OPTION 1: DIREKT ZUM CHIP-PIN LÖTEN
```
1. PCM5122 Pin 8 (Reset-Pin) direkt am Chip finden
2. Sehr dünnes Kabel (30 AWG) verwenden
3. Vorsichtig direkt zum Pin 8 löten
4. Andere Pins nicht berühren!
```

### OPTION 2: ANDERE TESTPUNKTE SUCHEN
```
1. Auf dem Board nach anderen Testpunkten suchen
2. Rückseite des Boards prüfen
3. Vias (Durchkontaktierungen) prüfen
```

### OPTION 3: PIN 8 VERIFIZIEREN
```
1. Prüfe, ob Pin 8 wirklich der Reset-Pin ist
2. PCM5122 Datenblatt konsultieren
3. Alternative: Pin 4 könnte Reset-Pin sein?
```

### OPTION 4: ANDEREN GPIO-PIN VERWENDEN
```
1. GPIO 18, 23, 24, 25 verwenden (statt GPIO 14)
2. Neues Overlay erstellen
3. Neuen Pin löten
```

---

## EMPFEHLUNG:
**Direkt zum PCM5122 Pin 8 löten** - das ist die sicherste Methode.

