# LÖTVERBINDUNG PRÜFEN

## AKTUELLER STATUS:
- ✅ GPIO 14 Overlay aktiviert
- ✅ Overlay konfiguriert GPIO 14 als Reset-Pin
- ❌ Reset schlägt immer noch fehl (-110 Timeout)

## GELÖTET:
- Raspberry Pi Pin 8 (GPIO 14) → **Mittleres der 3 Lötpinlöcher**

## PRÜFUNG MIT MULTIMETER:

### SCHRITT 1: Raspberry Pi Pin 8 → Gelötetes Loch
- Multimeter auf Durchgangsprüfung
- Spitze 1: Raspberry Pi Pin 8 (GPIO 14)
- Spitze 2: Gelötetes Loch (mittleres)
- **Erwartung: BEEP ✅** (Durchgang vorhanden)

### SCHRITT 2: Gelötetes Loch → PCM5122 Reset-Pin
- Multimeter auf Durchgangsprüfung
- Spitze 1: Gelötetes Loch (mittleres)
- Spitze 2: PCM5122 Pin 8 (Reset-Pin)
- **Erwartung: BEEP ✅** (Durchgang vorhanden)

## FALLS KEIN DURCHGANG ZU PCM5122:
❌ **Das mittlere Loch führt NICHT zum Reset-Pin!**

**LÖSUNG:**
1. Andere Löcher prüfen:
   - K1 (oben rechts, quadratisch)
   - Oberes runde Pad (unter C61)
   - Unteres runde Pad (unter C62)
2. Jedes Loch einzeln prüfen: Durchgang zu PCM5122 Pin 8?
3. Das Loch mit Durchgang löten

## FALLS DURCHGANG VORHANDEN:
✅ **Verbindung ist korrekt**

**MÖGLICHE PROBLEME:**
1. **Kalte Lötstelle** - neu löten
2. **Kabelbruch** - Kabel prüfen
3. **Lötzinn-Brücke** - andere Pins berührt?
4. **Timing-Problem** - Overlay-Reset-Sequenz zu schnell?

## ALTERNATIVE: DIREKT ZUM CHIP
Falls kein Loch zum Reset-Pin führt:
- Direkt zum PCM5122 Pin 8 (Reset-Pin) löten
- Sehr vorsichtig, dünnes Kabel (30 AWG)

