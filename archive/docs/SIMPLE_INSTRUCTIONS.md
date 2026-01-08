# Einfache Anleitung - Display Fix

## 🚀 Schnellste Methode

### Schritt 1: Script auf Pi kopieren
```bash
scp fix_display_on_pi.sh andre@192.168.178.178:/tmp/
# Passwort: 0815
```

### Schritt 2: Auf Pi einloggen und ausführen
```bash
ssh andre@192.168.178.178
# Passwort: 0815

chmod +x /tmp/fix_display_on_pi.sh
bash /tmp/fix_display_on_pi.sh
```

### Schritt 3: Reboot
```bash
sudo reboot
```

**Fertig!** Nach Reboot sollte das Display 1280x400 Landscape zeigen.

---

## 🔧 Alternative: Manuell

Falls das Script nicht funktioniert, führe die Befehle manuell aus:

### 1. Auf Pi einloggen
```bash
ssh andre@192.168.178.178
```

### 2. Backup erstellen
```bash
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
```

### 3. config.txt bearbeiten
```bash
sudo nano /boot/firmware/config.txt
```

**Füge hinzu oder ersetze [pi5] Sektion:**
```ini
[all]
disable_fw_kms_setup=1

[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87
disable_overscan=1
framebuffer_width=1280
framebuffer_height=400
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

### 4. cmdline.txt bearbeiten
```bash
sudo nano /boot/firmware/cmdline.txt
```

**Füge am Ende hinzu (nach dem letzten Wort):**
```
video=HDMI-A-2:1280x400M@60
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

### 5. xinitrc setzen
```bash
nano ~/.xinitrc
```

**Ersetze alles mit:**
```bash
#!/bin/sh
export DISPLAY=:0
sleep 2

for i in 1 2 3 4 5; do
    if xrandr --output HDMI-A-2 --query 2>/dev/null | grep -q "connected"; then
        break
    fi
    sleep 1
done

xrandr --output HDMI-A-2 --mode 1280x400 2>/dev/null || \
xrandr --output HDMI-A-2 --mode 400x1280 --rotate right 2>/dev/null || \
xrandr --output HDMI-A-2 --auto 2>/dev/null

xrandr --fb 1280x400 2>/dev/null || true

exec chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --window-size=1280,400 \
    --start-fullscreen \
    http://localhost
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

```bash
chmod +x ~/.xinitrc
```

### 6. Touchscreen-Config setzen
```bash
sudo mkdir -p /etc/X11/xorg.conf.d
sudo nano /etc/X11/xorg.conf.d/99-touchscreen.conf
```

**Füge hinzu:**
```
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

### 7. Reboot
```bash
sudo reboot
```

---

## ✅ Nach Reboot prüfen

```bash
ssh andre@192.168.178.178
export DISPLAY=:0
xrandr --output HDMI-A-2 --query | grep current
```

**Sollte zeigen:** `current 1280 x 400`

---

## 🆘 Probleme?

### Display zeigt immer noch Portrait
- Prüfe config.txt: `cat /boot/firmware/config.txt | grep -A 10 "[pi5]"`
- Prüfe cmdline.txt: `cat /boot/firmware/cmdline.txt | grep video`
- Prüfe xinitrc: `cat ~/.xinitrc`

### Pi nicht erreichbar
```bash
ping 192.168.178.178
```
- Falls nicht erreichbar: Netzwerk prüfen

### Script funktioniert nicht
- Verwende manuelle Schritte oben

---

**Status:** ✅ Alle Optionen bereit

