# LÖTSTELLE: 3 LÖTPINLÖCHER PRÜFEN

## AUF DEM BILD SICHTBAR:

### 3 LÖTPINLÖCHER:

1. **K1 (oben rechts):**
   - Goldenes **quadratisches Pad** mit Loch
   - Markiert als "K1"
   - Position: Oben rechts im Bild, über den Kondensatoren

2. **Zwei goldene runde Pads (unter C61/C62):**
   - Zwei **runde Pads** mit Löchern
   - Vertikal angeordnet
   - Position: Unter den Kondensatoren C61 und C62
   - Zwischen dem PCM5122 Chip (U9) und den Kondensatoren

## PRÜFUNG MIT MULTIMETER:

### SCHRITTE:
1. **Multimeter auf Durchgangsprüfung stellen** (Beep-Modus)
2. **PCM5122 Pin 8 (Reset-Pin) identifizieren:**
   - Chip U9: "PCM5122" Text lesbar
   - Pin 8 = letzter Pin in der ersten Reihe (oben rechts)
3. **Jedes der 3 Löcher prüfen:**
   - Multimeter-Spitze 1: PCM5122 Pin 8
   - Multimeter-Spitze 2: Eines der 3 Löcher
   - **Beep = Durchgang gefunden!** ✅

### WELCHES LOCH IST ES?
- Das Loch mit **Durchgang zu Pin 8** = Reset-Pin Lötstelle
- Wahrscheinlich eines der beiden runden Pads unter C61/C62
- Oder K1 (wenn es ein Reset-Testpunkt ist)

## LÖTVERBINDUNG:

```
Raspberry Pi Pin 8 (GPIO 14)  ----->  [GEFUNDENES LOCH]  ----->  PCM5122 Pin 8 (RST)
```

## VORTEILE:
- ✅ **Viel einfacher zu löten** als direkt am Chip
- ✅ **Größere Lötfläche** (Loch/Pad)
- ✅ **Weniger Risiko**, andere Pins zu beschädigen
- ✅ **Stabilere Verbindung**

## NACH DER PRÜFUNG:
1. Das gefundene Loch markieren
2. Kabel von Raspberry Pi Pin 8 dorthin löten
3. Overlay aktivieren: `dtoverlay=hifiberry-amp100-pi5-gpio14`
4. Reboot

