# 🔍 SD-KARTE PRÜFUNG

**Datum:** 2025-12-07  
**Status:** SD-Karte im Mac - Prüfe Fixes

---

## 📋 PRÜF-LISTE

### **1. Boot-Konfiguration (config.txt):**
- [ ] `display_rotate=0` (Landscape)
- [ ] `hdmi_force_mode=1` (Force landscape)
- [ ] HiFiBerry AMP100 Overlay
- [ ] FT6236 Touchscreen Overlay

### **2. Services:**
- [ ] `enable-ssh-early.service` vorhanden
- [ ] `fix-ssh-sudoers.service` vorhanden
- [ ] `fix-user-id.service` vorhanden
- [ ] `localdisplay.service` vorhanden

### **3. Hostname:**
- [ ] `/etc/hostname` = `GhettoBlaster`
- [ ] `/etc/hosts` enthält `GhettoBlaster`

### **4. User-Konfiguration:**
- [ ] User `andre` mit UID 1000
- [ ] Password: `0815`
- [ ] Sudoers konfiguriert

---

## 🛠️ BEI PROBLEMEN

### **Fixes fehlen:**
- Image neu brennen
- Oder: Manuell auf SD-Karte fixen

### **config.txt falsch:**
- Mounte Boot-Partition
- Editiere `config.txt`
- Unmounte SD-Karte

---

**Status:** 🔍 PRÜFE SD-KARTE  
**Nächster Schritt:** Fixes prüfen, dann SD-Karte in Pi einstecken

