# 🔧 HOSTNAME-FIX

**Datum:** 2025-12-07  
**Problem:** Hostname ist "mood" statt "GhettoBlaster"  
**Status:** ✅ Fix für nächsten Build hinzugefügt

---

## 🔍 PROBLEM

### **Symptom:**
- Hostname nach Boot ist `mood` statt `GhettoBlaster`
- Config hat `TARGET_HOSTNAME=GhettoBlaster`
- moOde überschreibt Hostname beim Boot

### **Ursache:**
- Hostname wurde nicht im Build-Script gesetzt
- pi-gen setzt Hostname, aber moOde überschreibt es

---

## ✅ LÖSUNG

### **Für nächsten Build:**
- ✅ Hostname wird im Build-Script gesetzt (`stage3_03-ghettoblaster-custom_00-run-chroot.sh`)
- ✅ `/etc/hostname` wird geschrieben
- ✅ `hostnamectl set-hostname GhettoBlaster`
- ✅ `/etc/hosts` wird aktualisiert

### **Fix hinzugefügt:**
```bash
# Set hostname in /etc/hostname
echo "GhettoBlaster" > /etc/hostname

# Set hostname with hostnamectl
hostnamectl set-hostname GhettoBlaster

# Update /etc/hosts
sed -i 's/127.0.1.1.*/127.0.1.1\tGhettoBlaster/' /etc/hosts
```

---

## 🔧 MANUELLER FIX (FÜR DIESEN BUILD)

### **Auf dem Pi ausführen:**
```bash
# Hostname setzen
sudo hostnamectl set-hostname GhettoBlaster

# /etc/hostname schreiben
echo "GhettoBlaster" | sudo tee /etc/hostname

# /etc/hosts aktualisieren
sudo sed -i 's/127.0.1.1.*/127.0.1.1\tGhettoBlaster/' /etc/hosts

# Prüfen
hostname
# Sollte "GhettoBlaster" ausgeben
```

### **Nach Reboot prüfen:**
```bash
hostname
# Sollte "GhettoBlaster" sein
```

---

## 📋 FÜR NÄCHSTEN BUILD

### **Fix ist bereits im Build-Script:**
- ✅ `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`
- ✅ Hostname wird automatisch gesetzt
- ✅ Funktioniert beim nächsten Build

---

**Status:** ✅ FIX FÜR NÄCHSTEN BUILD HINZUGEFÜGT  
**Manueller Fix:** Verfügbar für aktuellen Build

