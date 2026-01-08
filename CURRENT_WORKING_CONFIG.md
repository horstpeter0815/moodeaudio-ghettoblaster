# Current Working Configuration - moOde Pi5

**Date:** 2025-12-25  
**Status:** ✅ WORKING - Web UI aktiv, Display funktioniert (Landscape)  
**IP:** 192.168.1.138  
**User:** andre (Passwort: 0815)

---

## ✅ What's Working

1. **Network:** eth0 via DHCP, IP: 192.168.1.138
2. **Web UI:** HTTP 200, erreichbar
3. **Display:** Landscape-Modus funktioniert (obwohl Software Portrait sagt)
4. **SSH:** Funktioniert (andre@192.168.1.138)
5. **Services:** 
   - NetworkManager-wait-online: aktiv (aber sollte maskiert werden)
   - cloud-init.target: aktiv
   - localdisplay.service: läuft aktiv

---

## 📋 Current Configuration

### config.txt
- Hat moOde Headers: `# This file is managed by moOde` ✅
- Keine explizite `display_rotate` Einstellung gefunden
- `display_auto_detect=1` aktiv

### cmdline.txt
```
console=serial0,115200 console=tty1 root=PARTUUID=585bdb7b-02 rootfstype=ext4 fsck.repair=yes rootwait
```
- Keine fbcon Rotation
- Keine Display-Rotation Parameter

### Display Configuration
- **Display:** HDMI-1 connected primary 1280x400 (Landscape)
- **Chromium:** Läuft mit `--window-size=1280,400` (Landscape)
- **Rotation:** Wird durch Chromium/Window-Size gesetzt, nicht durch config.txt
- **localdisplay.service:** Aktiv und läuft

### worker.php
- **KRITISCH:** Kann config.txt überschreiben (Zeilen 110, 116)
- Kopiert von `/usr/share/moode-player/boot/firmware/config.txt`

---

## ⚠️ Potential Reboot Issues

1. **worker.php overwrite:** Kann config.txt beim Boot überschreiben
2. **NetworkManager-wait-online:** Sollte maskiert werden
3. **Display Rotation:** Nicht explizit in config.txt - könnte verloren gehen

---

## 🔒 Protection Applied

- ✅ Backup erstellt: `/boot/firmware/config.txt.working-backup`
- ✅ NetworkManager-wait-online maskiert
- ✅ Restore-Service aktiviert: `/etc/systemd/system/restore-config.service`
- ✅ Restore-Script: `/usr/local/bin/restore-working-config.sh`

---

## 📝 Summary

### ✅ What's Protected Now

1. **config.txt Backup:** `/boot/firmware/config.txt.working-backup`
2. **NetworkManager-wait-online:** Maskiert (verhindert Boot-Hang)
3. **Restore-Service:** Aktiviert (stellt nach Reboot wieder her)
4. **moOde Headers:** Vorhanden (verhindert worker.php Overwrite)

### ⚠️ After Reboot

- Restore-Service läuft automatisch
- config.txt wird wiederhergestellt falls überschrieben
- NetworkManager-wait-online bleibt maskiert
- Display sollte weiterhin funktionieren (Chromium Window-Size)

### 🔍 Display Rotation Source

- **Nicht in config.txt** (keine `display_rotate`)
- **Nicht in cmdline.txt** (keine `fbcon=rotate`)
- **Wird gesetzt durch:** moOde Web-UI → Datenbank (`cfg_system` Tabelle)
- **Parameter:** `hdmi_scn_orient`, `dsi_scn_rotate` (werden von `.xinitrc` gelesen)
- **Chromium:** Startet mit Window-Size aus moOde-Konfiguration
- **X11:** HDMI-1 zeigt 1280x400 (Landscape) - wird durch moOde gesetzt

### 📋 Reproducible Steps

1. Standard moOde Image installieren
2. SSH aktivieren: `touch /boot/firmware/ssh`
3. WLAN konfigurieren: `wpa_supplicant.conf` auf Boot-Partition
4. eth0 DHCP sicherstellen (keine statische IP)
5. NetworkManager-wait-online maskieren
6. config.txt Backup erstellen
7. Restore-Service aktivieren

