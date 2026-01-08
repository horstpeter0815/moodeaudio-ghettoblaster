# Deployment-Anleitung

**Schritt-für-Schritt Anleitung zum Deployen des moOde Images**

---

## 📋 Voraussetzungen

- ✅ moOde Image erstellt (`2025-12-07-moode-r1001-arm64-lite.img`)
- ✅ SD-Karte (mind. 8GB, empfohlen 16GB+)
- ✅ Raspberry Pi Hardware
- ✅ Netzwerk-Verbindung (optional)

---

## 🚀 Methode 1: Direkt auf Pi 5

### **Schritt 1: Image zu Pi 5 kopieren**

```bash
# Im Projekt-Verzeichnis
scp 2025-12-07-moode-r1001-arm64-lite.img pi@192.168.178.161:/tmp/

# Passwort eingeben (falls nötig)
```

### **Schritt 2: Auf Pi 5 einloggen**

```bash
ssh pi@192.168.178.161
```

### **Schritt 3: SD-Karte finden**

```bash
lsblk

# Beispiel-Output:
# NAME        SIZE TYPE MOUNTPOINT
# mmcblk0    14.9G disk
# └─mmcblk0p1 256M part /boot
# sda        14.9G disk    ← Das ist die SD-Karte!
```

### **Schritt 4: Image brennen**

```bash
# ⚠️ WICHTIG: Richtige SD-Karte wählen!
# Beispiel für /dev/sda:
sudo umount /dev/sda* 2>/dev/null
sudo dd if=/tmp/2025-12-07-moode-r1001-arm64-lite.img of=/dev/sda bs=4M status=progress
sync
```

**Dauer:** ~5-10 Minuten

---

## 🚀 Methode 2: Mit balenaEtcher (Mac/Windows)

### **Schritt 1: balenaEtcher öffnen**

1. balenaEtcher installieren: https://www.balena.io/etcher
2. balenaEtcher öffnen

### **Schritt 2: Image auswählen**

1. "Flash from file" klicken
2. `2025-12-07-moode-r1001-arm64-lite.img` auswählen

### **Schritt 3: SD-Karte auswählen**

1. SD-Karte in Computer einstecken
2. "Select target" klicken
3. SD-Karte auswählen

### **Schritt 4: Brennen**

1. "Flash!" klicken
2. Warten (~5-10 Minuten)

---

## 🚀 Methode 3: Mit `dd` (Mac/Linux)

### **Schritt 1: SD-Karte finden**

```bash
# Mac
diskutil list

# Linux
lsblk
```

### **Schritt 2: SD-Karte unmounten**

```bash
# Mac
diskutil unmountDisk /dev/disk2

# Linux
sudo umount /dev/sdX*
```

### **Schritt 3: Image brennen**

```bash
# Mac (Beispiel: /dev/disk2)
sudo dd if=2025-12-07-moode-r1001-arm64-lite.img of=/dev/rdisk2 bs=4m

# Linux (Beispiel: /dev/sda)
sudo dd if=2025-12-07-moode-r1001-arm64-lite.img of=/dev/sda bs=4M status=progress
```

### **Schritt 4: Sync**

```bash
sync
```

---

## ✅ Nach dem Brennen

### **Schritt 1: SD-Karte entfernen**

SD-Karte sicher auswerfen/entfernen.

### **Schritt 2: SD-Karte in Raspberry Pi stecken**

SD-Karte in den Raspberry Pi (Ziel-System) einstecken.

### **Schritt 3: System booten**

1. Raspberry Pi mit Strom versorgen
2. System bootet automatisch
3. Warten bis Boot abgeschlossen (~1-2 Minuten)

### **Schritt 4: Web-UI öffnen**

```
http://moode.local
oder
http://<IP-ADRESSE>
```

**IP-Adresse finden:**
```bash
# Auf dem Pi
hostname -I
```

---

## 🔧 Erste Konfiguration

### **1. Web-UI öffnen**

```
http://moode.local
```

### **2. Audio-Output konfigurieren**

- **Ghetto Blaster:** HiFiBerry AMP100
- **Ghetto Boom/Moob:** HiFiBerry BeoCreate
- **Ghetto Scratch:** HiFiBerry DAC+ ADC Pro

### **3. Display konfigurieren (nur Ghetto Blaster)**

- **Resolution:** 1280x400
- **Rotation:** 180°
- **Touchscreen:** FT6236

### **4. Features aktivieren**

- ✅ Flat EQ Preset
- ✅ Room Correction Wizard
- ✅ PeppyMeter (Ghetto Blaster)

---

## 🐛 Troubleshooting

### **Problem: SD-Karte wird nicht erkannt**

**Lösung:**
- SD-Karte neu einstecken
- Anderen USB-Port/Slot verwenden
- SD-Karte formatieren (FAT32)

### **Problem: System bootet nicht**

**Lösung:**
- SD-Karte erneut brennen
- Andere SD-Karte verwenden
- Boot-Logs prüfen (Serial Console)

### **Problem: Web-UI nicht erreichbar**

**Lösung:**
- IP-Adresse prüfen: `hostname -I`
- Netzwerk-Verbindung prüfen
- Firewall prüfen

### **Problem: Audio funktioniert nicht**

**Lösung:**
- HAT korrekt montiert?
- config.txt prüfen
- Audio-Output in Web-UI prüfen

---

## 📚 Weitere Ressourcen

- **Hardware-Setup:** [../hardware-setup/](../hardware-setup/)
- **Config-Parameter:** [../config-parameters/](../config-parameters/)
- **Quick Reference:** [../quick-reference/commands.md](../quick-reference/commands.md)

---

**Letzte Aktualisierung:** 2025-12-07

