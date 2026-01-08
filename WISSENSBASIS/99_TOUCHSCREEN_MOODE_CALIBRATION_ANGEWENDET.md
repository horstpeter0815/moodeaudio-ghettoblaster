# TOUCHSCREEN MOODE CALIBRATION ANGEWENDET

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Status:** ✅ **MOODE CALIBRATION ANGEWENDET**

---

## 🎯 MOODE CALIBRATION-DATEN GEFUNDEN

### **moOde Calibration-Matrix für 270°:**
```
0 -1 1 1 0 0 0 0 1
```

**Quelle:** `moode-source/www/inc/constants.php`
```php
'270' => '0 -1 1 1 0 0 0 0 1'
```

### **libinput Calibration-Matrix Format:**
Für 270° Rotation:
```
0 1 0 -1 0 1
```

---

## 🔧 DURCHGEFÜHRTE MASSNAHMEN

### **1. udev-Regel erstellt:**
```bash
/etc/udev/rules.d/99-waveshare-touchscreen-calibration.rules
```

**Inhalt:**
```
# WaveShare Touchscreen Calibration für 270° Rotation
# Basierend auf moOde Calibration: 0 -1 1 1 0 0 0 0 1
# libinput Format: 0 1 0 -1 0 1 (für 270°)
ENV{ID_INPUT_TOUCHSCREEN}=="1", ENV{ID_VENDOR_ID}=="0712", ENV{ID_MODEL_ID}=="000a", ENV{LIBINPUT_CALIBRATION_MATRIX}="0 1 0 -1 0 1"
```

### **2. udev-Regeln neu geladen:**
```bash
udevadm control --reload-rules
udevadm trigger
```

### **3. Weston neu gestartet:**
```bash
systemctl restart weston.service
```

---

## 📝 CALIBRATION-DETAILS

### **moOde (X11 Format):**
- **270°:** `0 -1 1 1 0 0 0 0 1`
- **Verwendung:** X11 CalibrationMatrix
- **Datei:** `/usr/share/X11/xorg.conf.d/40-libinput.conf`

### **libinput (Weston Format):**
- **270°:** `0 1 0 -1 0 1`
- **Verwendung:** LIBINPUT_CALIBRATION_MATRIX (udev)
- **Datei:** `/etc/udev/rules.d/99-waveshare-touchscreen-calibration.rules`

### **Konvertierung:**
- X11 Matrix: `0 -1 1 1 0 0 0 0 1`
- libinput Matrix: `0 1 0 -1 0 1`
- Entspricht 270° Rotation

---

## ✅ ERWARTETES ERGEBNIS

### **Touchscreen sollte jetzt funktionieren:**
- ✅ Calibration basierend auf moOde-Daten
- ✅ 270° Rotation korrekt kalibriert
- ✅ udev-Regel angewendet
- ✅ Weston neu gestartet

---

## ⚠️ HINWEISE

### **Falls Touchscreen immer noch nicht funktioniert:**
1. **System neu starten:**
   ```bash
   reboot
   ```
   - udev-Regel wird beim Boot angewendet

2. **Calibration prüfen:**
   ```bash
   libinput list-devices | grep -A 20 'WaveShare'
   ```

3. **Events testen:**
   ```bash
   hexdump -C /dev/input/event0
   ```

---

## 🎯 ZUSAMMENFASSUNG

### **✅ DURCHGEFÜHRT:**
1. ✅ moOde Calibration-Daten gefunden
2. ✅ udev-Regel erstellt (libinput Format)
3. ✅ udev-Regeln neu geladen
4. ✅ Weston neu gestartet

### **⏳ NÄCHSTER SCHRITT:**
- Touchscreen sollte jetzt funktionieren
- Falls nicht: System neu starten

---

**Status:** ✅ **MOODE CALIBRATION ANGEWENDET - TOUCHSCREEN SOLLTE FUNKTIONIEREN!**

