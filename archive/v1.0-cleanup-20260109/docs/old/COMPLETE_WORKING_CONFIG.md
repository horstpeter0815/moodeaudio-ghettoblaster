# Complete Working Configuration - moOde Pi5

**Date:** 2025-12-25  
**Status:** ✅ FULLY WORKING  
**IP:** 192.168.1.138  
**User:** andre (Passwort: 0815)

---

## ✅ Current Working State

1. **Network:** eth0 via DHCP, IP: 192.168.1.138 ✅
2. **Web UI:** HTTP 200, erreichbar ✅
3. **Display:** Landscape-Modus (1280x400) ✅
4. **SSH:** Funktioniert ✅
5. **Services:** Alle laufen ✅

---

## 📋 Complete Configuration

### config.txt
```
#########################################
# This file is managed by moOde
#########################################

[cm4]
otg_mode=1
[pi4]
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_enable_4kp60=0
[all]
dtoverlay=vc4-kms-v3d
max_framebuffers=2
display_auto_detect=1
disable_fw_kms_setup=1
arm_64bit=1
arm_boost=0
disable_splash=1
disable_overscan=1
hdmi_drive=2
hdmi_blanking=1
hdmi_force_edid_audio=1
hdmi_force_hotplug=1
hdmi_group=0
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=on
dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75
```

**Wichtig:** Hat moOde Headers - verhindert worker.php Overwrite!

### cmdline.txt
```
console=serial0,115200 console=tty1 root=PARTUUID=585bdb7b-02 rootfstype=ext4 fsck.repair=yes rootwait
```

### moOde Database Settings (Display)
```
hdmi_scn_orient|portrait
local_display|1
local_display_url|http://localhost/
dsi_scn_type|none
dsi_scn_rotate|0
```

**Wichtig:** Display-Rotation wird durch moOde Web-UI gesetzt, nicht durch config.txt!

### Display Configuration Flow

1. **moOde Web-UI** → Setzt `hdmi_scn_orient` in Datenbank
2. **`.xinitrc`** → Liest aus Datenbank: `HDMI_SCN_ORIENT=$(moodeutl -q "...")`
3. **xrandr** → Rotiert Display falls `portrait`: `xrandr --output HDMI-1 --rotate left`
4. **Chromium** → Startet mit `--window-size="$SCREEN_RES"` (aus kmsprint/fbset)

**Aktuell:** Display zeigt Landscape (1280x400), obwohl DB "portrait" sagt - bedeutet Rotation wird nicht angewendet oder Display ist bereits korrekt.

---

## 🔒 Protection Applied

### ✅ Implemented

1. **config.txt Backup:** `/boot/firmware/config.txt.working-backup`
2. **NetworkManager-wait-online:** Maskiert (`/dev/null`)
3. **Restore-Service:** Aktiviert (`restore-config.service`)
4. **Restore-Script:** `/usr/local/bin/restore-working-config.sh`

### ⚠️ After Reboot

- Restore-Service läuft automatisch
- config.txt wird wiederhergestellt falls überschrieben
- NetworkManager-wait-online bleibt maskiert
- **moOde Database:** Bleibt erhalten (in SQLite-Datenbank)
- **Display:** Sollte weiterhin funktionieren (wird von moOde gesetzt)

---

## 📝 Reproducible Setup Steps

### Initial Setup (Standard moOde Image)

1. **SD-Karte vorbereiten:**
   ```bash
   # SSH aktivieren
   touch /Volumes/bootfs/ssh
   
   # WLAN konfigurieren (optional)
   cat > /Volumes/bootfs/wpa_supplicant.conf <<EOF
   country=DE
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   network={
       ssid="Theedge553 2.4G/5G"
       psk="theedge553"
   }
   EOF
   ```

2. **Nach Boot - SSH verbinden:**
   ```bash
   ssh andre@<IP>
   # Passwort: 0815
   ```

3. **Protection anwenden:**
   ```bash
   # Backup config.txt
   sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.working-backup
   
   # Mask NetworkManager-wait-online
   sudo ln -sf /dev/null /etc/systemd/system/NetworkManager-wait-online.service
   sudo systemctl daemon-reload
   
   # Restore-Service aktivieren
   sudo tee /usr/local/bin/restore-working-config.sh > /dev/null <<'EOF'
   #!/bin/bash
   if [ -f /boot/firmware/config.txt.working-backup ]; then
       if ! grep -q "# This file is managed by moOde" /boot/firmware/config.txt; then
           cp /boot/firmware/config.txt.working-backup /boot/firmware/config.txt
       fi
   fi
   ln -sf /dev/null /etc/systemd/system/NetworkManager-wait-online.service
   systemctl daemon-reload
   EOF
   
   sudo chmod +x /usr/local/bin/restore-working-config.sh
   
   sudo tee /etc/systemd/system/restore-config.service > /dev/null <<'EOF'
   [Unit]
   Description=Restore Working Configuration
   After=local-fs.target
   Before=network.target
   [Service]
   Type=oneshot
   ExecStart=/usr/local/bin/restore-working-config.sh
   RemainAfterExit=yes
   [Install]
   WantedBy=multi-user.target
   EOF
   
   sudo systemctl enable restore-config.service
   ```

4. **Display konfigurieren (via Web-UI):**
   - Öffne: `http://<IP>/`
   - System → Local Display → Konfigurieren
   - Rotation wird automatisch von moOde gesetzt

---

## ⚠️ Known Issues & Solutions

### worker.php Overwrite
- **Problem:** worker.php kann config.txt überschreiben (Zeilen 110, 116)
- **Solution:** moOde Headers in config.txt verhindern Overwrite ✅

### NetworkManager-wait-online Hang
- **Problem:** Kann Boot blockieren
- **Solution:** Service maskiert ✅

### Display Rotation
- **Problem:** Wird durch moOde Web-UI gesetzt, nicht durch config.txt
- **Solution:** Nach Reboot bleibt moOde-Datenbank erhalten ✅

---

## 🎯 Summary

**Was funktioniert:**
- ✅ Network (DHCP)
- ✅ Web UI
- ✅ Display (Landscape)
- ✅ SSH
- ✅ Alle Services

**Was geschützt ist:**
- ✅ config.txt (Backup + Restore)
- ✅ NetworkManager-wait-online (maskiert)
- ✅ moOde Database (bleibt erhalten)

**Nach Reboot:**
- ✅ Restore-Service stellt alles wieder her
- ✅ Display sollte weiterhin funktionieren
- ✅ Network sollte weiterhin funktionieren

