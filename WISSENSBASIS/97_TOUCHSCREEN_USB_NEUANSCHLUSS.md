# TOUCHSCREEN USB NEUANSCHLUSS

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Aktion:** USB-Kabel neu angeschlossen, USB Autosuspend deaktiviert

---

## 🔧 DURCHGEFÜHRTE MASSNAHMEN

### **1. USB-Kabel neu angeschlossen:**
- USB-Kabel abgezogen
- 10 Sekunden gewartet
- USB-Kabel neu angeschlossen
- Touchscreen neu erkannt

### **2. Event-Device geändert:**
- **Vorher:** event6, mouse1
- **Jetzt:** event0, mouse0
- Touchscreen wurde neu initialisiert

### **3. USB Autosuspend deaktiviert:**
- `usbcore.autosuspend=-1` in `/boot/cmdline.txt` hinzugefügt
- Verhindert, dass USB-Devices automatisch inaktiviert werden
- Touchscreen bleibt aktiv

### **4. Weston neu gestartet:**
- Weston neu gestartet, damit neues Event-Device erkannt wird

---

## 📝 TOUCHSCREEN STATUS

### **✅ Neu erkannt:**
- USB Device: WaveShare (0712:000a) - Device 006
- Input Device: `/dev/input/input11` (vorher: input9)
- Event Device: `/dev/input/event0` (vorher: event6)
- Maus Device: `/dev/input/mouse0` (vorher: mouse1)
- HID Multitouch: `hid-multitouch 0003:0712:000A.0007`

### **✅ Konfiguration:**
- USB Autosuspend: Deaktiviert
- Weston: Neu gestartet
- Hardware-Rotation: Button gedrückt
- Display-Rotation: 270°

---

## 🔧 USB AUTOSUSPEND

### **Problem:**
- USB Autosuspend kann USB-Devices automatisch inaktivieren
- Touchscreen wird dann nicht mehr erkannt
- Events werden nicht mehr gesendet

### **Lösung:**
- `usbcore.autosuspend=-1` in `/boot/cmdline.txt`
- Deaktiviert USB Autosuspend
- Touchscreen bleibt aktiv

### **Hinweis:**
- Änderung wird erst nach Neustart wirksam
- System neu starten: `reboot`

---

## ✅ ERWARTETES ERGEBNIS

### **Touchscreen sollte jetzt funktionieren:**
- ✅ Touchscreen neu erkannt (event0)
- ✅ Weston neu gestartet
- ✅ USB Autosuspend deaktiviert
- ✅ Touchscreen bleibt aktiv

---

## ⚠️ HINWEISE

### **Falls Touchscreen immer noch nicht funktioniert:**
1. **System neu starten:**
   ```bash
   reboot
   ```
   - USB Autosuspend-Änderung wird wirksam

2. **Events testen:**
   ```bash
   hexdump -C /dev/input/event0
   ```

3. **Weston Log prüfen:**
   ```bash
   journalctl -u weston.service -f
   ```

---

## 🎯 ZUSAMMENFASSUNG

### **✅ DURCHGEFÜHRT:**
1. ✅ USB-Kabel neu angeschlossen
2. ✅ Touchscreen neu erkannt (event0)
3. ✅ USB Autosuspend deaktiviert
4. ✅ Weston neu gestartet

### **⏳ NÄCHSTER SCHRITT:**
- System neu starten (USB Autosuspend-Änderung)
- Touchscreen sollte dann funktionieren

---

**Status:** ✅ **USB NEUANSCHLUSS - SYSTEM NEU STARTEN EMPFOHLEN**

