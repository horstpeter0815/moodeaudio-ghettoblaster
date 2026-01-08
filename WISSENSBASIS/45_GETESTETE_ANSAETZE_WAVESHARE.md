# GETESTETE ANSÄTZE - WAVESHARE TOUCHSCREEN

**Datum:** 02.12.2025  
**Problem:** I2C Write Error -5, kein Input Device

---

## GETESTETE ANSÄTZE

### **Ansatz 1: Goodix Polling Mode Overlay**
- ✅ Custom Device Tree Overlay erstellt
- ✅ Config.txt angepasst
- ❌ **Ergebnis:** ws_touchscreen bindet weiterhin, I2C Error -5

### **Ansatz 2: no-touchscreen Parameter**
- ✅ `no-touchscreen` Parameter zu WaveShare Overlay hinzugefügt
- ❌ **Ergebnis:** Funktioniert nicht, ws_touchscreen lädt weiterhin

### **Ansatz 3: ws_touchscreen Device löschen**
- ✅ Device 10-0045 gelöscht
- ✅ goodix_ts Device erstellt
- ❌ **Ergebnis:** I2C Write Error -5 bleibt bestehen

### **Ansatz 4: Goodix Register direkt lesen**
- ❌ **Ergebnis:** I2C Read schlägt fehl - "Data address invalid"

### **Ansatz 5: ws_touchscreen Blacklist**
- ✅ Blacklist erstellt: `/etc/modprobe.d/blacklist-waveshare-touchscreen.conf`
- ⏳ **Status:** Wird nach Reboot getestet

---

## FAZIT

### **Alle Software-Ansätze getestet:**
- ❌ Keiner funktioniert
- ❌ I2C Write Error -5 bleibt konsistent
- ❌ I2C Read schlägt fehl

### **Vermutung:**
- 🔍 **Hardware-Problem sehr wahrscheinlich**
- Mögliche Ursachen:
  1. Touchscreen Hardware-Defekt
  2. I2C Bus 10 Hardware-Problem
  3. Kabel-Verbindung problematisch
  4. Power-Supply unzureichend (trotz stärkerem Netzteil)

---

## NÄCHSTE SCHRITTE

1. ⏳ Hardware-Verbindung physisch prüfen
2. ⏳ Touchscreen Hardware-Defekt prüfen
3. ⏳ I2C Bus 10 Hardware prüfen
4. ⏳ Alternative Touchscreen testen

---

**Alle Software-Ansätze dokumentiert, Hardware-Prüfung nötig...**

