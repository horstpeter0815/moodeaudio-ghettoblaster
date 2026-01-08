# 🔍 SD-KARTE PRÜFUNG - ERGEBNISSE

**Datum:** 2025-12-07  
**Status:** 🔍 PRÜFUNG LÄUFT

---

## 📋 PHASE 1: BOOT-PARTITION

### **Mountpoint:**
- [ ] `/Volumes/bootfs` gemountet

### **Kritische Dateien:**
- [ ] `config.txt` vorhanden
- [ ] `config.txt.overwrite` vorhanden
- [ ] `cmdline.txt` vorhanden
- [ ] `ssh` Flag vorhanden

---

## 📋 PHASE 2: CONFIG.TXT

### **config.txt.overwrite:**
- [ ] `display_rotate=0` vorhanden
- [ ] `hdmi_force_mode=1` vorhanden
- [ ] Pi 5 Konfiguration vorhanden

### **config.txt:**
- [ ] Enthält korrekte Einstellungen

---

## 📋 PHASE 3: ROOT-PARTITION

### **Mountpoint:**
- [ ] `/Volumes/rootfs` gemountet (normalerweise nicht auf macOS)

### **Kritische Verzeichnisse:**
- [ ] `/usr/local/bin` vorhanden
- [ ] `/etc/systemd/system` vorhanden
- [ ] `/lib/systemd/system` vorhanden

---

## 📋 PHASE 4: SERVICES

### **IP-Fix:**
- [ ] `fix-network-ip.sh` auf bootfs
- [ ] `static-ip.txt` auf bootfs

---

## 📋 PHASE 5: BOOT-DATEIEN

### **SSH:**
- [ ] `ssh` Flag vorhanden

### **cmdline.txt:**
- [ ] Vorhanden und korrekt

### **config.txt:**
- [ ] Vorhanden
- [ ] `config.txt.overwrite` vorhanden

---

## 📋 PHASE 6: VERGLEICH

### **config.txt.overwrite:**
- [ ] `display_rotate=0` stimmt überein
- [ ] `hdmi_force_mode=1` stimmt überein

---

**Status:** 🔍 PRÜFUNG LÄUFT

