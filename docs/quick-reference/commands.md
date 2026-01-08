# Wichtige Befehle - Quick Reference

**Schnellreferenz für häufig verwendete Befehle**

---

## 🔧 System

### **moOde Status**

```bash
# moOde Status
moodeutl -l

# MPD Status
mpc status

# Audio-Info
moodeutl -A
```

### **Services**

```bash
# Service Status
systemctl status mpd
systemctl status camilladsp
systemctl status peppymeter

# Service starten/stoppen
sudo systemctl start mpd
sudo systemctl stop mpd
sudo systemctl restart mpd
```

---

## 🖥️ Display & Touch

### **Display-Info**

```bash
# Display-Info
tvservice -s
vcgencmd get_display_power_state

# Display ein/aus
vcgencmd display_power 1
vcgencmd display_power 0
```

### **Touchscreen**

```bash
# Touchscreen-Status
systemctl status ft6236-delay

# Touchscreen-Test
evtest /dev/input/event0
```

---

## 🔊 Audio

### **ALSA**

```bash
# Audio-Geräte
aplay -l
arecord -l

# Volume
amixer sget Master
amixer sset Master 50%
```

### **CamillaDSP**

```bash
# CamillaDSP Status
systemctl status camilladsp

# Config prüfen
camilladsp --check /etc/camilladsp/config.yml

# Logs
journalctl -u camilladsp -f
```

---

## 📁 Dateien & Config

### **config.txt**

```bash
# config.txt bearbeiten
sudo nano /boot/firmware/config.txt

# config.txt anzeigen
cat /boot/firmware/config.txt

# Neustart nach Änderung
sudo reboot
```

### **Logs**

```bash
# System-Logs
journalctl -f

# moOde-Logs
tail -f /var/log/moode.log

# MPD-Logs
tail -f /var/log/mpd.log
```

---

## 🌐 Netzwerk

### **IP-Adresse**

```bash
# IP-Adresse
hostname -I
ip addr show

# Netzwerk-Info
ifconfig
```

### **SSH**

```bash
# SSH-Verbindung
ssh pi@192.168.178.161

# SSH-Key generieren
ssh-keygen -t rsa
```

---

## 🔍 Debugging

### **Hardware-Info**

```bash
# CPU-Info
vcgencmd measure_temp
vcgencmd measure_volts
vcgencmd get_mem arm
vcgencmd get_mem gpu

# Overlays
vcgencmd get_config dtoverlay
```

### **Prozesse**

```bash
# Laufende Prozesse
ps aux | grep mpd
ps aux | grep camilladsp

# CPU-Auslastung
top
htop
```

---

## 📦 Software

### **Updates**

```bash
# System-Update
sudo apt update
sudo apt upgrade -y

# moOde-Update
sudo moodeutl -U
```

### **Pakete**

```bash
# Paket installieren
sudo apt install <paket>

# Paket suchen
apt search <paket>
```

---

## 🎛️ moOde-spezifisch

### **moOde Utilities**

```bash
# Alle moOde-Utilities
moodeutl -h

# System-Info
moodeutl -l

# Audio-Info
moodeutl -A

# Update
moodeutl -U
```

### **Web-UI**

```bash
# Web-UI öffnen
http://moode.local
http://192.168.178.161

# Web-UI Status
systemctl status lighttpd
```

---

## 🔐 Sicherheit

### **Passwort ändern**

```bash
# User-Passwort
passwd

# Root-Passwort
sudo passwd root
```

### **Firewall**

```bash
# Firewall-Status
sudo ufw status

# Firewall aktivieren
sudo ufw enable
```

---

## 📊 Monitoring

### **System-Monitoring**

```bash
# System-Info
uname -a
cat /proc/cpuinfo
free -h
df -h

# Temperatur
vcgencmd measure_temp

# Uptime
uptime
```

---

## 🚀 Deployment

### **Image brennen**

```bash
# SD-Karte finden
lsblk

# Image brennen
sudo dd if=image.img of=/dev/sdX bs=4M status=progress
sync
```

### **Image kopieren**

```bash
# Image zu Pi kopieren
scp image.img pi@192.168.178.161:/tmp/
```

---

## 🔗 Weitere Ressourcen

- **Hardware-Setup:** [../hardware-setup/](../hardware-setup/)
- **Config-Parameter:** [../config-parameters/](../config-parameters/)
- **Anleitungen:** [../instructions/](../instructions/)

---

**Letzte Aktualisierung:** 2025-12-07

