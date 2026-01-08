# 🔐 Login-Credentials für moOde Custom Build

## ✅ Implementierte Credentials:

**Username:** `andre`  
**Password:** `0815`

**Sudo:** NOPASSWD (kein Passwort für sudo nötig)

---

## 📋 Im Build implementiert:

```bash
# User erstellen
useradd -m -s /bin/bash andre
usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre

# Password setzen
echo "andre:0815" | chpasswd

# Sudoers
echo "andre ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/andre
```

---

## 🔧 SSH-Verbindung:

```bash
ssh andre@<PI_IP>
Password: 0815
```

---

## 📋 Alternative Credentials (falls andre nicht funktioniert):

**moOde Standard:**
- Username: `moode`
- Password: `moodeaudio`

**ODER:**
- Username: `pi`
- Password: `moodeaudio`

---

**Datum:** 2025-12-07  
**Status:** ✅ Implementiert im Build-Script

