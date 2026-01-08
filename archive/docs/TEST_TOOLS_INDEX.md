# Test Tools Index

Sammlung von Test-Tools und Hacks für das Waveshare 7.9" DSI Display Projekt.

---

## Double Rotation Hack

**Datei:** `TEST_TOOL_DOUBLE_ROTATION_HACK.sh`

**Zweck:** Display mit 1280 Pixel Höhe initialisieren (Portrait-Mode) durch doppelte Rotation

**Schritte:**
1. `cmdline.txt`: `video=DSI-1:400x1280M@60,rotate=90` (Display startet im Portrait)
2. `xinitrc`: DSI-Rotation-Code VOR `xset` verschieben (zweite Rotation)

**Warum:**
- Display startet mit 1280 Pixel Höhe (statt 400)
- Löst mögliche "minimum pixel height" Probleme
- Wird dann für Anwendung korrekt orientiert

**Quelle:** Moode Audio Forum Thread 6416 (popeye65)

**Status:** ✅ Dokumentiert - NICHT implementiert

---

## Andere Test Tools

*(Weitere Tools hier hinzufügen...)*

---

**WICHTIG:** Diese Tools sind nur zur Dokumentation und zum Testen - nicht automatisch implementieren!

