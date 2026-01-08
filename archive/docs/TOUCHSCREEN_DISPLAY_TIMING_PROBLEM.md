# TOUCHSCREEN vs DISPLAY TIMING-PROBLEM

**Datum:** 1. Dezember 2025  
**Problem:** Touchscreen (FT6236) initialisiert VOR dem Display → Display hinkt

---

## 🔍 PROBLEM

**Beobachtung:**
- Touchscreen (FT6236 Overlay) versucht, sich VOR dem Display zu initialisieren
- Display hinkt/startet verzögert
- X Server crasht oder startet nicht stabil

---

## 📋 AKTUELLE KONFIGURATION (PI 192.168.178.62)

### `/boot/firmware/config.txt` - Overlay-Reihenfolge:

```
Zeile 13: dtoverlay=disable-uart
Zeile 15: dtoverlay=vc4-kms-v3d-pi5,noaudio    ← Display-Overlay
Zeile 40: dtoverlay=hifiberry-amp100-pi5-dsp-reset
Zeile 42: dtoverlay=ft6236                     ← Touchscreen-Overlay
```

**Problem:** FT6236 wird NACH dem Display-Overlay geladen, ABER:
- Touchscreen-Treiber könnte trotzdem zu früh initialisieren
- Race Condition zwischen Touchscreen-Init und Display-Init
- Touchscreen blockiert möglicherweise I2C-Bus, den das Display braucht

---

## 💡 LÖSUNG

### **OPTION 1: FT6236 Overlay DEAKTIVIEREN**

**Wenn Touchscreen nicht benötigt wird:**
```bash
# Kommentiere FT6236 aus
sudo sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' /boot/firmware/config.txt
```

### **OPTION 2: FT6236 Overlay NACH Display verschieben**

**Touchscreen sollte NACH Display initialisiert werden:**
```bash
# Entferne FT6236 von aktueller Position
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt

# Füge FT6236 NACH allen Display-Overlays hinzu (ganz ans Ende)
echo "dtoverlay=ft6236" | sudo tee -a /boot/firmware/config.txt
```

### **OPTION 3: FT6236 mit Delay laden**

**Erstelle systemd-Service, der Touchscreen NACH Display-Start aktiviert:**
```ini
[Unit]
Description=Enable FT6236 Touchscreen after Display
After=graphical.target
After=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe ft6236 || true'

[Install]
WantedBy=graphical.target
```

### **OPTION 4: FT6236 komplett entfernen (wenn nicht benötigt)**

**Wenn Touchscreen nicht funktioniert oder nicht benötigt wird:**
```bash
# Entferne FT6236 Overlay komplett
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt
```

---

## 🧪 TEST

**Test 1: FT6236 deaktivieren**
```bash
sudo sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' /boot/firmware/config.txt
sudo reboot
```

**Test 2: FT6236 ans Ende verschieben**
```bash
sudo sed -i '/^dtoverlay=ft6236/d' /boot/firmware/config.txt
echo "dtoverlay=ft6236" | sudo tee -a /boot/firmware/config.txt
sudo reboot
```

**Test 3: Boot-Logs prüfen**
```bash
dmesg | grep -E 'ft6236|vc4|kms|drm' | head -20
```

---

## ✅ ERWARTETES ERGEBNIS

**Nach Fix:**
- Display startet zuerst
- Touchscreen initialisiert NACH Display
- Keine Race Conditions
- X Server startet stabil
- Display hinkt nicht mehr

---

**Status:** 🔍 **PROBLEM IDENTIFIZIERT - TESTE FIX**

