# Forum Steps - Implementation Guide

**Quelle:** https://moodeaudio.org/forum/showthread.php?tid=6416  
**User:** popeye65  
**Display:** Waveshare 7.9" HDMI Capacitive Touch Screen (400x1280 rotated)

---

## Schritte aus dem Forum

### Schritt 1: Setup PI image, get ssh working
✅ Bereits erledigt

### Schritt 2: Adapt /boot/firmware/cmdline.txt

**Hinzufügen:**
```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Für unser DSI Display:**
```
video=DSI-1:1280x400M@60,rotate=90
```

---

### Schritt 3: Adapt /home/[USER]/.xinitrc

**User sagt:** Die Schritte sind im Forum beschrieben - "400 480 minimum pixel height"

**Aus dem Forum (popeye65):**
- Vor den "xset" Commands:
```bash
DISPLAY=:0 xrandr --output HDMI-1 --rotate left
```

- In der "SCREENSIZE=" Zeile, swap $2 und $3:
```bash
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $3","$2 }')"
```

**Für unser DSI Display (1280x400):**
```bash
# Vor xset Commands
DISPLAY=:0 xrandr --output DSI-1 --rotate left

# SCREENSIZE Swap
SCREENSIZE="$(fbset -s | awk '$1 == "geometry" { print $3","$2 }')"
# Ergebnis: 400,1280 statt 1280,400
```

---

## "400 480 minimum pixel height" Hack

**User-Hinweis:** "480" - möglicherweise gibt es einen Hack für 480 Pixel Minimum!

**Möglicher Hack:**
1. Display ist 400 Pixel hoch (1280x400)
2. Kernel erwartet möglicherweise 480 Pixel Minimum
3. xinitrc-Hack muss 480 Pixel erzwingen oder als Minimum setzen

**Zu prüfen:**
- Gibt es eine xinitrc-Zeile die "480" oder "minimum pixel height" enthält?
- Muss das Display als 1280x480 gemeldet werden statt 1280x400?
- Oder gibt es einen speziellen Parameter für 480p-Modus?

---

## Nächste Schritte

1. **Prüfe Forum-Thread nochmal genau** nach allen Code-Blöcken
2. **Suche nach "480" oder "minimum"** im Thread
3. **Implementiere die xinitrc-Änderungen** wenn gefunden
4. **Teste mit X11** ob das Display dann funktioniert

---

**Status:** Warte auf weitere Details vom User über den exakten "480" Hack!

