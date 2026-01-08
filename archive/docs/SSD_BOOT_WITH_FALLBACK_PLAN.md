# SSD BOOT MIT FALLBACK - PLAN

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**Zweck:** moOde auf SSD, Fallback auf SD-Karte mit DietPi

---

## 🎯 ANFORDERUNGEN

**Primär-System:**
- ✅ moOde Audio auf SSD
- ✅ Hauptsystem für Produktion

**Fallback-System:**
- ✅ DietPi auf SD-Karte
- ✅ Aktiviert, wenn SSD-System versagt
- ✅ Minimal-System für Recovery

---

## 📋 HARDWARE-SETUP

### **SSD:**
- USB-SSD oder NVMe-SSD (je nach Pi 5 Modell)
- Format: ext4
- Partition: Boot + Root
- Größe: Mindestens 32GB (empfohlen: 64GB+)

### **SD-Karte:**
- Format: ext4
- Partition: Boot + Root
- Größe: Mindestens 16GB
- System: DietPi (minimal)

---

## 🔧 BOOT-PRIORITÄT KONFIGURIEREN

### **Pi 5 Boot-Reihenfolge:**
1. **SSD (USB/NVMe)** - Primär
2. **SD-Karte** - Fallback

### **Konfiguration:**

**Option 1: Boot-Priorität in EEPROM**
- EEPROM konfigurieren für USB/NVMe Boot zuerst
- SD-Karte als Fallback

**Option 2: Boot-Sequenz in config.txt**
- `boot_order` Parameter setzen
- USB/NVMe zuerst, dann SD

---

## 📋 IMPLEMENTIERUNGS-PHASEN

### **PHASE 1: SSD vorbereiten**
1. SSD formatieren (ext4)
2. moOde Image auf SSD schreiben
3. Boot-Partition konfigurieren
4. Test-Boot von SSD

### **PHASE 2: SD-Karte vorbereiten (Fallback)**
1. DietPi Image auf SD-Karte schreiben
2. Minimal-Konfiguration
3. SSH aktivieren
4. Basis-Tools installieren

### **PHASE 3: Boot-Priorität konfigurieren**
1. EEPROM konfigurieren
2. Boot-Order setzen (SSD → SD)
3. Timeout für Fallback setzen
4. Test: SSD-Boot
5. Test: SD-Fallback (SSD entfernen)

### **PHASE 4: Monitoring & Recovery**
1. Boot-Status-Monitoring
2. Automatischer Fallback bei Fehler
3. Recovery-Script für SSD-Reparatur
4. Dokumentation

---

## 🔧 TECHNISCHE DETAILS

### **Boot-Order Konfiguration:**

**EEPROM Update:**
```bash
# Boot-Order: USB → SD
rpi-eeprom-config --edit
# Setze: BOOT_ORDER=0xf41
# 0xf41 = USB → SD → Network
```

**config.txt (auf SSD):**
```
# Boot von USB/NVMe
boot_order=0xf41
```

**config.txt (auf SD - Fallback):**
```
# Fallback Boot
boot_order=0xf41
```

---

### **SSD Partitionierung:**

**Partition 1: Boot (FAT32)**
- Größe: 256MB
- Mount: /boot/firmware

**Partition 2: Root (ext4)**
- Größe: Rest
- Mount: /

---

### **SD-Karte Partitionierung (DietPi):**

**Partition 1: Boot (FAT32)**
- Größe: 256MB
- Mount: /boot

**Partition 2: Root (ext4)**
- Größe: Rest
- Mount: /

---

## 🔄 FALLBACK-MECHANISMUS

### **Automatischer Fallback:**
1. Pi 5 versucht Boot von SSD
2. Wenn SSD nicht verfügbar → Boot von SD
3. Wenn SSD fehlerhaft → Boot von SD
4. DietPi startet als Recovery-System

### **Manueller Fallback:**
1. SSD physisch entfernen
2. Pi 5 bootet automatisch von SD
3. DietPi startet

---

## 📊 MONITORING

### **Boot-Status prüfen:**
```bash
# Prüfe von welchem Device gebootet wurde
lsblk
df -h
cat /proc/cmdline
```

### **Boot-Log prüfen:**
```bash
journalctl -b
dmesg | grep -i boot
```

---

## 🛠️ RECOVERY-SCRIPT

**Für DietPi (Fallback-System):**
- Script zum Prüfen der SSD
- Script zum Reparieren der SSD
- Script zum Zurückspielen des moOde Images

---

## ✅ VORTEILE

**SSD-Boot:**
- ✅ Schneller Boot
- ✅ Bessere Performance
- ✅ Längere Lebensdauer
- ✅ Mehr Speicher

**SD-Fallback:**
- ✅ Redundanz
- ✅ Recovery möglich
- ✅ System bleibt funktionsfähig
- ✅ Wartung ohne Ausfall

---

## 📝 NÄCHSTE SCHRITTE

1. **Planung:** Detaillierte Implementierungs-Schritte
2. **SSD vorbereiten:** Image auf SSD schreiben
3. **SD vorbereiten:** DietPi auf SD schreiben
4. **Boot-Order:** Konfigurieren
5. **Testing:** Beide Systeme testen
6. **Monitoring:** Boot-Status-Monitoring implementieren

---

**Status:** PLAN ERSTELLT  
**Nächster Schritt:** Detaillierte Implementierungs-Schritte

