# VOLUME PROBLEM - LÖSUNG

**Datum:** 03.12.2025  
**Problem:** Volume bleibt auf 100% statt 50%  
**Status:** ✅ Lösung implementiert

---

## 🔍 PROBLEM

### **Symptome:**
- Volume ist auf 100% (255) statt 50% (128)
- set-volume.service läuft, aber Volume wird nicht gesetzt
- Möglicherweise wird Volume nach set-volume wieder zurückgesetzt

### **Ursache:**
- set-volume.service läuft zu früh (vor restore-volume.service)
- restore-volume.service setzt Volume auf gespeicherten Wert zurück
- Timing-Problem: set-volume läuft vor restore-volume

---

## ✅ LÖSUNG

### **Verbesserter set-volume.service:**

```ini
[Unit]
Description=Set Audio Volume to 50%
After=sound.target
After=restore-volume.service  ← WICHTIG: Nach restore-volume!
Wants=sound.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2     ← Warte 2 Sekunden
ExecStart=/bin/bash -c 'amixer -c 0 set DSPVolume 50% && alsactl store'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### **Änderungen:**
1. ✅ `After=restore-volume.service` - Läuft NACH restore-volume
2. ✅ `ExecStartPre=/bin/sleep 2` - Warte 2 Sekunden
3. ✅ `alsactl store` - Speichere neuen Wert

---

## 📝 BOOT SEQUENZ

```
1. sound.target (Audio-System bereit)
2. restore-volume.service (Lädt gespeichertes Volume)
3. set-volume.service (Setzt auf 50% - NACH restore-volume!)
```

---

## 🎯 ERWARTUNG

Nach Reboot:
- ✅ restore-volume lädt gespeichertes Volume
- ✅ set-volume setzt auf 50% (NACH restore-volume)
- ✅ Volume bleibt auf 50%

---

**Status:** ✅ Implementiert - Bereit für Test

