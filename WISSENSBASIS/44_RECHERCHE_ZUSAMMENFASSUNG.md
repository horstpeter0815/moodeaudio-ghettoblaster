# ONLINE-RECHERCHE ZUSAMMENFASSUNG - WAVESHARE TOUCHSCREEN

**Datum:** 02.12.2025  
**Problem:** I2C Write Error -5, kein Input Device

---

## WICHTIGE ERKENNTNISSE AUS ONLINE-RECHERCHE

### **1. POLLING MODE ERFORDERLICH:**
- **WaveShare 7-inch Panels (GT911) haben KEINE Interrupt-Pins**
- Goodix Driver benötigt Polling Mode
- Patch verfügbar: https://lkml.org/lkml/2025/5/21/484
- `ws_touchscreen` Driver versucht Interrupt-Mode → schlägt fehl

### **2. DEVICE TREE OVERLAY:**
- Custom DTO für Goodix GT911 nötig
- Beispiel: https://forums.raspberrypi.com/viewtopic.php?t=380229
- Richtige I2C Adresse (0x45) und Bus (10) konfigurieren

### **3. DRIVER-KONFLIKTE:**
- `ws_touchscreen` (WaveShare) vs `goodix_ts` (Linux Kernel)
- Beide versuchen auf gleiches Device zuzugreifen
- `ws_touchscreen` muss deaktiviert werden, wenn `goodix_ts` verwendet wird

### **4. KERNEL-KOMPATIBILITÄT:**
- Bekannte Probleme mit neueren Kernels (Raspberry Pi 5)
- Kernel 6.12.47+rpt-rpi-v8 auf Pi 4 - Kompatibilität prüfen

### **5. I2C KOMMUNIKATION:**
- Error -5 = EIO (Input/Output Error)
- Kann Hardware-Problem sein (Kabel, Power)
- Kann Driver-Problem sein (Interrupt vs Polling)

---

## BEKANNTE LÖSUNGEN (AUS FOREN)

### **Lösung 1: Polling Mode Patch**
- Patch für Goodix Driver
- Ermöglicht Polling Mode ohne Interrupt-Pins
- Status: Patch verfügbar, muss angewendet werden

### **Lösung 2: Custom Device Tree Overlay**
- DTO ohne Interrupt-Pins
- Nur Polling Mode konfiguriert
- Status: Beispiel verfügbar

### **Lösung 3: ws_touchscreen deaktivieren**
- WaveShare Driver deaktivieren
- Nur goodix_ts verwenden
- Status: Zu testen

---

## NÄCHSTE SCHRITTE

1. ⏳ Polling Mode Patch prüfen/anwenden
2. ⏳ Custom DTO korrekt erstellen (I2C Bus 10, Adresse 0x45)
3. ⏳ ws_touchscreen deaktivieren
4. ⏳ goodix_ts mit Polling Mode testen

---

**Recherche abgeschlossen, systematische Umsetzung folgt...**

