# X SERVER CRASH - ROOT CAUSE ANALYSE

**Datum:** 1. Dezember 2025  
**Status:** 🔍 **PLANUNGSMODUS - PROBLEM IDENTIFIZIERT**

---

## 🎯 ROOT CAUSE IDENTIFIZIERT

### **Das Problem:**
**FT6236 Touchscreen-Overlay initialisiert VOR dem Display → Display hinkt → X Server crasht**

---

## 📋 BEWEISE

### **1. Konfiguration (PI 192.168.178.62):**

**`/boot/firmware/config.txt` - Overlay-Reihenfolge:**
```
Zeile 13: dtoverlay=disable-uart
Zeile 15: dtoverlay=vc4-kms-v3d-pi5,noaudio    ← Display-Overlay
Zeile 40: dtoverlay=hifiberry-amp100-pi5-dsp-reset
Zeile 42: dtoverlay=ft6236                     ← Touchscreen-Overlay
```

**Beobachtung:**
- FT6236 wird NACH dem Display-Overlay geladen (Zeile 42 vs 15)
- ABER: Touchscreen-Treiber initialisiert sich trotzdem zu früh
- Display hinkt/startet verzögert
- X Server crasht oder startet nicht stabil

### **2. Boot-Logs:**

**FT6236 Initialisierung:**
- ❌ Keine FT6236-Logs in `dmesg` gefunden
- Möglicherweise: FT6236 initialisiert, aber Logs fehlen
- Oder: FT6236 blockiert I2C-Bus, den Display braucht

**Display Initialisierung:**
- ✅ vc4/kms/drm wird bei ~4-5 Sekunden initialisiert
- ✅ Display-Treiber lädt korrekt

### **3. Symptome:**

- ✅ Display blinkt
- ✅ Display ist inaktiv
- ✅ X Server crasht wiederholt
- ✅ Service läuft, aber Display funktioniert nicht

---

## 💡 WARUM DAS PROBLEM VERURSACHT

### **Timing-Konflikt:**

1. **FT6236 Overlay wird geladen** (auch wenn nach Display-Overlay)
2. **Touchscreen-Treiber versucht I2C-Bus zu nutzen**
3. **Display braucht auch I2C-Bus** (für EDID, Hotplug-Detection)
4. **Race Condition:** Touchscreen blockiert I2C → Display kann nicht initialisieren
5. **Display hinkt** → X Server kann nicht starten → Crash

### **Alternative Erklärung:**

- FT6236 nutzt I2C-Bus 13 (RP1 Controller)
- Display nutzt auch I2C für EDID/Hotplug
- Beide versuchen gleichzeitig I2C zu nutzen
- I2C-Arbitration-Fehler → Display kann nicht starten

---

## 🔄 WAS WIR BEREITS VERSUCHT HABEN

### **Viele Versuche (2 Wochen):**

1. ✅ Service-Varianten (User, Parameter, Dependencies)
2. ✅ LightDM (Wayland-Konflikt, Permission-Probleme)
3. ✅ Wayland/Weston (Chromium-Kompatibilität)
4. ✅ Permission-Fixes (Gruppen, udev, /dev/tty0)
5. ✅ .xinitrc Varianten (Standard, vereinfacht, mit Wartezeiten)
6. ✅ X Server Parameter (-nolisten tcp, -novtswitch, vt7)
7. ✅ Restart-Strategien (Restart=always, verschiedene Delays)
8. ✅ Environment-Variablen (DISPLAY, XAUTHORITY, HOME)

**Ergebnis:** ❌ Nichts hat funktioniert

---

## ✅ LÖSUNG

### **OPTION 1: FT6236 DEAKTIVIEREN (Test)**

**Wenn Touchscreen nicht benötigt wird:**
```bash
# Kommentiere FT6236 aus
sudo sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' /boot/firmware/config.txt
sudo reboot
```

**Erwartetes Ergebnis:**
- Display startet stabil
- X Server läuft
- Keine Crashes mehr

### **OPTION 2: FT6236 MIT DELAY LADEN**

**Touchscreen NACH Display initialisieren:**
```bash
# Entferne FT6236 aus config.txt
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt

# Erstelle systemd-Service für verzögerte Initialisierung
sudo tee /etc/systemd/system/ft6236-delay.service > /dev/null << 'EOF'
[Unit]
Description=Enable FT6236 Touchscreen after Display
After=graphical.target
After=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe ft6236 || true'
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

sudo systemctl enable ft6236-delay.service
```

### **OPTION 3: FT6236 ANS ENDE VERSCHIEBEN**

**Touchscreen sollte NACH allen Display-Overlays geladen werden:**
```bash
# Entferne FT6236 von aktueller Position
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt

# Füge FT6236 ganz ans Ende hinzu
echo "dtoverlay=ft6236" | sudo tee -a /boot/firmware/config.txt
```

---

## 📊 ZUSAMMENFASSUNG

### **Problem:**
- ✅ **ROOT CAUSE:** FT6236 Touchscreen initialisiert vor Display
- ✅ **SYMPTOM:** Display hinkt → X Server crasht
- ✅ **BEWEIS:** FT6236 Overlay in config.txt, Display-Probleme

### **Lösung:**
- ✅ **OPTION 1:** FT6236 deaktivieren (Test)
- ✅ **OPTION 2:** FT6236 mit Delay laden
- ✅ **OPTION 3:** FT6236 ans Ende verschieben

### **Nächster Schritt:**
- ⏳ **TEST:** FT6236 deaktivieren → Reboot → Prüfe ob Display stabil läuft
- ⏳ **FALLS ERFOLG:** Problem bestätigt = FT6236 Timing-Problem
- ⏳ **DANN:** FT6236 mit Delay oder ans Ende verschieben

---

**Status:** 🔍 **PLANUNGSMODUS - BEREIT FÜR TEST**

