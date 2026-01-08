# IMPLEMENTIERUNGS-GUIDES

**Datum:** 1. Dezember 2025  
**Status:** In Arbeit  
**Version:** 1.0

---

## 📋 ÜBERSICHT

Diese Dokumentation enthält detaillierte Implementierungs-Guides für alle Lösungsansätze.

---

## 🎯 ANSATZ A: SYSTEMD-PATH-UNIT IMPLEMENTIERUNG

### **Ziel:**
FT6236 Touchscreen lädt nach Display-Initialisierung (Event-basiert)

### **Schritte:**

#### **Schritt 1: FT6236 Overlay entfernen**
```bash
# Auf beiden Pis:
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt
```

#### **Schritt 2: Path-Unit erstellen**
```bash
# /etc/systemd/system/display-ready.path
sudo tee /etc/systemd/system/display-ready.path > /dev/null << 'EOF'
[Path]
PathExists=/dev/dri/card0
Unit=ft6236-delay.service

[Install]
WantedBy=multi-user.target
EOF
```

#### **Schritt 3: Service erstellen**
```bash
# /etc/systemd/system/ft6236-delay.service
sudo tee /etc/systemd/system/ft6236-delay.service > /dev/null << 'EOF'
[Unit]
Description=Load FT6236 after Display
After=display-ready.path

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 2 && modprobe ft6236'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=display-ready.path
EOF
```

#### **Schritt 4: Services aktivieren**
```bash
sudo systemctl daemon-reload
sudo systemctl enable display-ready.path
sudo systemctl enable ft6236-delay.service
```

#### **Schritt 5: Test**
```bash
sudo reboot
# Nach Reboot prüfen:
systemctl status display-ready.path
systemctl status ft6236-delay.service
lsmod | grep ft6236
xinput list | grep FT6236
```

---

## 🎯 ANSATZ 1: SYSTEMD-SERVICE (DELAY) IMPLEMENTIERUNG

### **Ziel:**
FT6236 Touchscreen lädt nach Display-Start (Zeit-basiert)

### **Schritte:**

#### **Schritt 1: FT6236 Overlay entfernen**
```bash
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt
```

#### **Schritt 2: Service erstellen**
```bash
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
```

#### **Schritt 3: Service aktivieren**
```bash
sudo systemctl daemon-reload
sudo systemctl enable ft6236-delay.service
```

---

## 🔗 VERWANDTE DOKUMENTE

- [Ansätze & Vergleich](05_ANSATZE_VERGLEICH.md)
- [Test-Ergebnisse](04_TESTS_ERGEBNISSE.md)

---

**Letzte Aktualisierung:** 1. Dezember 2025

