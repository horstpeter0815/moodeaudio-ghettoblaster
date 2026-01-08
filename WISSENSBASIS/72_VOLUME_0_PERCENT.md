# VOLUME AUF 0% GESETZT

**Datum:** 03.12.2025  
**Status:** ✅ Volume auf 0% gesetzt

---

## ✅ KONFIGURATION

### **Aktuelles Volume:**
- **DSPVolume:** 0% (0/255)

### **set-volume.service:**
```ini
[Unit]
Description=Set Audio Volume to 0%
After=sound.target
After=restore-volume.service
Wants=sound.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2
ExecStart=/bin/bash -c 'amixer -c 0 set DSPVolume 0% && alsactl store'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

---

## 🎯 ERGEBNIS

- ✅ Volume ist auf 0% (stumm)
- ✅ Service setzt beim Boot automatisch auf 0%
- ✅ Volume wird in /etc/alsactl.store gespeichert

---

**Status:** ✅ Abgeschlossen

