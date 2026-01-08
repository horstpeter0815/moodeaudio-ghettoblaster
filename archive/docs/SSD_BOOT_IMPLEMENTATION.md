# SSD BOOT IMPLEMENTATION - DETAILIERTER PLAN

**Datum:** 2. Dezember 2025  
**Status:** IMPLEMENTATION PLAN  
**Zweck:** Schritt-für-Schritt Anleitung für SSD-Boot mit Fallback

---

## 🎯 ÜBERSICHT

**Ziel:**
- moOde auf SSD (Primär)
- DietPi auf SD-Karte (Fallback)
- Automatischer Fallback bei Fehler

---

## 📋 PHASE 1: SSD VORBEREITEN

### **Schritt 1.1: SSD formatieren**

**Auf Mac:**
```bash
# SSD anschließen
diskutil list  # SSD identifizieren

# Partitionen erstellen
# Partition 1: Boot (FAT32, 256MB)
# Partition 2: Root (ext4, Rest)

# Mit Disk Utility oder diskutil
```

**Oder mit Raspberry Pi:**
```bash
# SSD anschließen
lsblk  # SSD identifizieren (z.B. /dev/sda)

# Partitionen erstellen
sudo parted /dev/sda --script mklabel msdos
sudo parted /dev/sda --script mkpart primary fat32 0% 256MB
sudo parted /dev/sda --script mkpart primary ext4 256MB 100%

# Formatieren
sudo mkfs.vfat -F 32 /dev/sda1  # Boot
sudo mkfs.ext4 /dev/sda2         # Root
```

---

### **Schritt 1.2: moOde Image auf SSD schreiben**

**Option A: Von SD-Karte kopieren (wenn moOde bereits auf SD läuft)**
```bash
# Auf Pi 5 (moOde auf SD läuft)
sudo dd if=/dev/mmcblk0 of=/dev/sda bs=4M status=progress
sudo sync
```

**Option B: Image direkt auf SSD schreiben**
```bash
# Auf Mac
# moOde Image herunterladen
# Mit Raspberry Pi Imager auf SSD schreiben
```

---

### **Schritt 1.3: Boot-Partition konfigurieren**

**Auf SSD (nach dem Schreiben):**
```bash
# SSD mounten
sudo mount /dev/sda1 /mnt/boot
sudo mount /dev/sda2 /mnt/root

# config.txt anpassen
sudo nano /mnt/boot/config.txt
# Boot-Order setzen (wenn nötig)

# cmdline.txt prüfen
sudo nano /mnt/boot/cmdline.txt
# root=PARTUUID=... auf SSD-Partition setzen
```

---

### **Schritt 1.4: Test-Boot von SSD**

1. SD-Karte entfernen
2. SSD anschließen
3. Pi 5 booten
4. Prüfen, ob moOde von SSD startet

---

## 📋 PHASE 2: SD-KARTE VORBEREITEN (FALLBACK)

### **Schritt 2.1: DietPi Image auf SD-Karte schreiben**

**Auf Mac:**
1. DietPi Image herunterladen: https://dietpi.com/
2. Raspberry Pi Imager öffnen
3. DietPi Image auf SD-Karte schreiben

---

### **Schritt 2.2: DietPi konfigurieren**

**Erster Boot:**
1. SD-Karte in Pi 5 einstecken
2. Booten (SSD entfernt)
3. DietPi Setup durchführen
4. Minimal-Konfiguration:
   - SSH aktivieren
   - Basis-Tools installieren
   - Netzwerk konfigurieren

---

### **Schritt 2.3: Recovery-Tools installieren**

**Auf DietPi:**
```bash
# Tools für SSD-Recovery
sudo apt update
sudo apt install -y \
    gparted \
    dosfstools \
    e2fsprogs \
    rsync \
    curl \
    wget
```

---

### **Schritt 2.4: Recovery-Script erstellen**

**Script: `/opt/recovery/check-ssd.sh`**
```bash
#!/bin/bash
# Prüft SSD und bietet Recovery-Optionen

SSD_DEVICE="/dev/sda"

echo "=== SSD RECOVERY TOOL ==="
echo ""

# Prüfe ob SSD vorhanden
if [ ! -e "$SSD_DEVICE" ]; then
    echo "❌ SSD nicht gefunden: $SSD_DEVICE"
    exit 1
fi

echo "✅ SSD gefunden: $SSD_DEVICE"
lsblk | grep sda

# Prüfe Partitionen
echo ""
echo "Partitionen:"
sudo fdisk -l $SSD_DEVICE

# Prüfe Dateisystem
echo ""
echo "Dateisystem-Check:"
sudo fsck -n ${SSD_DEVICE}2 2>&1 | head -20

# Optionen
echo ""
echo "Recovery-Optionen:"
echo "1. Dateisystem reparieren: sudo fsck -y ${SSD_DEVICE}2"
echo "2. moOde Image zurückspielen: /opt/recovery/restore-moode.sh"
echo "3. SSD neu formatieren: /opt/recovery/format-ssd.sh"
```

