# 🔌 USB-DEBUGGER VERBINDUNG - ERKANNT!

**Datum:** 2025-12-08  
**Status:** ✅ USB-SERIAL-ADAPTER ERKANNT

---

## ✅ ERKANNTES GERÄT

**USB-Serial-Adapter:**
- `/dev/tty.usbmodem214302` (Terminal-Device)
- `/dev/cu.usbmodem214302` (Callout-Device - **VERWENDE DIESEN!**)

**Typ:** USB-Serial-Adapter (wahrscheinlich FTDI oder CH340)

---

## 🔧 VERBINDUNG ZUM RASPBERRY PI

### **1. Hardware-Verbindung**

**USB-Debugger → Raspberry Pi:**
- **GND** (Schwarz) → **GND** (Pin 6 oder 14)
- **TX** (Weiß/Grün) → **RX** (GPIO 15, Pin 10)
- **RX** (Grün/Weiß) → **TX** (GPIO 14, Pin 8)
- **VCC** (Rot) → **5V** (Pin 2) - **NUR WENN NÖTIG!**

**⚠️ WICHTIG:**
- VCC **NICHT** verbinden, wenn der Pi bereits mit Strom versorgt ist!
- Nur GND, TX, RX verbinden!

---

## 📋 SERIAL-KONSOLE VERBINDEN

### **Option 1: screen (macOS Standard)**
```bash
# Verbinde mit 115200 Baud (Standard für Raspberry Pi)
screen /dev/cu.usbmodem214302 115200

# Zum Beenden: Ctrl+A, dann K, dann Y
```

### **Option 2: minicom**
```bash
# Installiere minicom (falls nicht vorhanden)
brew install minicom

# Verbinde
minicom -D /dev/cu.usbmodem214302 -b 115200
```

### **Option 3: cu (macOS Standard)**
```bash
# Verbinde
cu -l /dev/cu.usbmodem214302 -s 115200

# Zum Beenden: ~.
```

---

## 🎯 RASPBERRY PI KONFIGURATION

### **1. Serial-Konsole aktivieren (auf dem Pi)**

**Via SSH oder Web-UI:**
```bash
# Boot-Partition beschreibbar machen
sudo mount -o remount,rw /boot

# config.txt bearbeiten
sudo nano /boot/config.txt

# Füge hinzu:
enable_uart=1
dtoverlay=uart0

# Speichere und starte neu
sudo reboot
```

### **2. Serial-Login aktivieren (optional)**
```bash
# Serial-Login aktivieren
sudo systemctl enable serial-getty@ttyAMA0.service
sudo systemctl start serial-getty@ttyAMA0.service
```

---

## 🔍 DEBUGGING MIT SERIAL-KONSOLE

### **1. Boot-Logs ansehen**
```bash
# Verbinde mit screen
screen /dev/cu.usbmodem214302 115200

# Warte auf Boot - du siehst alle Boot-Logs!
```

### **2. Serial-Konsole nutzen**
```bash
# Nach dem Boot kannst du dich einloggen:
# User: andre
# Password: 0815

# Dann normale Shell-Befehle ausführen
```

### **3. GDB über Serial (Remote Debugging)**
```bash
# Auf dem Pi: gdbserver starten
gdbserver /dev/ttyAMA0:115200 /path/to/program

# Auf dem Mac: GDB verbinden
gdb
(gdb) target remote /dev/cu.usbmodem214302
```

---

## 📊 VERFÜGBARE BEFEHLE

### **Serial-Konsole:**
- **screen:** `screen /dev/cu.usbmodem214302 115200`
- **minicom:** `minicom -D /dev/cu.usbmodem214302 -b 115200`
- **cu:** `cu -l /dev/cu.usbmodem214302 -s 115200`

### **Boot-Logs:**
- Alle Boot-Logs werden in Echtzeit angezeigt
- Siehst alle Kernel-Messages
- Siehst alle Systemd-Logs

### **Debugging:**
- Serial-Konsole für direkten Zugriff
- GDB über Serial für Remote-Debugging
- Boot-Probleme diagnostizieren

---

## 🎯 NÄCHSTE SCHRITTE

1. ✅ **USB-Debugger erkannt:** `/dev/cu.usbmodem214302`
2. ⏳ **Hardware verbinden:** GND, TX, RX zum Pi
3. ⏳ **Serial-Konsole aktivieren:** Auf dem Pi `enable_uart=1`
4. ⏳ **Verbinden:** `screen /dev/cu.usbmodem214302 115200`

---

## 🔧 TROUBLESHOOTING

### **Problem: Keine Ausgabe**
- Prüfe Hardware-Verbindung (GND, TX, RX)
- Prüfe Baudrate (115200)
- Prüfe ob `enable_uart=1` in config.txt

### **Problem: Falsche Zeichen**
- Baudrate prüfen (115200)
- TX/RX vertauscht? Tausche die Kabel

### **Problem: Kein Login**
- Serial-Login aktivieren: `systemctl enable serial-getty@ttyAMA0.service`

---

**Status:** ✅ USB-DEBUGGER ERKANNT - BEREIT FÜR VERBINDUNG


