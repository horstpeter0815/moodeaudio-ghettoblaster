# IMPLEMENTIERUNG: ANSATZ 1 - SYSTEMD-SERVICE (DELAY)

**Datum:** 1. Dezember 2025  
**Status:** Ready for Implementation  
**Version:** 1.0  
**Priorität:** 🔴 HOCH (Höchste Erfolgswahrscheinlichkeit: 95%)

---

## 🎯 ZIEL

FT6236 Touchscreen mit 3 Sekunden Delay nach Display-Start laden, um Timing-Konflikte zu vermeiden.

---

## ✅ VORAUSSETZUNGEN

- ✅ moOde Audio oder RaspiOS installiert
- ✅ Display funktioniert
- ✅ FT6236 Hardware vorhanden
- ✅ Root-Zugriff

---

## 📋 IMPLEMENTIERUNGS-SCHRITTE

### **SCHRITT 1: FT6236 OVERLAY AUS CONFIG.TXT ENTFERNEN**

#### **Auf beiden Pis:**
```bash
# Backup erstellen
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

# FT6236 Overlay auskommentieren oder entfernen
sudo sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' /boot/firmware/config.txt

# Oder manuell bearbeiten:
sudo nano /boot/firmware/config.txt
# Zeile finden: dtoverlay=ft6236
# Ändern zu: #dtoverlay=ft6236
```

#### **Verifikation:**
```bash
# Prüfen, dass FT6236 nicht mehr aktiv ist
grep -i ft6236 /boot/firmware/config.txt
# Sollte auskommentiert sein: #dtoverlay=ft6236
```

---

### **SCHRITT 2: SYSTEMD-SERVICE ERSTELLEN**

#### **Service-Datei erstellen:**
```bash
sudo nano /etc/systemd/system/ft6236-delay.service
```

#### **Inhalt:**
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

#### **Service aktivieren:**
```bash
# Systemd neu laden
sudo systemctl daemon-reload

# Service aktivieren
sudo systemctl enable ft6236-delay.service

# Service starten (für sofortigen Test)
sudo systemctl start ft6236-delay.service
```

---

### **SCHRITT 3: VERIFIKATION**

#### **Service-Status prüfen:**
```bash
# Service-Status
sudo systemctl status ft6236-delay.service

# Sollte zeigen:
# - Active: active (exited)
# - Loaded: loaded
# - Enabled: enabled
```

#### **FT6236 Modul prüfen:**
```bash
# Prüfen, ob FT6236 geladen ist
lsmod | grep ft6236

# Sollte zeigen:
# ft6236                 20480  0
```

#### **Touchscreen-Device prüfen:**
```bash
# Prüfen, ob Touchscreen-Device existiert
ls -la /dev/input/event*

# Sollte ein Event-Device für FT6236 zeigen
```

#### **X Server Logs prüfen:**
```bash
# X Server Logs prüfen (keine Crashes)
journalctl -u localdisplay.service -n 50

# Sollte keine Fehler zeigen
```

---

### **SCHRITT 4: TEST**

#### **Reboot durchführen:**
```bash
sudo reboot
```

#### **Nach Reboot prüfen:**
```bash
# 1. Service-Status
sudo systemctl status ft6236-delay.service

# 2. FT6236 Modul
lsmod | grep ft6236

# 3. Touchscreen-Device
ls -la /dev/input/event*

# 4. X Server Status
systemctl is-active localdisplay.service

# 5. Display funktioniert (visuell prüfen)
# 6. Touchscreen funktioniert (visuell testen)
```

---

## 🔧 TROUBLESHOOTING

### **Problem: Service startet nicht**

#### **Lösung:**
```bash
# Service-Logs prüfen
journalctl -u ft6236-delay.service -n 50

# Manuell testen
sudo modprobe ft6236

# Prüfen, ob Modul verfügbar ist
modinfo ft6236
```

---

### **Problem: FT6236 lädt zu früh**

#### **Lösung:**
Delay erhöhen (von 3 auf 5 Sekunden):
```bash
sudo nano /etc/systemd/system/ft6236-delay.service
# Ändern: sleep 3 → sleep 5

sudo systemctl daemon-reload
sudo systemctl restart ft6236-delay.service
```

---

### **Problem: Display startet nicht**

#### **Lösung:**
Prüfen, ob `localdisplay.service` funktioniert:
```bash
sudo systemctl status localdisplay.service
journalctl -u localdisplay.service -n 50
```

---

## 📊 ERWARTETE ERGEBNISSE

### **Erfolgreich:**
- ✅ Display startet stabil (kein Flickering)
- ✅ Touchscreen funktioniert nach 3 Sekunden
- ✅ Keine X Server Crashes
- ✅ System startet zuverlässig

### **Metriken:**
- **Boot-Erfolg:** 100%
- **Display-Stabilität:** 100%
- **Touchscreen-Funktionalität:** 100%
- **Timing-Konflikte:** 0%

---

## 🔄 ROLLBACK

### **Falls etwas schiefgeht:**

```bash
# 1. Service deaktivieren
sudo systemctl disable ft6236-delay.service
sudo systemctl stop ft6236-delay.service

# 2. FT6236 Overlay wieder aktivieren
sudo sed -i 's/^#dtoverlay=ft6236/dtoverlay=ft6236/' /boot/firmware/config.txt

# 3. Reboot
sudo reboot
```

---

## 🔗 VERWANDTE DOKUMENTE

- [Ansätze & Vergleich](05_ANSATZE_VERGLEICH.md#ansatz-1-systemd-service-delay)
- [Probleme & Lösungen](03_PROBLEME_LOESUNGEN.md)
- [Troubleshooting](08_TROUBLESHOOTING.md)

---

**Letzte Aktualisierung:** 1. Dezember 2025  
**Nächster Schritt:** Implementierung auf beiden Pis

