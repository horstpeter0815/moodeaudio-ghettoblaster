# HiFiBerry AMP100 auf Pi 5 - Status Zusammenfassung

**Datum:** 1. Dezember 2025  
**Status:** ⚠️ **PCM5122 auf falschem I2C Bus**

---

## ✅ ERREICHT

1. **i2c1 Alias erstellt:**
   - Custom Overlay `i2c1-alias.dtbo` erstellt
   - `i2c1` zeigt jetzt auf `/soc@107c000000/i2c@7d005600` (i2c_arm)
   - In `config.txt` aktiviert

2. **PCM5122 wird erkannt:**
   - `pcm512x 13-004d: Failed to reset device: -11`
   - Hardware ist vorhanden und antwortet

3. **Konfiguration gesetzt:**
   ```ini
   dtoverlay=i2c1-alias
   dtoverlay=hifiberry-amp100
   dtparam=i2c_arm=on
   dtparam=i2s=on
   force_eeprom_read=0
   ```

---

## ❌ PROBLEM

**PCM5122 ist auf I2C Bus 13, nicht Bus 1:**
- **Bus 1 (i2c_arm):** Leer - kein PCM5122
- **Bus 13 (RP1 Controller):** PCM5122 bei 0x4d gefunden
- **Overlay erwartet:** PCM5122 auf Bus 1
- **Ergebnis:** Overlay kann nicht geladen werden

---

## 🔧 LÖSUNGSOPTIONEN

### Option 1: Hardware prüfen (EMPFOHLEN)
- HAT richtig auf GPIO-Header stecken
- Sicherstellen, dass SDA/SCL auf GPIO 2/3 sind
- Prüfen ob Pi 5 Adapter benötigt wird

### Option 2: Custom Overlay für Bus 13
Erstelle angepasstes Overlay, das Bus 13 verwendet:
- Kopiere `hifiberry-amp100.dts`
- Ändere I2C Bus Referenz von `i2c1` zu Bus 13
- Kompiliere und teste

### Option 3: I2C Bus Mapping ändern
Konfiguriere System so, dass `i2c_arm` auf Bus 13 zeigt (falls möglich).

---

## 📋 NÄCHSTE SCHRITTE

**Was möchtest du tun?**
1. Hardware-Verbindung prüfen lassen?
2. Custom Overlay für Bus 13 erstellen?
3. Weitere Diagnose durchführen?

---

**Status:** ⚠️ **WARTE AUF ENTSCHEIDUNG**


