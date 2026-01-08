# Boot Display Fix - Hide Prompts & Rotate Screen

**Date:** 2025-12-25  
**Status:** ✅ Konfiguriert, Reboot erforderlich

---

## ✅ Changes Applied

### 1. Hide Boot Prompts

**config.txt:**
```ini
disable_splash=1
```

**cmdline.txt:**
```
console=null
```

**Result:** Raspberry Pi Logo und Boot-Prompts werden nicht angezeigt

---

### 1b. Matrix Boot Screen (Matrix Rain)

In dieser Custom-Build gibt es einen Boot-Screen als Systemd-Service:

- Service: `/lib/systemd/system/matrix-boot.service`
- Script: `/usr/local/bin/matrix-boot.sh`
- Ausgabe: `tty1` (Framebuffer-Konsole)

**Enable/Disable (auf dem Pi):**

```bash
sudo systemctl enable --now matrix-boot.service
# oder
sudo systemctl disable --now matrix-boot.service
```

**Hinweis zu `console=null`:** Das versteckt Kernel-Boot-Prompts. Der Matrix-Screen schreibt aber direkt nach `tty1`. Falls trotzdem nur schwarz bleibt: `console=tty1` in `cmdline.txt` sicherstellen bzw. `console=null` entfernen.

---

### 2. Rotate Boot Screen

**cmdline.txt:**
```
fbcon=rotate:1
```

**Rotation Options:**
- `fbcon=rotate:0` = 0° (normal)
- `fbcon=rotate:1` = 90° (clockwise)
- `fbcon=rotate:2` = 180°
- `fbcon=rotate:3` = 270° (counter-clockwise)

**⚠️ Note:** Framebuffer unterstützt nur 90° Schritte. 45° ist nicht direkt möglich.

**Für 45° Rotation:**
- Müsste über X11 Transformation erfolgen
- Oder `display_rotate` verwenden (rotiert auch X11)

---

## 📋 Current Configuration

### config.txt
```ini
[all]
disable_splash=1
```

### cmdline.txt
```
... console=null fbcon=rotate:1 ...
```

---

## 🧪 Testing After Reboot

### Check Boot Display:
1. **Boot-Prompts:** Sollten nicht sichtbar sein
2. **Framebuffer Rotation:** Sollte rotiert sein (90°)
3. **X11 Display:** Sollte weiterhin funktionieren

### Verify Settings:
```bash
# Framebuffer Rotation
cat /sys/class/graphics/fbcon/rotate

# Boot Settings
grep disable_splash /boot/firmware/config.txt
grep -E 'console=|fbcon=' /boot/firmware/cmdline.txt
```

---

## ⚠️ Important Notes

1. **45° Rotation:** Nicht direkt möglich mit fbcon
   - Aktuell: 90° (fbcon=rotate:1)
   - Alternative: X11 Transformation (rotiert nur X11, nicht Boot)

2. **Display Compatibility:**
   - Framebuffer Rotation sollte X11 nicht beeinflussen
   - X11 verwendet eigene Rotation (xrandr)

3. **After Reboot:**
   - Boot-Screen sollte rotiert sein
   - X11 Display sollte weiterhin funktionieren
   - moOde Web-UI sollte weiterhin funktionieren

---

## 🔄 Rollback

Falls Probleme auftreten:

```bash
# Restore backups
sudo cp /boot/firmware/config.txt.backup_boot_* /boot/firmware/config.txt
sudo cp /boot/firmware/cmdline.txt.backup_boot_* /boot/firmware/cmdline.txt
sudo reboot
```

---

**Status:** ✅ Konfiguriert, Reboot erforderlich für Test

