# WebSSH Anleitung - Config anwenden

**Status:** WebSSH funktioniert mit `andre` / `0815`, normales SSH (Port 22) noch nicht.

## 📋 Schritte über WebSSH:

### 1. WebSSH öffnen
- Gehe zu: `http://192.168.1.101:4200`
- Login mit: `andre` / `0815`

### 2. Config-Datei hochladen

**Option A: Über WebSSH Terminal**
```bash
# Erstelle die Config-Datei direkt
sudo nano /tmp/config.txt
# Kopiere den Inhalt von MOODE_PI5_WAVESHARE_HDMI_CONFIG.txt hinein
```

**Option B: Über SCP (wenn SSH funktioniert)**
```bash
# Vom Mac aus:
scp MOODE_PI5_WAVESHARE_HDMI_CONFIG.txt andre@192.168.1.101:/tmp/config.txt
```

### 3. Skript ausführen

Im WebSSH Terminal:
```bash
# Kopiere das Skript
cat > /tmp/apply-config.sh << 'EOF'
#!/bin/bash
sudo systemctl enable ssh
sudo systemctl start ssh
sudo touch /boot/firmware/ssh
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup_$(date +%Y%m%d_%H%M%S)
sudo mount -o remount,rw /boot/firmware
sudo cp /tmp/config.txt /boot/firmware/config.txt
sudo chmod 644 /boot/firmware/config.txt
sync
echo "✅ Config angewendet!"
EOF

chmod +x /tmp/apply-config.sh
/tmp/apply-config.sh
```

### 4. Reboot
```bash
sudo reboot
```

Nach dem Reboot sollte:
- ✅ SSH (Port 22) funktionieren
- ✅ Config-Dateien angewendet sein
- ✅ Waveshare Display konfiguriert sein

---

## 🔧 Alternative: Direkt über WebSSH

Falls du die Config-Datei nicht hochladen kannst, kannst du sie direkt im Terminal erstellen:

```bash
sudo nano /boot/firmware/config.txt
# Füge die Config-Einstellungen ein
sudo reboot
```

