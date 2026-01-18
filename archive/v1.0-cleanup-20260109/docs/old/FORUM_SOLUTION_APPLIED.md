# Forum-Lösung angewendet: Waveshare 7.9" Display

**Quelle:** Moode Audio Forum Thread 6416  
**Link:** https://moodeaudio.org/forum/showthread.php?tid=6416  
**User:** popeye65

---

## Problem

- Nach Flashen funktioniert Display meistens
- **Nach Reboot ist Bild abgeschnitten und falsch orientiert**

---

## Lösung (Forum-Lösung)

### 1. cmdline.txt angepasst

**Für Pi 5:**
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

**Erklärung:**
- Display startet im **Portrait-Modus (400x1280)**
- Wird dann zu **Landscape (1280x400) rotiert**

### 2. .xinitrc muss angepasst werden (nach Boot)

**Hinzufügen vor xset Commands:**
```bash
DISPLAY=:0 xrandr --output HDMI-2 --rotate left
```

**SCREENSIZE Swap:**
```bash
# Original:
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $2","$3 }')"

# Geändert (Portrait → Landscape Swap):
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $3","$2 }')"
```

### 3. Moode Datenbank

**hdmi_scn_orient muss auf "landscape" sein:**
```sql
UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient';
```

---

## Script erstellt

**`/boot/firmware/fix-xinitrc-display.sh`** - Wird nach Boot ausgeführt

**Ausführen:**
```bash
sudo /boot/firmware/fix-xinitrc-display.sh
```

---

## Erwartetes Verhalten

1. ✅ Console scrollt Boot-Messages
2. ✅ GUI startet nach ca. 2 Minuten
3. ✅ Display zeigt 1280x400 Landscape
4. ✅ Touchscreen funktioniert

---

## Wichtig

- **Display startet Portrait (400x1280)** → wird dann zu Landscape rotiert
- **Moode hdmi_scn_orient** muss auf "landscape" stehen
- **.xinitrc** muss angepasst werden (Script erstellt)

