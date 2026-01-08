# 🚀 MOODE PI5 SETUP - BEREIT

**Datum:** $(date +"%Y-%m-%d %H:%M:%S")

---

## ✅ VORBEREITET

**Setup-Script:** `SETUP_MOODE_PI5.sh`
- Wartet auf Pi Boot
- Wendet Config-Dateien automatisch an
- Erstellt Backups

**Config-Dateien:**
- `PI5_WORKING_CONFIG.txt` - Funktionierende Config für Pi 5
- `sd_card_config/cmdline.txt` - Cmdline Config

**Login-Daten:**
- User: `andre`
- Pass: `0815`
- IP: `192.168.178.134` (Standard, kann überschrieben werden)

---

## 🎯 NÄCHSTE SCHRITTE

1. **Warte auf dein Signal, dass der Pi gebootet ist**
2. **Dann ausführen:**
   ```bash
   ./SETUP_MOODE_PI5.sh
   ```
   
   Oder mit anderer IP:
   ```bash
   ./SETUP_MOODE_PI5.sh 192.168.178.XXX
   ```

---

## 📋 WAS DAS SCRIPT MACHT

1. ✅ Prüft ob Pi erreichbar ist (Ping)
2. ✅ Wartet auf SSH
3. ✅ Erstellt Backup der originalen Config-Dateien
4. ✅ Kopiert `PI5_WORKING_CONFIG.txt` → `/boot/firmware/config.txt`
5. ✅ Kopiert `sd_card_config/cmdline.txt` → `/boot/firmware/cmdline.txt`
6. ✅ Fragt nach Reboot
7. ✅ Wartet auf Neustart

---

## 🔧 MANUELLE ALTERNATIVE

Falls das Script nicht funktioniert:

```bash
# SSH Verbindung
ssh andre@192.168.178.134
# Pass: 0815

# Config kopieren
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
sudo nano /boot/firmware/config.txt
# Inhalt von PI5_WORKING_CONFIG.txt einfügen

# Cmdline kopieren
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
sudo nano /boot/firmware/cmdline.txt
# Inhalt von sd_card_config/cmdline.txt einfügen

# Reboot
sudo reboot
```

---

**Status:** ⏳ **WARTE AUF PI BOOT**

