# BUILDROOT CONFIG.TXT ÜBERSCHREIBUNG PROBLEM

**Datum:** 02.12.2025  
**Problem:** config.txt wird beim Boot von detect-hifiberry Script überschrieben  
**System:** HiFiBerryOS (Buildroot)

---

## PROBLEM

### **detect-hifiberry Script:**
Das Script `/opt/hifiberry/bin/detect-hifiberry` läuft beim Boot und:
1. Entfernt alle `hifiberry` Overlay-Zeilen aus config.txt
2. Fügt nur `dtoverlay=hifiberry-$card` hinzu (OHNE Parameter wie `automute`)
3. Überschreibt die config.txt komplett

### **Code aus detect-hifiberry:**
```bash
cat $CONFIG | grep -v "hifiberry" > /tmp/config.txt 
echo "dtoverlay=hifiberry-$card" >> /tmp/config.txt
mv /tmp/config.txt $CONFIG
```

**Problem:** Alle Parameter wie `automute`, `24db_digital_gain`, etc. gehen verloren!

---

## LÖSUNG: FIX-CONFIG SERVICE

### **1. Fix-Config Script:**
Erstellt: `/opt/hifiberry/bin/fix-config.sh`

```bash
#!/bin/bash
# Fix config.txt after detect-hifiberry runs
CONFIG=/boot/config.txt

mount -o remount,rw /boot

# Füge automute zu hifiberry-dacplus hinzu
sed -i 's|dtoverlay=hifiberry-dacplus$|dtoverlay=hifiberry-dacplus,automute|' $CONFIG

# Stelle sicher dass display_rotate=3 gesetzt ist
if ! grep -q '^display_rotate=3' $CONFIG; then
    sed -i '/display_rotate/d' $CONFIG
    echo 'display_rotate=3' >> $CONFIG
fi

sync
mount -o ro,remount /boot
```

### **2. Systemd Service:**
Erstellt: `/etc/systemd/system/fix-config.service`

```ini
[Unit]
Description=Fix config.txt after detect-hifiberry
After=hifiberry-detect.service
Before=hifiberry-finish.service

[Service]
Type=oneshot
ExecStart=/opt/hifiberry/bin/fix-config.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

### **3. Aktivierung:**
```bash
systemctl enable fix-config.service
```

---

## SERVICE-ABHÄNGIGKEITEN

### **Boot-Sequenz:**
1. `hifiberry-detect.service` - Erkennt Hardware, überschreibt config.txt
2. **`fix-config.service`** - Korrigiert config.txt (fügt Parameter hinzu)
3. `hifiberry-finish.service` - Finalisierung

---

## PARAMETER DIE ERHALTEN BLEIBEN

### **Nach fix-config.service:**
- `dtoverlay=hifiberry-dacplus,automute` ✅
- `display_rotate=3` ✅
- Alle anderen Parameter bleiben erhalten

---

## ALTERNATIVE LÖSUNGEN

### **1. detect-hifiberry Script modifizieren:**
- Ändere `/opt/hifiberry/bin/detect-hifiberry`
- Problem: Wird bei Update überschrieben

### **2. Buildroot Overlay:**
- Erstelle custom Overlay
- Problem: Komplex, erfordert Rebuild

### **3. Post-Boot Script (AKTUELLE LÖSUNG):**
- fix-config.service läuft nach detect-hifiberry
- Vorteil: Überlebt Updates
- Vorteil: Einfach zu warten

---

## TROUBLESHOOTING

### **Falls Parameter immer noch fehlen:**
1. Prüfe fix-config.service Status: `systemctl status fix-config.service`
2. Prüfe Logs: `journalctl -u fix-config.service`
3. Prüfe config.txt: `cat /boot/config.txt | grep hifiberry`

### **Falls Service nicht läuft:**
```bash
systemctl enable fix-config.service
systemctl start fix-config.service
```

---

**Lösung implementiert und dokumentiert...**

