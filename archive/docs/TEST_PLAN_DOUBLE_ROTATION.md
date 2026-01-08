# Test Plan: Double Rotation Hack

**Ziel:** Prüfen ob Double Rotation Hack das CRTC-Problem löst

---

## Test-Schritte

### 1. cmdline.txt ändern

**Von:**
```
video=DSI-1:1280x400@60
```

**Zu:**
```
video=DSI-1:400x1280M@60,rotate=90
```

**Bedeutung:**
- Display startet im Portrait-Mode (400x1280)
- 1280 Pixel Höhe beim Start
- 90° Rotation

---

### 2. xinitrc anpassen (optional, falls X11 läuft)

- DSI-Rotation-Code VOR `xset` verschieben
- Zweite Rotation für finale Orientierung

---

### 3. Reboot und prüfen

**Nach Reboot prüfen:**
1. Ist Display "enabled" statt "disabled"?
2. Wird ein CRTC zugewiesen?
3. Gibt es Bild auf dem Display?
4. dmesg: Gibt es noch `possible_crtcs=0x0` Fehler?

---

## Erwartete Ergebnisse

**Erfolg:**
- Display ist "enabled" ✅
- CRTC wird zugewiesen ✅
- Bild erscheint auf Display ✅

**Misserfolg:**
- Display bleibt "disabled" ❌
- Kein CRTC zugewiesen ❌
- Kein Bild ❌

---

**Status:** Bereit zum Testen wenn User zustimmt!