---

## 📋 PHASE 3: BOOT-PRIORITÄT KONFIGURIEREN

### **Schritt 3.1: EEPROM konfigurieren**

**Auf Pi 5 (von SD oder SSD):**
```bash
# EEPROM-Config prüfen
sudo rpi-eeprom-config

# Boot-Order setzen
# 0xf41 = USB → SD → Network
sudo rpi-eeprom-config --edit
# Setze: BOOT_ORDER=0xf41

# EEPROM Update (wenn nötig)
sudo rpi-eeprom-update -a
```

---

### **Schritt 3.2: Boot-Timeout konfigurieren**

**config.txt (auf SSD):**
```
# Boot-Timeout (Sekunden)
boot_delay=3

# Boot-Order
boot_order=0xf41
```

**config.txt (auf SD - Fallback):**
```
# Gleiche Konfiguration
boot_delay=3
boot_order=0xf41
```

---

### **Schritt 3.3: Test SSD-Boot**

1. SSD anschließen
2. SD-Karte entfernen
3. Pi 5 booten
4. Prüfen: `lsblk`, `df -h`, `cat /proc/cmdline`

---

### **Schritt 3.4: Test SD-Fallback**

1. SSD entfernen
2. SD-Karte einstecken
3. Pi 5 booten
4. Prüfen: DietPi startet

---

## 📋 PHASE 4: MONITORING & RECOVERY

### **Schritt 4.1: Boot-Status-Monitoring**

**Script: `/opt/monitoring/boot-status.sh`**
```bash
#!/bin/bash
# Prüft Boot-Status und loggt

BOOT_DEVICE=$(lsblk | grep -E 'mmcblk0p2|sda2' | awk '{print $1}')
BOOT_LOG="/var/log/boot-status.log"

echo "$(date): Boot von $BOOT_DEVICE" >> "$BOOT_LOG"

if [[ "$BOOT_DEVICE" == *"sda"* ]]; then
    echo "✅ Boot von SSD (Primär)"
elif [[ "$BOOT_DEVICE" == *"mmcblk0"* ]]; then
    echo "⚠️  Boot von SD-Karte (Fallback)"
    # Optional: Alert senden
fi
```

**Service: `/etc/systemd/system/boot-status.service`**
```ini
[Unit]
Description=Boot Status Monitoring
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/opt/monitoring/boot-status.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

---

### **Schritt 4.2: Recovery-Script für SSD**

**Script: `/opt/recovery/restore-moode.sh`**
```bash
#!/bin/bash
# Stellt moOde Image auf SSD wieder her

SSD_DEVICE="/dev/sda"
MOODE_IMAGE="/opt/recovery/moode-latest.img"

echo "=== MOODE RECOVERY ==="
echo "WARNUNG: Dies überschreibt alle Daten auf $SSD_DEVICE!"
read -p "Fortfahren? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Abgebrochen"
    exit 1
fi

# Image auf SSD schreiben
sudo dd if="$MOODE_IMAGE" of="$SSD_DEVICE" bs=4M status=progress
sudo sync

echo "✅ moOde Image wiederhergestellt"
echo "SSD kann jetzt neu gestartet werden"
```

---

## 🔧 KONFIGURATION

### **Boot-Order Werte:**
- `0xf41` = USB → SD → Network
- `0xf14` = SD → USB → Network
- `0xf1` = USB → Network (kein SD)

### **Empfohlene Konfiguration:**
- **SSD:** `boot_order=0xf41` (USB zuerst)
- **SD:** `boot_order=0xf41` (gleiche Reihenfolge)

---

## ✅ TEST-PLAN

### **Test 1: SSD-Boot**
1. SSD anschließen, SD entfernen
2. Booten
3. Prüfen: moOde startet von SSD
4. ✅ Erfolg: System funktioniert

### **Test 2: SD-Fallback**
1. SSD entfernen, SD einstecken
2. Booten
3. Prüfen: DietPi startet
4. ✅ Erfolg: Fallback funktioniert

### **Test 3: SSD-Fehler-Simulation**
1. SSD beschädigen (simuliert)
2. Booten
3. Prüfen: Automatischer Fallback auf SD
4. ✅ Erfolg: Fallback aktiviert

---

## 📝 DOKUMENTATION

**Zu erstellen:**
1. ✅ SSD-Boot-Anleitung
2. ✅ Fallback-Konfiguration
3. ✅ Recovery-Prozedur
4. ✅ Troubleshooting-Guide

---

**Status:** IMPLEMENTATION PLAN ERSTELLT  
**Nächster Schritt:** Schritt-für-Schritt implementieren

