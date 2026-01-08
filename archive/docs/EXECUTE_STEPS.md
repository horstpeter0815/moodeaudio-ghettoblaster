# Einfache Ausführungs-Schritte

## Schritt 1: Scripts ausführbar machen

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
chmod +x FIX_MOODE_DISPLAY_FINAL.sh
chmod +x VERIFY_DISPLAY_FIX.sh
```

## Schritt 2: Display Fix ausführen

```bash
./FIX_MOODE_DISPLAY_FINAL.sh
```

**Was passiert:**
- Erstellt Backups
- Setzt config.txt, cmdline.txt, xinitrc
- Konfiguriert Touchscreen
- Erstellt Screenshot

## Schritt 3: Pi 5 rebooten

```bash
ssh andre@192.168.178.178
# Passwort: 0815
sudo reboot
```

**Warte bis Pi wieder online ist** (ca. 1-2 Minuten)

## Schritt 4: Verifikation

```bash
./VERIFY_DISPLAY_FIX.sh
```

**Prüft:**
- config.txt Einträge
- cmdline.txt Video-Parameter
- Display-Status
- xinitrc
- Touchscreen-Config
- Erstellt Screenshot

---

## Alternative: Manuell auf dem Pi

Wenn die Scripts nicht funktionieren, kannst du die Befehle direkt auf dem Pi ausführen:

### 1. Auf Pi einloggen
```bash
ssh andre@192.168.178.178
# Passwort: 0815
```

### 2. Backup erstellen
```bash
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
cp ~/.xinitrc ~/.xinitrc.backup 2>/dev/null || true
```

### 3. config.txt setzen
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

### 4. cmdline.txt setzen
```bash
sudo nano /boot/firmware/cmdline.txt
```

**Füge am Ende hinzu:**
```
video=HDMI-A-2:1280x400M@60
```

### 5. xinitrc setzen
```bash
nano ~/.xinitrc
```

**Ersetze mit:**
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

### 7. Reboot
```bash
sudo reboot
```

---

## Troubleshooting

### Script funktioniert nicht
- Prüfe ob `sshpass` installiert ist: `which sshpass`
- Falls nicht: `brew install hudochenkov/sshpass/sshpass` (Mac)
- Oder verwende manuelle Schritte oben

### Pi nicht erreichbar
```bash
ping 192.168.178.178
```
- Falls nicht erreichbar: Netzwerk prüfen
- Falls IP geändert: Script anpassen

### Nach Reboot funktioniert es nicht
- Prüfe Screenshots: `scp andre@192.168.178.178:/tmp/display_*.png .`
- Prüfe Logs: `ssh andre@192.168.178.178 "dmesg | tail -50"`
- Prüfe X11: `ssh andre@192.168.178.178 "ps aux | grep Xorg"`

---

**Status:** ✅ Scripts bereit, Anleitung erstellt

