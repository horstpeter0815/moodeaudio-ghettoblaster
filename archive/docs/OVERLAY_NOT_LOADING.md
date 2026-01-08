# Device Tree Overlay wird nicht geladen

## Problem:

- ❌ Panel-Modul wird nicht automatisch geladen
- ❌ DSI-1 nicht sichtbar
- ❌ Kein Framebuffer
- ⚠️ Device Tree Overlay möglicherweise nicht geladen

## Mögliche Ursachen:

1. **Overlay-Reihenfolge in config.txt falsch?**
2. **Overlay-Datei korrupt?**
3. **DSI Hardware nicht erkannt?**
4. **Pi 5 vs Pi 4 Unterschiede?**

## Prüfe:

- dmesg für Overlay-Fehler
- Ob Overlay in chosen/overlays ist
- Ob Device Tree Node existiert
- Ob manuelles Modul-Laden hilft

---

**Status:** Prüfe warum Overlay nicht geladen wird...

