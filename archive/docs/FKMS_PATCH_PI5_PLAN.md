# FKMS Patch Plan für Pi 5

## Kernel-Version:
- **Pi 5 #1:** 6.12.47+rpt-rpi-2712

## Patch-Strategie:

1. ✅ **vc4_firmware_kms.c finden** - `/lib/modules/6.12.47+rpt-rpi-2712/source` oder `/usr/src/linux-source-6.12.tar.xz`
2. ✅ **Patch anwenden** - Proaktiver CRTC für DSI (wie auf Pi 4)
3. ✅ **Modul kompilieren** - vc4_firmware_kms.ko
4. ✅ **Installieren** - Nach /lib/modules/.../kernel/drivers/gpu/drm/vc4/
5. ✅ **Testen** - Reboot und prüfen

## Patch-Code (V4 Proaktiv):

```c
/*
 * WORKAROUND: Always create a CRTC for DSI (display_num 0 = MAIN_LCD) if it doesn't exist.
 * This ensures that DSI connectors created by panel drivers (like panel-waveshare-dsi)
 * will have a CRTC available, even if the firmware doesn't report DSI displays.
 */
{
    bool has_display_0 = false;
    int i;

    /* Check if we already have a CRTC for display_num 0 */
    for (i = 0; i < num_displays; i++) {
        if (crtc_list[i] && crtc_list[i]->display_number == 0) {
            has_display_0 = true;
            break;
        }
    }

    if (!has_display_0) {
        // Create CRTC for DSI...
    }
}
```

## Nächste Schritte:

1. ⏳ Kernel-Source finden
2. ⏳ Patch anwenden
3. ⏳ Kompilieren
4. ⏳ Installieren

---

**Status:** Plan erstellt, bereit für Patch-Installation...

