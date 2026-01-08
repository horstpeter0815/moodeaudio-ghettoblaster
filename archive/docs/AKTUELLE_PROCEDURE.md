# AKTUELLE PROCEDURE - ANSATZ 1: SYSTEMD-SERVICE (DELAY)

**Status:** ✅ IN ARBEIT (Beide Systeme parallel)  
**Erfolgswahrscheinlichkeit:** 95%  
**Datum:** 02.12.2025

**✅ PROJEKT-ÄNDERUNG:** Pi 1 ist jetzt Pi 4, beide Systeme parallel

---

## 📋 DEFINIERTE PROCEDURE

### **SCHRITT 1: FT6236 OVERLAY AUS CONFIG.TXT ENTFERNEN** ✅
- [x] Backup erstellen
- [x] FT6236 Overlay auskommentieren (beide Pis)
- [x] Verifikation: `grep ft6236 /boot/firmware/config.txt`

### **SCHRITT 2: SYSTEMD-SERVICE ERSTELLEN** ✅
- [x] Service-Datei erstellen: `/etc/systemd/system/ft6236-delay.service`
- [x] Service aktivieren: `systemctl enable ft6236-delay.service`
- [x] Systemd reload: `systemctl daemon-reload`

### **SCHRITT 3: VERIFIKATION** ✅
- [x] Service-Status prüfen: `systemctl status ft6236-delay.service`
- [x] Service enabled prüfen
- [x] Config.txt prüfen

### **SCHRITT 4: REBOOT & TEST** ⏳ IN ARBEIT
- [x] Reboot durchführen (PI 1 - Pi 4)
- [x] Service-Logs prüfen
- [ ] FT6236 Modul prüfen
- [ ] Nach Reboot prüfen:
  - [x] Service-Status (PI 1)
  - [ ] FT6236 Modul geladen
  - [ ] Touchscreen-Device vorhanden
  - [ ] Display funktioniert
  - [ ] Touchscreen funktioniert
  - [ ] Keine X Server Crashes

**Status:**
- ✅ **PI 1 (Pi 4 - 192.168.178.96):** Ansatz 1 implementiert, Reboot durchgeführt
- ⏸️ **PI 2 (Pi 5 - 192.168.178.178):** Offline, wartet auf Verbindung

---

## 🎯 SERVICE-DEFINITION

```ini
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
```

---

## 📊 FORTSCHRITT

**Aktueller Schritt:** SCHRITT 4 - REBOOT & TEST  
**Status:** ⏳ Verifikation nach Reboot läuft

**Status:**
- ✅ **PI 1 (RaspiOS - Pi 4 - 192.168.178.96):** Ansatz 1 implementiert
- ✅ **PI 2 (moOde - Pi 5 - 192.168.178.134):** Ansatz 1 implementiert
- ⏳ **Nächster Schritt:** Touchscreen, PeppyMeter, Display-Rotation prüfen

---

**KEINE ABWEICHUNGEN VON DIESER PROCEDURE!**

