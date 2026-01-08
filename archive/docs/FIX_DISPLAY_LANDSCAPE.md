# 🔧 Display auf Landscape + Browser starten

**Problem:**
- Display ist Portrait (display_rotate=3)
- Soll Landscape sein (display_rotate=0)
- Browser startet nicht
- Schwarzer Bildschirm mit "Mood Audio Login"

---

## 🔧 FIX 1: Display-Rotation ändern

**Über Web-UI:**
1. Öffne: http://192.168.178.161
2. Gehe zu: Configure → System
3. Suche: Display Rotation
4. Ändere: Portrait → Landscape (oder 270° → 0°)
5. Speichern & Neustart

**Oder über SSH (wenn verfügbar):**
```bash
sudo sed -i 's/display_rotate=3/display_rotate=0/' /boot/firmware/config.txt
sudo reboot
```

---

## 🌐 FIX 2: Browser starten

**Über Web-UI:**
1. Gehe zu: Configure → Peripherals
2. Suche: Local Display
3. Aktiviere: Local Display
4. URL: http://localhost
5. Kiosk Mode: Aktivieren
6. Speichern

**Oder über SSH:**
```bash
sudo systemctl enable localdisplay
sudo systemctl start localdisplay
```

---

## 📋 VOLLSTÄNDIGER FIX (SSH)

```bash
# 1. Display-Rotation ändern
sudo sed -i 's/display_rotate=3/display_rotate=0/' /boot/firmware/config.txt

# 2. Chromium starten
sudo systemctl enable localdisplay
sudo systemctl start localdisplay

# 3. Neustart
sudo reboot
```

---

**Nach Neustart:**
- Display sollte Landscape sein
- Browser sollte automatisch starten
- PeppyMeter sollte sichtbar sein

