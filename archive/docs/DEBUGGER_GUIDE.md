# 🔧 DEBUGGER AUF PI EINRICHTEN - ANLEITUNG

**Datum:** 2025-12-07  
**Zweck:** Debugger direkt auf dem Raspberry Pi nutzen

---

## 🎯 PROBLEM

**Situation:**
- Debugger auf Mac, aber Pi läuft
- Verbindung über Mac ist nicht zielgerichtet
- **Lösung:** Debugger direkt auf dem Pi nutzen

---

## ✅ LÖSUNG: DEBUGGER AUF PI

### **Schritt 1: Debug-Tools installieren**

Führe das Setup-Script aus:
```bash
./SETUP_PI_DEBUGGER.sh
```

**Oder manuell:**
```bash
ssh andre@GhettoBlaster.local
sudo apt-get update
sudo apt-get install -y gdb strace valgrind perf htop
```

---

## 🔧 VERFÜGBARE DEBUG-TOOLS

### **1. GDB (GNU Debugger)**
- **Zweck:** Programm-Debugging
- **Verwendung:**
  ```bash
  gdb <programm>
  # oder für laufende Prozesse:
  sudo gdb -p <PID>
  ```

### **2. strace (System Call Tracer)**
- **Zweck:** System-Calls verfolgen
- **Verwendung:**
  ```bash
  strace <programm>
  # oder für laufende Prozesse:
  sudo strace -p <PID>
  ```

### **3. valgrind (Memory Debugger)**
- **Zweck:** Speicher-Fehler finden
- **Verwendung:**
  ```bash
  valgrind <programm>
  ```

### **4. perf (Performance Profiler)**
- **Zweck:** Performance-Analyse
- **Verwendung:**
  ```bash
  perf record <programm>
  perf report
  ```

### **5. htop (Process Monitor)**
- **Zweck:** Prozesse überwachen
- **Verwendung:**
  ```bash
  htop
  ```

---

## 📋 DEBUG-HELPER-SCRIPT

Nach der Installation ist ein Debug-Helper verfügbar:

```bash
source ~/debug/debug-services.sh
```

**Verfügbare Befehle:**
- `debug-service <service>` - Debug Service mit gdb
- `trace-service <service>` - Trace Service mit strace
- `monitor-service <service>` - Monitor Service mit htop

**Beispiele:**
```bash
debug-service localdisplay.service
trace-service localdisplay.service
monitor-service localdisplay.service
```

---

## 🎯 PRAKTISCHE BEISPIELE

### **1. Service debuggen:**
```bash
ssh andre@GhettoBlaster.local
source ~/debug/debug-services.sh
debug-service localdisplay.service
```

### **2. System-Calls verfolgen:**
```bash
ssh andre@GhettoBlaster.local
source ~/debug/debug-services.sh
trace-service localdisplay.service
```

### **3. Prozess überwachen:**
```bash
ssh andre@GhettoBlaster.local
source ~/debug/debug-services.sh
monitor-service localdisplay.service
```

### **4. Chromium debuggen:**
```bash
ssh andre@GhettoBlaster.local
PID=$(pgrep chromium)
sudo gdb -p $PID
```

### **5. Logs analysieren:**
```bash
ssh andre@GhettoBlaster.local
journalctl -u localdisplay.service -f
journalctl -u localdisplay.service --since "1 hour ago"
```

---

## 🔍 TROUBLESHOOTING

### **SSH-Verbindung fehlgeschlagen:**
```bash
# Prüfe IP-Adresse
ping GhettoBlaster.local

# Prüfe SSH
ssh -v andre@GhettoBlaster.local
```

### **Service nicht gefunden:**
```bash
# Liste alle Services
systemctl list-units --type=service

# Prüfe Service-Status
systemctl status <service>
```

### **Permission Denied:**
```bash
# Prüfe sudo-Rechte
sudo -l

# Prüfe User-Gruppen
groups
```

---

## 📚 WEITERE RESSOURCEN

### **GDB Cheat Sheet:**
- `break <function>` - Breakpoint setzen
- `run` - Programm starten
- `continue` - Weiterlaufen
- `step` - Einzelschritt
- `print <variable>` - Variable anzeigen
- `backtrace` - Stack-Trace anzeigen

### **strace Cheat Sheet:**
- `-p <PID>` - An laufenden Prozess anhängen
- `-f` - Forked Prozesse verfolgen
- `-e trace=all` - Alle System-Calls
- `-e trace=open,read,write` - Spezifische Calls

---

**Status:** ✅ ANLEITUNG ERSTELLT  
**Bereit für direktes Debugging auf dem Pi**

