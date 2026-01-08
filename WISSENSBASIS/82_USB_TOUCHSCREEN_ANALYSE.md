# USB TOUCHSCREEN ANALYSE - WAVESHARE HDMI DISPLAY

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Erkenntnis:** Touchscreen ist USB-basiert, nicht I2C!

---

## 🔍 ERKENNTNIS

### **Touchscreen-Verbindung:**
- ✅ WaveShare HDMI Display ist über USB mit Touchscreen verbunden
- ❌ Touchscreen wird NICHT als USB-Device erkannt
- ❌ Kein Touchscreen-Device in `/proc/bus/input/devices`

---

## 📊 USB-DEVICES STATUS

### **Gefundene USB-Devices:**
1. **USB Hub** (2109:3431) - Bus 001 Device 002
2. **Compx 2.4G Receiver** (25a7:fa61) - Keyboard/Mouse
3. **Apple Magic Keyboard** (05ac:0267) - Keyboard
4. **USB Controllers** (1d6b:0002, 1d6b:0003) - Standard

### **❌ KEIN Touchscreen-Device gefunden!**

---

## 🔧 MÖGLICHE GRÜNDE

### **1. Touchscreen nicht angeschlossen:**
- USB-Kabel nicht verbunden
- USB-Kabel defekt
- Touchscreen nicht eingeschaltet

### **2. Touchscreen nicht erkannt:**
- Touchscreen sendet keine HID-Events
- Touchscreen benötigt speziellen Driver
- Touchscreen am USB-Hub, aber nicht erkannt

### **3. Touchscreen als anderes Device:**
- Touchscreen wird als anderes Device erkannt
- Touchscreen sendet Events, aber nicht als Touchscreen klassifiziert

---

## 🔍 PRÜFUNG DURCHGEFÜHRT

### **1. USB-Devices:**
```bash
lsusb
# Zeigt nur Keyboard/Mouse, kein Touchscreen
```

### **2. Input Devices:**
```bash
cat /proc/bus/input/devices
# Zeigt nur Keyboard/Mouse, kein Touchscreen
```

### **3. libinput:**
```bash
libinput list-devices
# Zeigt nur Keyboard/Mouse, kein Touchscreen
```

### **4. dmesg:**
```bash
dmesg | grep -i usb
# Zeigt nur Keyboard/Mouse USB-Devices
```

---

## 💡 LÖSUNGSANSÄTZE

### **1. Hardware prüfen:**
- ✅ Ist USB-Kabel angeschlossen?
- ✅ Ist Touchscreen eingeschaltet?
- ✅ Funktioniert USB-Kabel?

### **2. USB-Device identifizieren:**
```bash
# Alle USB-Devices auflisten
lsusb -v

# USB-Device beim Anschließen beobachten
dmesg -w
# Dann Touchscreen anschließen/abschließen
```

### **3. Touchscreen manuell testen:**
```bash
# Prüfe alle Input-Devices
cat /proc/bus/input/devices | grep -A 10 'ABS='

# Teste Events
hexdump -C /dev/input/eventX
# (X durch event-Nummer ersetzen)
```

### **4. Weston Input-Konfiguration:**
```ini
# /etc/xdg/weston/weston.ini
[input]
# Touchscreen sollte automatisch erkannt werden
# Falls nicht, möglicherweise Calibration nötig
```

---

## 📝 NÄCHSTE SCHRITTE

### **1. Hardware prüfen:**
- [ ] USB-Kabel prüfen
- [ ] Touchscreen anschließen/abschließen testen
- [ ] dmesg beim Anschließen beobachten

### **2. USB-Device identifizieren:**
- [ ] lsusb vor/nach Anschließen vergleichen
- [ ] USB-Device-ID notieren
- [ ] HID-Descriptor prüfen

### **3. Touchscreen konfigurieren:**
- [ ] Falls erkannt: Weston Calibration
- [ ] Falls nicht erkannt: Driver-Problem
- [ ] Falls als anderes Device: Re-Klassifizierung

---

## 🎯 ERWARTETE ERGEBNISSE

### **Wenn Touchscreen erkannt wird:**
```
# lsusb sollte zeigen:
Bus 001 Device XXX: ID XXXX:XXXX WaveShare Touchscreen

# /proc/bus/input/devices sollte zeigen:
I: Bus=0003 Vendor=XXXX Product=XXXX
N: Name="WaveShare Touchscreen"
H: Handlers=eventX
B: ABS=...
```

### **libinput sollte zeigen:**
```
Device:           WaveShare Touchscreen
Kernel:           /dev/input/eventX
Capabilities:     touch
```

---

## ⚠️ HINWEISE

**Weston/Wayland:**
- Weston verwendet libinput für Input-Devices
- Touchscreen sollte automatisch erkannt werden
- Falls erkannt: Calibration möglicherweise nötig

**USB HID:**
- Touchscreen sollte als HID (Human Interface Device) erkannt werden
- Sollte ABS (Absolute) Events senden
- Sollte als Touchscreen klassifiziert werden

---

**Status:** ⏳ Touchscreen wird nicht erkannt - Hardware-Prüfung nötig

