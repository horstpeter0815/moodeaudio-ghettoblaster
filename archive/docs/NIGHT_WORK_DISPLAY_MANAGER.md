# Nacht-Arbeit: Display Manager & FKMS Patch

## Installiert

✅ **LightDM** - Display Manager
✅ **X11 Tools** - xrandr, xset, etc.
✅ **Kernel Headers** - Für Module-Kompilierung

## Problem bleibt

❌ **CRTC fehlt** - DSI-1 hat keinen CRTC
❌ **modetest schlägt fehl** - Kann /dev/dri/card1 nicht öffnen
❌ **Display disabled** - Kein Bild

## Lösung: FKMS Patch kompilieren

### Schritt 1: Kernel Source klonen
- Repository: `rpi-6.12.y` Branch
- Ziel: `/tmp/kernel-source`

### Schritt 2: Patch anwenden
- Datei: `drivers/gpu/drm/vc4/vc4_firmware_kms.c`
- Patch: Proaktiver CRTC für DSI (display_num 0)
- Position: Nach Zeile 2011

### Schritt 3: Modul kompilieren
```bash
cd /tmp/kernel-source/drivers/gpu/drm/vc4
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
```

### Schritt 4: Modul installieren
```bash
sudo cp vc4_firmware_kms.ko /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/vc4/
sudo depmod -a
sudo modprobe -r vc4_firmware_kms
sudo modprobe vc4_firmware_kms
```

---

**Status:** Patch wird kompiliert...

