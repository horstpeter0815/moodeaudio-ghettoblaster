# Forum Solution: Waveshare 7.9" Display für Moode 9

**Quelle:** Moode Audio Forum Thread 6416  
**User:** popeye65  
**Datum:** 04-21-2024  
**Link:** https://moodeaudio.org/forum/showthread.php?tid=6416

---

## Hardware

- Raspberry Pi 4b
- Waveshare 7.9" HDMI Capacitive Touch Screen
- Moode 9 (getestet auf ~pre4)

---

## Lösung - Schritt für Schritt

### Schritt 1: Setup PI Image, SSH aktivieren

✅ Standard Moode Installation mit SSH-Zugriff

---

### Schritt 2: cmdline.txt anpassen

**Datei:** `/boot/firmware/cmdline.txt`

**Hinzufügen am Ende der Zeile:**
```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Vollständige Zeile sollte so aussehen:**
```
console=serial0,115200 console=tty1 root=PARTUUID=92517673-02 rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-1:400x1280M@60,rotate=90
```

**Wichtig:** 
- `HDMI-A-1` für Pi 4
- `HDMI-A-2` für Pi 5
- `400x1280M@60,rotate=90` - Display startet im Portrait-Modus

---

### Schritt 3: .xinitrc anpassen

**Datei:** `/home/[USER]/.xinitrc` (nicht `/home/pi/.xinitrc` - User kann anders sein!)

**Vor den "xset" Commands hinzufügen:**
```bash
DISPLAY=:0 xrandr --output HDMI-1 --rotate left
```

**In der SCREENSIZE-Zeile: $2 und $3 tauschen**

**Original:**
```bash
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $2","$3 }')"
```

**Geändert:**
```bash
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $3","$2 }')"
```

**Ergebnis:** `400,1280` statt `1280,400` (Portrait → Landscape Swap)

---

### Schritt 4: Reboot

```bash
sudo reboot
```

---

## Erwartetes Verhalten

1. ✅ Console scrollt Boot-Messages
2. ✅ GUI startet nach ca. 2 Minuten (X11 + Chromium Loading)
3. ✅ Display zeigt 1280x400 Landscape
4. ✅ Touchscreen funktioniert

---

## Touchscreen

**Hinweis vom Forum:**
> "The touch screen worked out of the box. However, you may need to press the 'Rotate Touch' button a few times until it works correctly. The display modules saves the rotation setting internally."

---

## Wichtige Punkte

1. **Display startet Portrait (400x1280)** → wird dann zu Landscape rotiert
2. **SCREENSIZE Swap** ist notwendig für korrekte Chromium-Größe
3. **xrandr Rotation** erfolgt VOR xset Commands
4. **User-Verzeichnis beachten:** Nicht `/home/pi/` sondern `/home/[USER]/`

---

## Für Pi 5 Anpassungen

- `HDMI-A-1` → `HDMI-A-2` in cmdline.txt
- `HDMI-1` → `HDMI-2` in xinitrc (oder entsprechend dem tatsächlichen Output)

---

**Status:** ✅ Forum-Lösung dokumentiert - funktioniert für Waveshare 7.9" Display

