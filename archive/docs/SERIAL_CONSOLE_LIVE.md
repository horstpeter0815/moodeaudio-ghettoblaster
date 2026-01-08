# 🔌 SERIAL CONSOLE - LIVE MONITORING

**Datum:** $(date '+%Y-%m-%d %H:%M:%S')

## ✅ SERIAL CONSOLE VERFÜGBAR

**Serial-Port:** `/dev/cu.usbmodem214302`  
**Baudrate:** 115200

## 🚀 DIREKTER ZUGRIFF

### **Mit screen (Empfohlen):**
```bash
screen /dev/cu.usbmodem214302 115200
```

**Befehle in screen:**
- `Ctrl+A` dann `K` dann `Y` - Beenden
- `Ctrl+A` dann `]` - Scroll-Modus

### **Mit cu:**
```bash
cu -l /dev/cu.usbmodem214302 -s 115200
```

**Befehle in cu:**
- `~.` - Beenden

## 📊 LIVE MONITORING

**Was Sie sehen:**
- Boot-Messages
- Kernel-Logs
- Service-Starts
- first-boot-setup Ausgabe
- Fehler (falls vorhanden)

## 💡 DIREKTES EINGREIFEN

**Über Serial Console können Sie:**
- Boot-Prozess live verfolgen
- Bei Problemen direkt eingreifen
- Commands ausführen
- Logs ansehen
- Services starten/stoppen

## 🔍 WAS ICH JETZT MACHE

1. ✅ Serial Console verbinden
2. ✅ Boot-Vorgang live verfolgen
3. ✅ Bei Problemen direkt eingreifen
4. ✅ Logs sammeln

**Ich habe jetzt direkten Zugriff über den Debugger!**

