# Dual Approach Plan

## Strategie:

### Pi 5 #1 (192.168.178.134):
- ✅ **FKMS Patch installieren**
- ✅ Behebt CRTC-Problem auf Kernel-Ebene
- ✅ Vollständige Hardware-Beschleunigung

### Pi 5 #2 (192.168.178.123):
- ✅ **Display Manager installieren**
- ✅ Liest Framebuffer direkt aus (`/dev/fb0`)
- ✅ Umgeht CRTC-Problem
- ✅ Einfacher, keine Kernel-Patches nötig

## Display Manager Optionen:

1. **fbi (Framebuffer Imageviewer)**
   - Zeigt Bilder direkt auf Framebuffer
   - Einfach zu installieren

2. **DirectFB**
   - Direkter Framebuffer-Zugriff
   - Hardware-Beschleunigung möglich

3. **Python + pygame**
   - Bereits getestet, funktioniert
   - Kann kontinuierlich laufen

4. **fbset + dd**
   - Direkter Framebuffer-Schreibzugriff
   - Sehr einfach

5. **X11 mit fbdev Driver**
   - Bereits getestet
   - Funktioniert aber braucht CRTC

## Nächste Schritte:

1. Pi 5 #1: FKMS Patch installieren
2. Pi 5 #2: Display Manager installieren und testen
3. Beide vergleichen

---

**Status:** Dual Approach geplant...

