# Komplette System-Dokumentation

## Übersicht

### System 1: Ghetto Pi 5 (Moode Audio)
- **IP:** 192.168.178.178
- **OS:** Moode Audio
- **Display:** Waveshare 7.9" HDMI (1280x400)
- **Status:** Fast perfekt, Rotation muss gefixt werden

### System 2: RaspiOS Full
- **IP:** 192.168.178.143
- **OS:** Raspberry Pi OS Full
- **Display:** Waveshare 7.9" HDMI (1280x400)
- **Status:** Funktioniert perfekt (Referenz-System)

### System 3: HiFiBerryOS (wird zu Moode Audio)
- **IP:** Wird gesucht
- **OS:** HiFiBerryOS → Moode Audio
- **Status:** Wird vorbereitet

---

## Display-Konfiguration

### Fallback-Lösung (funktioniert fast perfekt)

#### config.txt - [pi5] Sektion
```ini
[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_mode=87
hdmi_group=2
```

#### cmdline.txt
```
console=serial0,115200 console=tty1 root=PARTUUID=738a4d67-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles
```

#### xinitrc
```bash
xrandr --output HDMI-A-2 --mode 1280x400 --rotate right
chromium-browser --kiosk --window-size=1280,400 http://localhost
```

#### Touchscreen Config
```
Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
```

---

## Scripts

### Rotation & Display
- `FIX_ROTATION.sh` - Behebt Rotation-Problem
- `STUDY_FALLBACK_CONFIG.sh` - Studiert aktuelle Config
- `CLEANUP_HDMI_CONFIGS.sh` - Löscht Backup-Configs

### System
- `CLEANUP_SYSTEM.sh` - Räumt System auf
- `EXECUTE_NIGHT_WORK.sh` - Führt alle Arbeiten aus

### HiFiBerryOS
- `FIND_HIFIBERRYOS.sh` - Findet HiFiBerryOS im Netzwerk
- `HIFIBERRYOS_TO_MOODE.sh` - Fährt HiFiBerryOS herunter

---

## Bekannte Probleme & Lösungen

### Problem: Rotation funktioniert nicht
**Lösung:** 
- xinitrc Rotation-Befehl prüfen
- Touchscreen Matrix anpassen
- Reihenfolge: Modus setzen → Rotation anwenden → Framebuffer setzen

### Problem: Display flackert
**Lösung:**
- Keine custom hdmi_timings verwenden
- EDID-Modus verwenden
- disable_fw_kms_setup=1 setzen

### Problem: Touchscreen Koordinaten falsch
**Lösung:**
- TransformationMatrix für Rotation anpassen
- Device-ID prüfen: `xinput list`
- Manuell testen: `xinput test <device-id>`

---

## Nächste Schritte

1. ✅ Rotation beheben
2. ✅ System aufräumen
3. ⏳ HiFiBerryOS finden und herunterfahren
4. ⏳ Moode Audio installieren
5. ⏳ Peppy Meter installieren
6. ⏳ Finale Dokumentation

---

## Wichtige Erkenntnisse

1. **Moode Audio verwendet `/boot/firmware/` statt `/boot/`**
2. **Keine custom hdmi_timings verwenden (verursacht Flackern)**
3. **Rotation via xrandr ist stabiler als Boot-Parameter**
4. **Touchscreen Matrix muss zur Rotation passen**
5. **RaspiOS Full ist perfekte Referenz für saubere Lösung**

---

## Dokumentation

- `FALLBACK_SOLUTION.md` - Fallback-Lösung (fast perfekt)
- `STABLE_HDMI_SOLUTION_PLAN.md` - Plan für saubere Lösung
- `ROTATION_FIX_DETAILED.md` - Detaillierte Rotation-Anleitung
- `MOODE_AUDIO_INSTALLATION_PLAN.md` - Moode Audio Installation
- `NIGHT_WORK_PLAN.md` - Nacht-Arbeit Plan

---

**Letzte Aktualisierung:** $(date)

