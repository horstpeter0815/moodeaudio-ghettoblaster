# TOUCHSCREEN NACH KABELWECHSEL

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Aktion:** USB-Kabel gewechselt

---

## 🔍 PRÜFUNG NACH KABELWECHSEL

### **Erwartete Erkennung:**
```
# USB Device:
Bus 001 Device XXX: ID 0712:000a WaveShare WaveShare

# Input Device:
I: Bus=0003 Vendor=0712 Product=000a
N: Name="WaveShare WaveShare"
H: Handlers=eventX

# dmesg:
[  XXX.XXX] usb 1-X: New USB device found, idVendor=0712, idProduct=000a
[  XXX.XXX] usb 1-X: Product: WaveShare
[  XXX.XXX] input: WaveShare WaveShare as /dev/input/inputX
[  XXX.XXX] hid-multitouch 0003:0712:000A.XXXX: input,hiddevXX,hidrawX: USB HID v1.11 Device [WaveShare WaveShare]
```

---

## 🔧 WENN TOUCHSCREEN ERKANNT WIRD

### **1. Weston neu starten:**
```bash
systemctl restart weston.service
```

### **2. libinput prüfen:**
```bash
libinput list-devices | grep -A 15 'WaveShare'
```

### **3. Touchscreen testen:**
- Touchscreen in Wayland-Apps (cog Browser) berühren
- Sollte funktionieren

---

## ⚠️ WENN TOUCHSCREEN NICHT ERKANNT WIRD

### **Mögliche Probleme:**
1. **USB-Kabel:**
   - Kabel nicht fest angeschlossen
   - Kabel defekt
   - Falsches Kabel

2. **Touchscreen:**
   - Touchscreen nicht eingeschaltet
   - Touchscreen defekt

3. **USB-Port:**
   - Falscher USB-Port
   - USB-Port defekt

### **Troubleshooting:**
```bash
# dmesg beim Anschließen beobachten
dmesg -w

# USB-Devices prüfen
lsusb

# Input-Devices prüfen
cat /proc/bus/input/devices | grep -i waveshare
```

---

**Status:** ⏳ Prüfung läuft...

