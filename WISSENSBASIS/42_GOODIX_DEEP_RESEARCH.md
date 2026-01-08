# GOODIX TOUCHSCREEN - TIEFE RECHERCHE

**Datum:** 02.12.2025  
**Hardware:** Goodix Touchscreen Controller (vermutlich GT911/GT9271)  
**Driver:** ws_touchscreen (WaveShare) / goodix_ts (Linux Kernel)

---

## HARDWARE-IDENTIFIZIERUNG

### **Goodix Chip:**
- **I2C Adresse:** 0x45
- **I2C Bus:** 10
- **Mögliche Modelle:**
  - GT911
  - GT9271
  - GT9286

### **Register:**
- **0x8140:** Chip ID / Reset Register
- **0x8144:** Firmware Version
- **0x8147:** Chip Type
- **0x8148:** Config Data

---

## ONLINE-RECHERCHE ERGEBNISSE

⏳ Recherche in Arbeit...

---

## BEKANNTE PROBLEME

### **1. I2C Write Error -5:**
- EIO (Input/Output Error)
- Remote I/O Error
- Hardware-Kommunikationsfehler

### **2. Driver-Kompatibilität:**
- ws_touchscreen vs goodix_ts
- Device Tree Overlay Konfiguration

### **3. Input Device nicht erstellt:**
- Driver lädt, aber erstellt kein Input Device
- Probe fehlgeschlagen

---

## LÖSUNGSANSÄTZE

### **1. Goodix Driver direkt verwenden:**
- Device Tree Overlay für Goodix
- Interrupt GPIO konfigurieren
- Reset GPIO konfigurieren

### **2. Hardware-Reset:**
- Goodix Reset Register
- GPIO Reset

### **3. I2C Kommunikation:**
- Register direkt lesen/schreiben
- Chip ID identifizieren

---

**Tiefe Recherche und Analyse in Arbeit...**

