# 🔌 DEBUGGER VERBINDEN - SCHRITT FÜR SCHRITT

**Datum:** 2025-12-07  
**Zweck:** Konkrete Anleitung zum Verbinden des Debuggers

---

## 🎯 SCHRITT 1: PI-VERBINDUNG PRÜFEN

### **1.1 Pi-Adresse finden:**
```bash
# Option 1: Hostname (falls funktioniert)
ping GhettoBlaster.local

# Option 2: Bekannte IP
ping 192.168.178.143

# Option 3: Netzwerk scannen
nmap -sn 192.168.178.0/24 | grep -B 2 "Raspberry"
```

### **1.2 SSH-Verbindung testen:**
```bash
# Test SSH-Verbindung
ssh andre@192.168.178.143
# Password: 0815

# Falls Hostname funktioniert:
ssh andre@GhettoBlaster.local
# Password: 0815
```

**✅ Wenn SSH funktioniert → Weiter zu Schritt 2**  
**❌ Wenn SSH nicht funktioniert → Siehe Troubleshooting unten**

---

## 🚀 SCHRITT 2: DEBUG-TOOLS INSTALLIEREN

### **2.1 Setup-Script ausführen:**
```bash
# Im Projekt-Verzeichnis
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

# Setup-Script ausführen
./SETUP_PI_DEBUGGER.sh

# Oder mit spezifischer IP:
./SETUP_PI_DEBUGGER.sh 192.168.178.143 andre
```

**Das Script:**
- Verbindet sich automatisch zum Pi
- Installiert alle Debug-Tools (gdb, strace, valgrind, etc.)
- Erstellt Debug-Helper-Scripts
- Konfiguriert alles automatisch

**✅ Wenn Installation erfolgreich → Weiter zu Schritt 3**

---

## 🔧 SCHRITT 3: DEBUGGER VERBINDEN

### **3.1 SSH zum Pi:**
```bash
ssh andre@192.168.178.143
# Password: 0815
```

### **3.2 Debug-Helper laden:**
```bash
# Debug-Helper aktivieren
source ~/debug/debug-services.sh
```

**✅ Jetzt sind Debug-Befehle verfügbar**

---

## 🎯 SCHRITT 4: DEBUGGER NUTZEN

### **4.1 Service debuggen (GDB):**
```bash
# Service mit GDB debuggen
debug-service localdisplay.service

# Oder manuell:
# 1. PID finden
PID=$(systemctl show -p MainPID --value localdisplay.service)

# 2. GDB starten
sudo gdb -p $PID
```

**GDB-Befehle:**
```
(gdb) break main          # Breakpoint setzen
(gdb) continue            # Weiterlaufen
(gdb) step               # Einzelschritt
(gdb) print variable      # Variable anzeigen
(gdb) backtrace           # Stack-Trace
(gdb) quit               # Beenden
```

### **4.2 System-Calls verfolgen (strace):**
```bash
# Service mit strace verfolgen
trace-service localdisplay.service

# Oder manuell:
PID=$(systemctl show -p MainPID --value localdisplay.service)
sudo strace -p $PID -f -e trace=all
```

### **4.3 Prozess überwachen (htop):**
```bash
# Service mit htop überwachen
monitor-service localdisplay.service

# Oder direkt:
htop
```

### **4.4 Chromium debuggen:**
```bash
# Chromium PID finden
PID=$(pgrep chromium)

# GDB starten
sudo gdb -p $PID

# Oder strace:
sudo strace -p $PID -f
```

---

## 📋 PRAKTISCHE BEISPIELE

### **Beispiel 1: localdisplay.service debuggen**
```bash
# SSH zum Pi
ssh andre@192.168.178.143

# Debug-Helper laden
source ~/debug/debug-services.sh

# Service debuggen
debug-service localdisplay.service
```

### **Beispiel 2: Chromium-Crash analysieren**
```bash
# SSH zum Pi
ssh andre@192.168.178.143

# Chromium PID finden
PID=$(pgrep chromium)

# Mit GDB verbinden
sudo gdb -p $PID

# In GDB:
(gdb) continue
(gdb) backtrace    # Wenn Crash
(gdb) info registers
(gdb) quit
```

### **Beispiel 3: System-Calls verfolgen**
```bash
# SSH zum Pi
ssh andre@192.168.178.143

# Debug-Helper laden
source ~/debug/debug-services.sh

# Service verfolgen
trace-service localdisplay.service
```

### **Beispiel 4: Logs analysieren**
```bash
# SSH zum Pi
ssh andre@192.168.178.143

# Service-Logs live ansehen
journalctl -u localdisplay.service -f

# Letzte 100 Zeilen
journalctl -u localdisplay.service -n 100

# Seit heute
journalctl -u localdisplay.service --since today
```

---

## 🔍 TROUBLESHOOTING

### **Problem 1: SSH-Verbindung fehlgeschlagen**
```bash
# Prüfe ob Pi läuft
ping 192.168.178.143

# Prüfe SSH-Port
nc -zv 192.168.178.143 22

# Falls SSH nicht aktiv:
# → Web-UI öffnen: http://192.168.178.143
# → System Config → Security → Web SSH
# → Dort: sudo systemctl start ssh
```

### **Problem 2: Permission Denied**
```bash
# Prüfe sudo-Rechte
sudo -l

# Falls nicht in sudoers:
# → Web-UI → Web SSH
# → Dort: sudo visudo
# → Füge hinzu: andre ALL=(ALL) NOPASSWD: ALL
```

### **Problem 3: Debug-Tools nicht installiert**
```bash
# Manuell installieren
ssh andre@192.168.178.143
sudo apt-get update
sudo apt-get install -y gdb strace valgrind perf htop
```

### **Problem 4: Service nicht gefunden**
```bash
# Liste alle Services
systemctl list-units --type=service

# Prüfe Service-Status
systemctl status localdisplay.service

# Prüfe ob Service läuft
systemctl is-active localdisplay.service
```

---

## 📚 DEBUGGER-BEFEHLE REFERENZ

### **GDB (GNU Debugger):**
```
break <function>      # Breakpoint setzen
break <file>:<line>   # Breakpoint in Datei
run                   # Programm starten
continue              # Weiterlaufen
step                  # Einzelschritt (in Funktion)
next                  # Einzelschritt (über Funktion)
print <variable>      # Variable anzeigen
backtrace             # Stack-Trace
info registers        # Register anzeigen
info breakpoints      # Breakpoints anzeigen
delete <num>          # Breakpoint löschen
quit                  # Beenden
```

### **strace (System Call Tracer):**
```
-p <PID>              # An Prozess anhängen
-f                   # Forked Prozesse verfolgen
-e trace=all         # Alle System-Calls
-e trace=open,read   # Spezifische Calls
-o <file>            # Output in Datei
```

### **valgrind (Memory Debugger):**
```
valgrind <programm>           # Memory-Checks
valgrind --leak-check=full    # Detaillierte Leak-Checks
valgrind --tool=memcheck      # Memory-Checker
```

---

## ✅ CHECKLISTE

- [ ] Pi ist erreichbar (ping funktioniert)
- [ ] SSH-Verbindung funktioniert
- [ ] Setup-Script ausgeführt
- [ ] Debug-Tools installiert
- [ ] Debug-Helper geladen
- [ ] Service gefunden
- [ ] Debugger verbunden

---

**Status:** ✅ VOLLSTÄNDIGE ANLEITUNG ERSTELLT  
**Bereit für Debugger-Verbindung**

