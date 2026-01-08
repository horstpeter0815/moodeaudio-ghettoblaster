# 🔬 SYSTEMATISCHER TOUCHSCREEN-TEST

**Datum:** 2025-12-01  
**Ziel:** Touchscreen-Matrix Schritt für Schritt optimieren

---

## 📋 TEST-PLAN

### Phase 1: Basis-Test (Aktuelle Konfiguration)
**Matrix:** `0 -1 1 -1 0 1 0 0 1` (X/Y vertauscht, beide invertiert)

**Tests:**
1. **Tippen-Test:**
   - Tippe auf die linke obere Ecke → Wo erscheint der Cursor?
   - Tippe auf die rechte obere Ecke → Wo erscheint der Cursor?
   - Tippe auf die linke untere Ecke → Wo erscheint der Cursor?
   - Tippe auf die rechte untere Ecke → Wo erscheint der Cursor?
   - Tippe in die Mitte → Wo erscheint der Cursor?

2. **Wischen-Test:**
   - Wische von links nach rechts → Was passiert? (horizontal/vertikal scrollen?)
   - Wische von rechts nach links → Was passiert?
   - Wische von oben nach unten → Was passiert?
   - Wische von unten nach oben → Was passiert?

3. **Offset-Messung:**
   - Tippe auf einen bekannten Punkt (z.B. Button)
   - Miss den Abstand zwischen Finger und Cursor
   - Richtung des Offsets (links/rechts/oben/unten)

---

### Phase 2: Matrix-Varianten testen

**Variante A: Nur Y invertiert (Basis)**
- Matrix: `1 0 0 0 -1 1 0 0 1`
- Test: Tippen und Wischen

**Variante B: X/Y vertauscht, nur Y invertiert**
- Matrix: `0 1 0 -1 0 1 0 0 1`
- Test: Tippen und Wischen

**Variante C: X/Y vertauscht, beide invertiert (aktuell)**
- Matrix: `0 -1 1 -1 0 1 0 0 1`
- Test: Tippen und Wischen

**Variante D: Beide invertiert, nicht vertauscht**
- Matrix: `-1 0 1 0 -1 1 0 0 1`
- Test: Tippen und Wischen

---

### Phase 3: Offset-Korrektur

**Wenn Richtung stimmt, aber Offset vorhanden:**
- X-Offset: Anpassen der 3. Spalte (z.B. `0 -1 1.05` für X-Offset)
- Y-Offset: Anpassen der 6. Spalte (z.B. `-1 0 1.05` für Y-Offset)
- Skalierung: Anpassen der 1. und 5. Spalte (z.B. `0.95 -1` für Verkleinerung)

---

## 🎯 TEST-ABLAUF

1. **Aktuelle Konfiguration testen**
2. **Ergebnisse dokumentieren**
3. **Nächste Variante testen**
4. **Beste Variante identifizieren**
5. **Offset korrigieren**
6. **Finale Konfiguration speichern**

---

## 📝 ERGEBNISSE

**Phase 1 - Aktuelle Konfiguration:**
- Matrix: `0 -1 1 -1 0 1 0 0 1`
- Tippen: [ ] Korrekt / [ ] Offset vorhanden
- Wischen: [ ] Korrekt / [ ] Falsche Richtung
- Offset: [ ] Kein Offset / [ ] X-Offset: ___ cm / [ ] Y-Offset: ___ cm

