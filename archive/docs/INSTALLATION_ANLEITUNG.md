# INSTALLATION ANLEITUNG - ANSATZ 1

**Datum:** 1. Dezember 2025  
**Status:** Ready  
**Version:** 1.0

---

## 🎯 ÜBERSICHT

Installation von Ansatz 1 (FT6236 Delay Service) auf beiden Raspberry Pis.

---

## 📋 VORBEREITUNG

### **Benötigt:**
- ✅ SSH-Zugriff auf beide Pis
- ✅ Root/Sudo-Zugriff
- ✅ Scripts: `install_ansatz1_raspios.sh` und `install_ansatz1_moode.sh`

---

## 🖥️ PHASE 1: RASPIOS (PI 1 - 192.168.178.62)

### **Schritt 1: Script kopieren**
```bash
scp install_ansatz1_raspios.sh andre@192.168.178.62:~/
```

### **Schritt 2: Auf Pi 1 verbinden**
```bash
ssh andre@192.168.178.62
```

### **Schritt 3: Script ausführen**
```bash
sudo bash ~/install_ansatz1_raspios.sh
```

### **Schritt 4: Reboot**
```bash
sudo reboot
```

### **Schritt 5: Nach Reboot prüfen**
```bash
# Service-Status
sudo systemctl status ft6236-delay.service

# FT6236 Modul
lsmod | grep ft6236

# Touchscreen-Device
ls -la /dev/input/event*

# Display-Status
systemctl is-active localdisplay.service
```

---

## 🎵 PHASE 2: MOODE AUDIO (PI 2 - 192.168.178.178)

### **Schritt 1: Script kopieren**
```bash
scp install_ansatz1_moode.sh andre@192.168.178.178:~/
```

### **Schritt 2: Auf Pi 2 verbinden**
```bash
ssh andre@192.168.178.178
```

### **Schritt 3: Script ausführen**
```bash
sudo bash ~/install_ansatz1_moode.sh
```

### **Schritt 4: Reboot**
```bash
sudo reboot
```

### **Schritt 5: Nach Reboot prüfen**
```bash
# Service-Status
sudo systemctl status ft6236-delay.service

# FT6236 Modul
lsmod | grep ft6236

# Touchscreen-Device
ls -la /dev/input/event*

# Display-Status
systemctl is-active localdisplay.service

# Audio-Status (wichtig für moOde!)
systemctl is-active mpd.service
```

---

## ✅ ERFOLGS-KRITERIEN

### **Beide Pis sollten zeigen:**
- ✅ Display startet stabil (kein Flickering)
- ✅ Touchscreen funktioniert nach 3 Sekunden
- ✅ Keine X Server Crashes
- ✅ System startet zuverlässig

### **Zusätzlich für moOde:**
- ✅ Audio funktioniert weiterhin
- ✅ MPD läuft

---

## 🔄 ROLLBACK

### **Falls etwas schiefgeht:**

#### **Auf RaspiOS (Pi 1):**
```bash
sudo systemctl disable ft6236-delay.service
sudo systemctl stop ft6236-delay.service
sudo cp /boot/firmware/config.txt.backup-* /boot/firmware/config.txt
sudo reboot
```

#### **Auf moOde (Pi 2):**
```bash
sudo systemctl disable ft6236-delay.service
sudo systemctl stop ft6236-delay.service
sudo cp /boot/firmware/config.txt.backup-* /boot/firmware/config.txt
sudo reboot
```

---

## 📊 TEST-PROTOKOLL

### **Nach Installation auf beiden Pis:**

| Test | Pi 1 (RaspiOS) | Pi 2 (moOde) | Status |
|------|----------------|--------------|--------|
| **Display startet** | ⏳ | ⏳ | - |
| **Touchscreen funktioniert** | ⏳ | ⏳ | - |
| **Keine X Crashes** | ⏳ | ⏳ | - |
| **Audio funktioniert** | N/A | ⏳ | - |
| **System stabil** | ⏳ | ⏳ | - |

---

## 🔗 VERWANDTE DOKUMENTE

- [Implementierung Ansatz 1](WISSENSBASIS/19_IMPLEMENTIERUNG_ANSATZ_1.md)
- [Implementierungs-Strategie](WISSENSBASIS/20_IMPLEMENTIERUNGS_STRATEGIE.md)

---

**Letzte Aktualisierung:** 1. Dezember 2025

