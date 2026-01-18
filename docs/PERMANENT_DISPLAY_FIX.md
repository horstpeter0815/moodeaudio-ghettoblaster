# 🔧 Permanent Display Fix - Ein für alle Mal

**Problem:** Display zeigt immer wieder schwarzen Login-Bildschirm statt moOde Web-UI  
**Ursache:** Konflikt zwischen Framebuffer-Console (fbcon) und X-Server um DRM-Master  
**Lösung:** Dauerhafte Konfiguration, die beide gleichzeitig erlaubt

---

## 🎯 Die Echte Lösung

### Option 1: KMS Mode (Empfohlen)

**KMS (Kernel Mode Setting)** erlaubt X-Server und Framebuffer gleichzeitig.

#### Auf SD-Karte konfigurieren:

1. **`/boot/firmware/config.txt`:**
   ```ini
   [pi5]
   dtoverlay=vc4-kms-v3d-pi5,noaudio
   hdmi_enable_4kp60=0
   
   [all]
   disable_overscan=1
   hdmi_group=2
   hdmi_mode=87
   hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
   hdmi_drive=2
   hdmi_blanking=0
   hdmi_force_hotplug=1
   ```

2. **`/boot/firmware/cmdline.txt`:**
   ```
   console=serial0,115200 console=tty1 root=PARTUUID=... rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE video=HDMI-A-2:400x1280M@60,rotate=90
   ```
   
   **WICHTIG:** `fbcon=rotate:1` WEGLASSEN wenn KMS aktiv ist!

#### Warum das funktioniert:
- KMS gibt X-Server direkten Zugriff auf Display
- Framebuffer läuft über KMS, nicht direkt
- Kein DRM-Master-Konflikt

---

### Option 2: Framebuffer komplett deaktivieren

Wenn KMS nicht funktioniert:

1. **`/boot/firmware/cmdline.txt`:**
   ```
   console=serial0,115200 console=tty1 root=... video=HDMI-A-2:400x1280M@60,rotate=90
   ```
   
   **Entfernen:**
   - `fbcon=rotate:1`
   - Alle `fbcon` Parameter

2. **Boot-Messages werden nicht rotiert sein** (aber X-Server funktioniert)

---

### Option 3: X-Server als Display Manager

Statt localdisplay.service einen echten Display Manager verwenden:

1. **Installiere lightdm (wenn nicht vorhanden):**
   ```bash
   sudo apt install lightdm
   ```

2. **Konfiguriere lightdm für automatischen Login:**
   ```bash
   sudo nano /etc/lightdm/lightdm.conf
   ```
   
   ```
   [Seat:*]
   autologin-user=andre
   autologin-session=xfce
   ```

3. **Starte Chromium in .xinitrc:**
   ```bash
   # ~/.xinitrc
   #!/bin/bash
   DISPLAY=:0 /usr/local/bin/start-chromium-clean.sh
   ```

---

## 🔍 Diagnose: Was ist das Problem?

### Symptome:
- ✅ Chromium läuft (`pgrep -f chromium`)
- ✅ Web-Server läuft (`curl http://localhost/`)
- ❌ X-Server startet nicht (`ps aux | grep Xorg`)
- ❌ Display zeigt schwarzen Bildschirm

### Root Cause Check:
```bash
# Prüfe X-Server Logs
tail -50 /var/log/Xorg.0.log | grep -i "drm\|master\|busy"

# Prüfe DRM Status
ls -la /dev/dri/
lsof /dev/dri/*

# Prüfe Framebuffer
cat /sys/class/graphics/fb0/name
```

**Wenn du siehst:**
- `drmSetMaster failed: Device or resource busy` → DRM-Konflikt
- `AddScreen/ScreenInit failed` → Display-Treiber-Problem

---

## ✅ Dauerhafte Lösung Implementieren

### Schritt 1: SD-Karte mounten (Mac)

```bash
# SD-Karte sollte erscheinen als:
# - /Volumes/bootfs
# - /Volumes/rootfs
```

### Schritt 2: config.txt prüfen/anpassen

```bash
# Prüfe ob KMS aktiv ist
grep "vc4-kms" /Volumes/bootfs/config.txt

# Falls nicht, hinzufügen:
# [pi5]
# dtoverlay=vc4-kms-v3d-pi5,noaudio
```

### Schritt 3: cmdline.txt anpassen

```bash
# Aktuell (PROBLEM):
# ... video=... fbcon=rotate:1

# Neu (LÖSUNG):
# ... video=... 
# (fbcon=rotate:1 ENTFERNEN wenn KMS aktiv)
```

### Schritt 4: localdisplay.service prüfen

```bash
# Auf SD-Karte:
cat /Volumes/rootfs/lib/systemd/system/localdisplay.service

# Sollte enthalten:
# - Wants=graphical.target
# - After=graphical.target
# - ExecStartPre=/usr/local/bin/xserver-ready.sh
```

---

## 🚫 Was NICHT mehr machen

1. ❌ **Nicht:** `fbcon=rotate:1` hinzufügen wenn KMS aktiv
2. ❌ **Nicht:** X-Server manuell starten (sollte über Service laufen)
3. ❌ **Nicht:** Login-Manager aktivieren (blockiert Chromium)
4. ❌ **Nicht:** Framebuffer und X-Server gleichzeitig ohne KMS

---

## ✅ Was IMMER machen

1. ✅ **KMS aktivieren** in config.txt
2. ✅ **fbcon nur wenn nötig** (und nur wenn kein KMS)
3. ✅ **localdisplay.service** für automatischen Start verwenden
4. ✅ **Nach Änderungen:** Reboot, nicht nur Service-Restart

---

## 📋 Checkliste für dauerhafte Lösung

- [ ] KMS aktiv in config.txt (`dtoverlay=vc4-kms-v3d-pi5`)
- [ ] cmdline.txt: `fbcon=rotate:1` entfernt (wenn KMS aktiv)
- [ ] cmdline.txt: `video=...rotate=90` vorhanden (für Display-Rotation)
- [ ] localdisplay.service enabled
- [ ] Login-Manager deaktiviert
- [ ] Nach Änderungen: Reboot, nicht nur Service-Restart

---

## 🔄 Wenn es IMMER NOCH nicht funktioniert

1. **Prüfe Build-System:**
   - Werden diese Einstellungen beim Build überschrieben?
   - Gibt es Stage-Scripts die cmdline.txt ändern?

2. **Prüfe Boot-Prozess:**
   - Was passiert beim Boot?
   - Welche Services starten zuerst?

3. **Alternative:**
   - PeppyMeter statt Web-UI verwenden?
   - Headless-Mode (kein Display)?

---

## 💡 Die Wahrheit

**Das Problem:** Wir fixen Symptome, nicht die Ursache.

**Die Ursache:** Framebuffer und X-Server wollen beide den Display, aber nur einer kann ihn haben.

**Die Lösung:** KMS erlaubt beiden Zugriff, oder wir entscheiden uns für einen (X-Server) und deaktivieren den anderen (Framebuffer).

**Warum passiert es immer wieder?**
- Build-System überschreibt vielleicht cmdline.txt?
- Updates ändern Konfiguration?
- Wir fixen es manuell, aber nicht im Build-System?

---

**Nächster Schritt:** Diese Lösung ins Build-System integrieren, damit sie bei jedem Build automatisch angewendet wird.

---

**Last Updated:** 2025-01-12  
**Status:** Dauerhafte Lösung dokumentiert - muss ins Build-System integriert werden
