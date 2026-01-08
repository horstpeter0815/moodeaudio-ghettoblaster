# PI 5 SSH SETUP

**Datum:** 03.12.2025  
**Zweck:** SSH-Zugriff ohne Passwort für effizientes Arbeiten

---

## ⚠️ WICHTIG: Script wird auf dem MAC ausgeführt!

Das Script `setup-pi5-ssh.sh` wird **auf dem Mac** ausgeführt. Es:
1. Erstellt einen SSH-Key auf dem Mac (falls nicht vorhanden)
2. Kopiert den Public Key auf den Pi 5
3. Testet die Verbindung

**NICHT auf dem Pi 5 ausführen!**

---

## 📍 SCRIPT FINDEN

Das Script liegt im Projektverzeichnis:
```
/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/
```

**Zum Projektverzeichnis navigieren:**
```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
```

**Oder kürzer (wenn du im Home-Verzeichnis bist):**
```bash
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/Ablage/Roon\ filters/Bose\ Wave/OS/RPi4/moodeaudio/cursor
```

**Dann Script ausführen:**
```bash
./setup-pi5-ssh.sh
```

---

## SETUP (EINMALIG)

### **1. Auf dem Mac ausführen:**
```bash
# Zum Projektverzeichnis navigieren
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

# Script ausführen
./setup-pi5-ssh.sh
```

**Was macht das Script:**
- ✅ Erstellt SSH-Key auf dem Mac (falls nicht vorhanden)
- ✅ Kopiert Public Key auf Pi 5 (verwendet Passwort einmalig)
- ✅ Testet Verbindung ohne Passwort

**Voraussetzungen:**
- ✅ Pi 5 muss erreichbar sein (192.168.178.134)
- ✅ Passwort bekannt (moode oder moodeaudio)
- ✅ SSH-Service läuft auf Pi 5
- ✅ `sshpass` installiert auf Mac (`brew install hudochenkov/sshpass/sshpass`)

---

## VERWENDUNG NACH SETUP

### **1. Einzelne Befehle (auf Mac):**
```bash
# Im Projektverzeichnis
./pi5-ssh.sh "hostname && uname -a"
./pi5-ssh.sh "systemctl status mpd"
./pi5-ssh.sh "cat /boot/firmware/config.txt"
```

### **2. Dateien kopieren (Mac → Pi 5):**
```bash
./pi5-ssh.sh copy local_file.txt /opt/moode/bin/file.txt
```

### **3. Dateien kopieren (Pi 5 → Mac):**
```bash
./pi5-ssh.sh pull /boot/firmware/config.txt config.txt.backup
```

### **4. Interaktive Shell (auf Mac):**
```bash
./pi5-ssh.sh
# Oder:
./pi5-ssh.sh shell
```

---

## BEISPIELE

### **System-Info:**
```bash
./pi5-ssh.sh "hostname && uname -a && cat /etc/os-release | head -3"
```

### **Service-Status:**
```bash
./pi5-ssh.sh "systemctl status mpd localdisplay peppymeter"
```

### **Config prüfen:**
```bash
./pi5-ssh.sh "grep -E 'display_rotate|hifiberry' /boot/firmware/config.txt"
```

### **Datei bearbeiten:**
```bash
# Lokal auf Mac bearbeiten
nano myfile.txt

# Auf Pi 5 kopieren
./pi5-ssh.sh copy myfile.txt /opt/moode/bin/myfile.txt

# Auf Pi 5 ausführbar machen
./pi5-ssh.sh "chmod +x /opt/moode/bin/myfile.txt"
```

---

## TROUBLESHOOTING

### **Problem: "no such file or directory"**
- Du bist im falschen Verzeichnis!
- Navigiere zum Projektverzeichnis (siehe oben)

### **Problem: "sshpass: command not found"**
```bash
# Auf Mac installieren:
brew install hudochenkov/sshpass/sshpass
```

### **Problem: "Permission denied"**
- SSH-Key nicht installiert → `./setup-pi5-ssh.sh` ausführen
- Falsches Passwort → Script anpassen (Zeile 11)

### **Problem: "Connection refused"**
- Pi 5 nicht erreichbar → IP prüfen: `ping 192.168.178.134`
- SSH-Service läuft nicht → Auf Pi 5: `systemctl start ssh`

### **Problem: "Host key verification failed"**
```bash
# Auf Mac:
ssh-keygen -R 192.168.178.134
# Dann Setup erneut ausführen
```

---

## WIE ES FUNKTIONIERT

1. **Erstes Mal (mit Passwort):**
   - Script verwendet `sshpass` um sich mit Passwort anzumelden
   - Kopiert Public Key (`~/.ssh/id_rsa.pub`) nach `~/.ssh/authorized_keys` auf Pi 5

2. **Danach (ohne Passwort):**
   - SSH verwendet automatisch den Private Key (`~/.ssh/id_rsa`)
   - Kein Passwort mehr nötig

---

**Status:** ✅ Scripts erstellt, ⏳ Setup durchführen
