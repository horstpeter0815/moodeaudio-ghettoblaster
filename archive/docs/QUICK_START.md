# QUICK START - SOFORT LOSLEGEN

**Für beide Pis - Einfach kopieren und ausführen!**

---

## 🚀 SCHNELLINSTALLATION

### **Auf beiden Pis (Pi 1 & Pi 2):**

```bash
# 1. Script herunterladen/kopieren
# (Kopiere MASTER_INSTALL.sh auf den Pi)

# 2. Ausführen
sudo bash MASTER_INSTALL.sh

# 3. Reboot
sudo reboot
```

**Das war's!** ✅

---

## 📋 MANUELLE INSTALLATION (Falls Script nicht funktioniert)

### **Auf beiden Pis:**

```bash
# 1. Backup
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

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

## ✅ NACH REBOOT PRÜFEN

```bash
# Service-Status
sudo systemctl status ft6236-delay.service

# FT6236 geladen?
lsmod | grep ft6236

# Touchscreen-Device?
ls -la /dev/input/event*

# Display aktiv?
systemctl is-active localdisplay.service
```

---

## 🔄 ROLLBACK

```bash
sudo systemctl disable ft6236-delay.service
sudo systemctl stop ft6236-delay.service
sudo cp /boot/firmware/config.txt.backup /boot/firmware/config.txt
sudo reboot
```

---

**Fertig!** 🎉
