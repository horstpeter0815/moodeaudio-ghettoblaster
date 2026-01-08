# MANUELLE INSTALLATION - JETZT TESTEN

**Datum:** 1. Dezember 2025, 23:45 Uhr  
**Status:** Bereit für sofortige Ausführung

---

## 🚀 SCHNELLINSTALLATION (5 MINUTEN)

### **Auf beiden Pis ausführen:**

```bash
# 1. Scripts auf Pi kopieren (von diesem Mac)
scp FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh andre@192.168.178.62:~/
scp FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh andre@192.168.178.178:~/

# 2. Auf Pi 1 (RaspiOS) verbinden und installieren
ssh andre@192.168.178.62
chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh
sudo bash ~/FINAL_OPTIMIZED_INSTALL.sh
sudo reboot

# 3. Auf Pi 2 (moOde) verbinden und installieren
ssh andre@192.168.178.178
chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh
sudo bash ~/FINAL_OPTIMIZED_INSTALL.sh
sudo reboot
```

---

## 📋 ALTERNATIVE: DIREKTE BEFEHLE (Falls Scripts nicht funktionieren)

### **Auf beiden Pis ausführen:**

```bash
# 1. Backup
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup-$(date +%Y%m%d-%H%M%S)

# 2. FT6236 auskommentieren
sudo sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' /boot/firmware/config.txt

# 3. Service erstellen
sudo tee /etc/systemd/system/ft6236-delay.service > /dev/null << 'EOF'
[Unit]
Description=Load FT6236 touchscreen after display
After=graphical.target
After=localdisplay.service
Wants=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 3 && modprobe ft6236'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# 4. Aktivieren
sudo systemctl daemon-reload
sudo systemctl enable ft6236-delay.service
sudo systemctl start ft6236-delay.service

# 5. Reboot
sudo reboot
```

---

## ✅ NACH REBOOT VERIFIZIEREN

```bash
# Auf beiden Pis nach Reboot:
sudo bash ~/verify_installation.sh

# Oder manuell:
sudo systemctl status ft6236-delay.service
lsmod | grep ft6236
ls -la /dev/input/event*
systemctl is-active localdisplay.service
```

---

## 🔄 ROLLBACK (falls nötig)

```bash
sudo systemctl disable ft6236-delay.service
sudo systemctl stop ft6236-delay.service
sudo cp /boot/firmware/config.txt.backup-* /boot/firmware/config.txt
sudo reboot
```

---

**Bereit für sofortige Installation!** 🚀

