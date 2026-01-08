# TOUCHSCREEN TROUBLESHOOTING

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Problem:** Touchscreen funktioniert nicht

---

## ❌ PROBLEM

**Touchscreen wird nicht erkannt:**
- ❌ Nicht in `lsusb`
- ❌ Nicht in `/proc/bus/input/devices`
- ❌ Nicht in `libinput list-devices`

---

## 🔍 DIAGNOSE

### **Aktueller Status:**
- ✅ Display: Funktioniert (HDMI)
- ✅ Audio: Funktioniert
- ✅ Volume: 0% (stabil)
- ❌ **Touchscreen: NICHT ERKANNT**

### **Mögliche Ursachen:**
1. **USB-Kabel nicht angeschlossen**
2. **Touchscreen nicht eingeschaltet**
3. **USB-Kabel defekt**
4. **Touchscreen am falschen USB-Port**
5. **USB-Hub Problem**

---

## 🔧 LÖSUNGSSCHRITTE

### **SCHRITT 1: USB-KABEL PRÜFEN**

**Prüfen:**
1. Ist USB-Kabel vom Display zum Pi angeschlossen?
2. Welcher USB-Port wird verwendet?
3. Ist USB-Kabel fest angeschlossen?

**Test:**
```bash
# USB-Kabel abziehen
# USB-Kabel neu anschließen
# dmesg beobachten
dmesg -w
```

**Erwartete Meldung beim Anschließen:**
```
[  XXX.XXX] usb 1-X: New USB device found, idVendor=0712, idProduct=000a
[  XXX.XXX] usb 1-X: Product: WaveShare
[  XXX.XXX] usb 1-X: Manufacturer: WaveShare
[  XXX.XXX] input: WaveShare WaveShare as /dev/input/inputX
[  XXX.XXX] hid-multitouch 0003:0712:000A.XXXX: input,hiddevXX,hidrawX: USB HID v1.11 Device [WaveShare WaveShare]
```

---

### **SCHRITT 2: TOUCHSCREEN ERKENNUNG PRÜFEN**

**Nach Anschließen prüfen:**
```bash
# USB-Device
lsusb | grep -i waveshare

# Input Device
cat /proc/bus/input/devices | grep -i waveshare

# libinput
libinput list-devices | grep -i waveshare

# Event Device
ls -la /dev/input/event* | tail -1
```

**Erfolg:**
- ✅ USB-Device: `Bus 001 Device XXX: ID 0712:000a WaveShare`
- ✅ Input Device: `WaveShare WaveShare`
- ✅ Event Device: `/dev/input/eventX`
- ✅ libinput: Touchscreen erkannt

---

### **SCHRITT 3: FALLS ERKANNT, ABER NICHT FUNKTIONIERT**

**1. Weston neu starten:**
```bash
systemctl restart weston.service
```

**2. Touchscreen-Events testen:**
```bash
# Event-Device finden
cat /proc/bus/input/devices | grep -A 5 'WaveShare'

# Events testen (berühre Touchscreen)
hexdump -C /dev/input/eventX
```

**3. libinput Calibration:**
```bash
# Touchscreen in libinput prüfen
libinput list-devices | grep -A 15 'WaveShare'

# Falls Calibration nötig:
# Weston sollte automatisch kalibrieren
# Falls nicht: manuelle Calibration nötig
```

---

### **SCHRITT 4: WESTON KONFIGURATION**

**weston.ini erweitert:**
```ini
[input]
# Touchscreen-Konfiguration
# Touchscreen wird automatisch von libinput erkannt
```

**Weston neu starten:**
```bash
systemctl restart weston.service
```

---

### **SCHRITT 5: FALLS IMMER NOCH NICHT FUNKTIONIERT**

**Hardware-Tests:**
1. **USB-Kabel testen:**
   - Anderes USB-Kabel verwenden
   - Kabel auf Defekte prüfen

2. **USB-Port testen:**
   - Touchscreen am anderen USB-Port testen
   - Direkt am Pi (nicht am Hub) testen

3. **Touchscreen testen:**
   - Touchscreen am anderen Gerät testen
   - Funktioniert Touchscreen dort?

4. **USB-Hub prüfen:**
   - Falls am Hub: Direkt am Pi testen
   - Hub möglicherweise defekt

---

## 📊 ERWARTETE ERKENNTNISSE

### **Wenn Touchscreen angeschlossen ist:**
```
# lsusb:
Bus 001 Device XXX: ID 0712:000a WaveShare WaveShare

# /proc/bus/input/devices:
I: Bus=0003 Vendor=0712 Product=000a
N: Name="WaveShare WaveShare"
H: Handlers=eventX
B: EV=b
B: ABS=...

# libinput:
Device:           WaveShare WaveShare
Kernel:           /dev/input/eventX
Capabilities:     touch
```

---

## 🎯 AKTUELLER STATUS

**Touchscreen:**
- ❌ **NICHT ERKANNT** - USB-Device nicht sichtbar
- ⏳ **LÖSUNG:** USB-Kabel prüfen und anschließen

**System:**
- ✅ Display: Funktioniert
- ✅ Audio: Funktioniert
- ✅ Volume: 0% (stabil)
- ❌ Touchscreen: Benötigt USB-Kabel

---

## 📝 NÄCHSTE SCHRITTE

1. **USB-Kabel prüfen:**
   - Ist Kabel angeschlossen?
   - Kabel abziehen und neu anschließen
   - `dmesg -w` beobachten

2. **Touchscreen erkannt?**
   - `lsusb | grep waveshare`
   - Falls ja: Weston neu starten
   - Falls nein: Hardware-Problem

3. **Falls erkannt, aber nicht funktioniert:**
   - Events testen
   - Calibration prüfen
   - Weston-Konfiguration prüfen

---

**Status:** ⏳ Touchscreen benötigt USB-Kabel-Anschluss  
**Nächster Schritt:** USB-Kabel prüfen und anschließen

