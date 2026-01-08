# SSD FALLBACK STRATEGY - KOMPLETT

**Datum:** 2. Dezember 2025  
**Status:** PLAN  
**Zweck:** Komplette Strategie für SSD-Boot mit SD-Fallback

---

## 🎯 SYSTEM-ARCHITEKTUR

```
┌─────────────────────────────────────────┐
│         Raspberry Pi 5                 │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   SSD        │    │   SD-Karte   │  │
│  │   (Primär)   │    │  (Fallback)  │  │
│  │              │    │              │  │
│  │  moOde Audio │    │   DietPi     │  │
│  │  (Produktion)│    │  (Recovery)  │  │
│  └──────────────┘    └──────────────┘  │
│         │                    │          │
│         └────────┬───────────┘          │
│                  │                      │
│         ┌────────▼──────────┐           │
│         │   Boot-Loader     │           │
│         │  (EEPROM)         │           │
│         │  Priorität:       │           │
│         │  1. SSD (USB)     │           │
│         │  2. SD            │           │
│         └───────────────────┘           │
└─────────────────────────────────────────┘
```

---

## 📋 BOOT-SZENARIEN

### **Szenario 1: Normal-Betrieb (SSD)**
1. Pi 5 startet
2. Boot-Loader prüft SSD
3. ✅ SSD gefunden → Boot von SSD
4. moOde startet
5. System läuft normal

### **Szenario 2: SSD-Fehler (Automatischer Fallback)**
1. Pi 5 startet
2. Boot-Loader prüft SSD
3. ❌ SSD nicht verfügbar/fehlerhaft
4. ⚠️  Timeout (3 Sekunden)
5. ✅ Fallback auf SD-Karte
6. DietPi startet
7. Recovery möglich

### **Szenario 3: Manueller Fallback**
1. SSD physisch entfernen
2. Pi 5 startet
3. Boot-Loader findet keine SSD
4. ✅ Boot von SD-Karte
5. DietPi startet

---

## 🔧 KONFIGURATION

### **EEPROM Boot-Order:**
```
BOOT_ORDER=0xf41
```
**Bedeutung:**
- `0xf` = Try SD, USB, Network
- `4` = USB Mass Storage
- `1` = SD Card
- Reihenfolge: USB → SD → Network

### **Boot-Timeout:**
```
boot_delay=3
```
**Bedeutung:**
- 3 Sekunden warten auf SSD
- Dann Fallback auf SD

---

## 🛠️ RECOVERY-PROZEDUR

### **Von DietPi (Fallback-System):**

**1. SSD prüfen:**
```bash
/opt/recovery/check-ssd.sh
```

**2. SSD reparieren (falls möglich):**
```bash
sudo fsck -y /dev/sda2
```

**3. moOde Image zurückspielen:**
```bash
/opt/recovery/restore-moode.sh
```

**4. SSD neu formatieren (wenn nötig):**
```bash
/opt/recovery/format-ssd.sh
```

---

## 📊 MONITORING

### **Boot-Status prüfen:**
```bash
# Von welchem Device gebootet?
cat /var/log/boot-status.log

# Aktuelles Boot-Device
lsblk | grep -E 'mmcblk0p2|sda2'

# Boot-Device aus Kernel
cat /proc/cmdline | grep -o 'root=[^ ]*'
```

### **Alert bei Fallback:**
- Boot-Status-Service loggt Fallback
- Optional: E-Mail/Notification senden
- Wartung planen

---

## ✅ VORTEILE

**SSD-Boot:**
- ✅ Schneller Boot (2-3x schneller)
- ✅ Bessere Performance
- ✅ Längere Lebensdauer
- ✅ Mehr Speicher möglich

**SD-Fallback:**
- ✅ Redundanz
- ✅ System bleibt funktionsfähig
- ✅ Recovery ohne Ausfall
- ✅ Wartung möglich

---

## 📝 IMPLEMENTIERUNGS-CHECKLISTE

### **SSD vorbereiten:**
- [ ] SSD formatieren (Boot + Root)
- [ ] moOde Image auf SSD schreiben
- [ ] Boot-Partition konfigurieren
- [ ] Test-Boot von SSD

### **SD-Karte vorbereiten:**
- [ ] DietPi Image auf SD schreiben
- [ ] DietPi konfigurieren
- [ ] Recovery-Tools installieren
- [ ] Recovery-Scripts erstellen

### **Boot konfigurieren:**
- [ ] EEPROM Boot-Order setzen
- [ ] Boot-Timeout konfigurieren
- [ ] Test SSD-Boot
- [ ] Test SD-Fallback

### **Monitoring:**
- [ ] Boot-Status-Script erstellen
- [ ] Boot-Status-Service aktivieren
- [ ] Recovery-Scripts testen

---

**Status:** PLAN ERSTELLT  
**Nächster Schritt:** Schritt-für-Schritt implementieren

