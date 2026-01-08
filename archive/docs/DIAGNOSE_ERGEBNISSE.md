# HiFiBerry AMP100 auf Pi 5 - Diagnose Ergebnisse

**Datum:** 1. Dezember 2025  
**Status:** 🔴 **KRITISCHES PROBLEM IDENTIFIZIERT**

---

## 🔴 HAUPTPROBLEM

**I2C Bus 1 existiert NICHT auf Raspberry Pi 5!**

### Details:
- **i2c1 Alias zeigt auf:** `/soc@107c000000/i2c@7d005600` (i2c_arm)
- **Aber `/dev/i2c-1` existiert NICHT**
- **Verfügbare Busse:** 13, 14, 15
- **PCM5122 ist auf Bus 13** registriert (`/axi/pcie@1000120000/rp1/i2c@74000`)

---

## 📊 DIAGNOSE ERGEBNISSE

### 1. I2C Bus Übersicht
```
i2c-13: Synopsys DesignWare I2C adapter (RP1 Controller)
i2c-14: 107d508200.i2c
i2c-15: 107d508280.i2c
```

### 2. PCM5122 Status
- ✅ **Registriert auf Bus 13** als `13-004d`
- ✅ **Hardware erkannt** (`/sys/bus/i2c/devices/13-004d`)
- ❌ **Overlay kann nicht geladen werden** (sucht Bus 1)

### 3. Overlay Analyse
Das `hifiberry-amp100` Overlay:
- **Fragment 2** sucht nach `i2c1` (sollte Bus 1 sein)
- **Fragment 2** fügt `pcm5122@4d` hinzu
- **Problem:** `i2c1` existiert nicht als `/dev/i2c-1`

### 4. I2C Arbitration Fehler
```
i2c_designware 1f00074000.i2c: lost arbitration
```
- Mehrere Geräte versuchen gleichzeitig zu kommunizieren
- Bus 13 hat Konflikte

### 5. Bus 14/15 Anomalie
- Bus 14/15 zeigen **viele Geräte** (40-4f)
- Könnte i2c_arm sein, aber unklar
- **NICHT** der richtige Bus für PCM5122

---

## 🔧 LÖSUNGSANSÄTZE

### Option A: Custom Overlay für Bus 13 (EMPFOHLEN)
Erstelle angepasstes Overlay, das direkt Bus 13 verwendet:
1. Kopiere `hifiberry-amp100.dts`
2. Ändere `target = <&i2c1>` zu `target = <&i2c13>` oder direktem Pfad
3. Kompiliere zu `.dtbo`
4. Teste

### Option B: i2c_arm richtig mappen
- Prüfe warum i2c_arm nicht als Bus 1 erscheint
- Möglicherweise ist i2c_arm Bus 14 oder 15?
- Dann Overlay so anpassen, dass es den richtigen Bus findet

### Option C: Hardware prüfen
- **GPIO Pins 2/3** sollten auf i2c_arm sein
- Prüfe ob HAT richtig aufsteckt
- Prüfe ob Pi 5 Adapter benötigt wird

---

## 📋 NÄCHSTE SCHRITTE

**Empfehlung:** Option A - Custom Overlay für Bus 13 erstellen

**Warum?**
- PCM5122 ist bereits auf Bus 13 registriert
- Hardware funktioniert (wird erkannt)
- Nur Software-Mapping muss angepasst werden

---

**Status:** ⚠️ **BEREIT FÜR LÖSUNG**

