# PLAN: FT6236 MIT DELAY IMPLEMENTIERUNG

**Datum:** 1. Dezember 2025  
**Ziel:** Touchscreen funktioniert, Display startet zuerst

---

## 🎯 ZIEL

- ✅ Touchscreen (FT6236) funktioniert
- ✅ Display startet zuerst (keine Timing-Probleme)
- ✅ X Server läuft stabil
- ✅ Beide Pis konfiguriert

---

## 📋 IMPLEMENTIERUNGSPLAN

### **SCHRITT 1: FT6236 AUS config.txt ENTFERNEN**

**Auf beiden Pis:**
- PI 192.168.178.178 (Ghettoblaster - moOde)
- PI 192.168.178.62 (Smooth Audio - RaspiOS)

**Aktion:**
```bash
# FT6236 aus config.txt entfernen (nicht deaktivieren, sondern entfernen)
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt
```

**Grund:**
- FT6236 soll nicht beim Boot geladen werden
- Wird später von systemd-Service geladen

---

### **SCHRITT 2: SYSTEMD-SERVICE ERSTELLEN**

**Service-Name:** `ft6236-delay.service`

**Service-Definition:**
```ini
[Unit]
Description=Load FT6236 Touchscreen after Display
After=graphical.target
After=localdisplay.service
Wants=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe ft6236 || true'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
```

**Was macht der Service:**
1. Wartet auf `graphical.target` (Display-System bereit)
2. Wartet auf `localdisplay.service` (X Server läuft)
3. Lädt dann FT6236-Modul (`modprobe ft6236`)

**Alternative (falls modprobe nicht funktioniert):**
- Device Tree Overlay zur Laufzeit laden (komplexer)
- Oder: FT6236 in config.txt behalten, aber mit `dtoverlay=ft6236,disable` und dann aktivieren

---

### **SCHRITT 3: SERVICE AKTIVIEREN**

**Auf beiden Pis:**
```bash
# Service-Datei erstellen
sudo tee /etc/systemd/system/ft6236-delay.service > /dev/null << 'EOF'
[Unit]
Description=Load FT6236 Touchscreen after Display
After=graphical.target
After=localdisplay.service
Wants=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe ft6236 || true'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# Service aktivieren
sudo systemctl daemon-reload
sudo systemctl enable ft6236-delay.service
```

---

### **SCHRITT 4: TOUCHSCREEN-KONFIGURATION IN .xinitrc**

**Prüfen ob Touchscreen-Konfiguration in .xinitrc vorhanden ist:**
```bash
# Prüfe .xinitrc
grep -i "ft6236\|touch" /home/andre/.xinitrc
```

**Falls nicht vorhanden, hinzufügen:**
```bash
# Touchscreen-Kalibrierung nach FT6236-Laden
# Warte auf FT6236
sleep 2
xinput set-prop "FT6236" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1 2>/dev/null || true
```

---

### **SCHRITT 5: TEST**

**Nach Reboot:**
1. Prüfe: Display startet stabil?
2. Prüfe: FT6236 wird geladen? (`lsmod | grep ft6236`)
3. Prüfe: Touchscreen funktioniert? (`xinput list`)
4. Prüfe: Service läuft? (`systemctl status ft6236-delay.service`)

---

## 🔧 ALTERNATIVE: DEVICE TREE OVERLAY ZUR LAUFZEIT

**Falls `modprobe ft6236` nicht funktioniert:**

**Option A: configfs verwenden:**
```bash
# Device Tree Overlay zur Laufzeit laden
mkdir -p /sys/kernel/config/device-tree/overlays/ft6236
echo ft6236 > /sys/kernel/config/device-tree/overlays/ft6236/path
echo 1 > /sys/kernel/config/device-tree/overlays/ft6236/status
```

**Option B: dtoverlay-Tool verwenden:**
```bash
# Falls dtoverlay-Tool verfügbar
dtoverlay ft6236
```

**Option C: FT6236 in config.txt behalten, aber deaktivieren:**
```bash
# In config.txt: dtoverlay=ft6236,disable
# Dann im Service aktivieren (falls möglich)
```

---

## 📋 IMPLEMENTIERUNGS-REIHENFOLGE

### **1. PI 192.168.178.62 (Smooth Audio - RaspiOS)**
- FT6236 aus config.txt entfernen
- Service erstellen
- Service aktivieren
- Reboot
- Test

### **2. PI 192.168.178.178 (Ghettoblaster - moOde)**
- FT6236 aus config.txt entfernen
- Service erstellen
- Service aktivieren
- Reboot
- Test

---

## ✅ ERWARTETES ERGEBNIS

**Nach Implementierung:**
- ✅ Display startet zuerst (keine Timing-Probleme)
- ✅ FT6236 lädt nach Display (via systemd-Service)
- ✅ Touchscreen funktioniert
- ✅ X Server läuft stabil
- ✅ Keine Crashes mehr

---

## ⚠️ MÖGLICHE PROBLEME

### **Problem 1: modprobe ft6236 funktioniert nicht**
**Lösung:** Device Tree Overlay zur Laufzeit laden (Alternative)

### **Problem 2: FT6236 wird nicht erkannt**
**Lösung:** Prüfe ob FT6236-Modul verfügbar ist (`modinfo ft6236`)

### **Problem 3: Touchscreen-Kalibrierung fehlt**
**Lösung:** Touchscreen-Konfiguration in .xinitrc hinzufügen

---

**Status:** 📋 **PLAN ERSTELLT - BEREIT FÜR IMPLEMENTIERUNG**

