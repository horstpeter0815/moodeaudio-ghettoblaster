# FKMS DSI Support Research - Task 1

**Date:** 2025-11-26 00:45 CET  
**Status:** IN PROGRESS

---

## Research Questions

1. Unterstützt fkms DSI überhaupt?
2. Gibt es bekannte fkms + DSI Probleme?
3. Wie funktioniert fkms CRTC-Erstellung?

---

## Key Findings

### Finding 1: fkms kennt DSI theoretisch

**Source:** `vc4_firmware_kms.c:348`

```c
static u32 vc4_get_display_type(u32 display_number)
{
    static const u32 display_types[] = {
        DRM_MODE_ENCODER_NONE,	/* MAIN_LCD - DSI or DPI */
        DRM_MODE_ENCODER_DSI,	/* MAIN_LCD - DSI or DPI */
        DRM_MODE_ENCODER_DSI,	/* AUX_LCD */
        ...
    };
    return display_types[display_number];
}
```

**Erkenntnis:** fkms hat DSI-Encoder-Typen definiert!

---

### Finding 2: fkms erstellt DSI-Connector

**Source:** `vc4_firmware_kms.c:1754-1759`

```c
if (fkms_connector->display_type == DRM_MODE_ENCODER_DSI) {
    drm_connector_init(dev, connector, &vc4_fkms_connector_funcs,
                       DRM_MODE_CONNECTOR_DSI);
    drm_connector_helper_add(connector,
                             &vc4_fkms_lcd_conn_helper_funcs);
    connector->interlace_allowed = 0;
}
```

**Erkenntnis:** fkms kann DSI-Connector erstellen!

---

### Finding 3: CRTC-Erstellung hängt von Firmware ab

**Source:** `vc4_firmware_kms.c:1961-2000`

```c
ret = rpi_firmware_property(vc4->firmware,
                            RPI_FIRMWARE_FRAMEBUFFER_GET_NUM_DISPLAYS,
                            &num_displays, sizeof(u32));

for (display_num = 0; display_num < num_displays; display_num++) {
    display_id = display_num;
    ret = rpi_firmware_property(vc4->firmware,
                                RPI_FIRMWARE_FRAMEBUFFER_GET_DISPLAY_ID,
                                &display_id, sizeof(display_id));
    // ...
    vc4_fkms_create_screen(dev, drm, display_num, display_id, &crtc_list[display_num]);
}
```

**KRITISCH:** fkms fragt die **Firmware** nach Displays, nicht den Kernel!

**Problem:** Wenn die Firmware DSI nicht meldet, wird kein CRTC erstellt!

---

### Finding 4: CRTC-Validierung nur für HDMI

**Source:** `vc4_firmware_kms.c:1141-1152`

```c
switch (vc4_fkms_crtc->display_number) {
case 2:	/* HDMI0 */
    if (fkms->cfg.max_pixel_clock[0] &&
        mode->clock > fkms->cfg.max_pixel_clock[0])
        return MODE_CLOCK_HIGH;
    break;
case 7:	/* HDMI1 */
    if (fkms->cfg.max_pixel_clock[1] &&
        mode->clock > fkms->cfg.max_pixel_clock[1])
        return MODE_CLOCK_HIGH;
    break;
}
```

**Erkenntnis:** CRTC-Validierung nur für HDMI (display_number 2 und 7), NICHT für DSI!

---

### Finding 5: Display Number Mapping

**Source:** `vc4_firmware_kms.c:342-359`

```c
static u32 vc4_get_display_type(u32 display_number)
{
    static const u32 display_types[] = {
        DRM_MODE_ENCODER_NONE,	/* 0 */
        DRM_MODE_ENCODER_DSI,	/* 1 - MAIN_LCD */
        DRM_MODE_ENCODER_DSI,	/* 2 - AUX_LCD */
        ...
    };
}
```

**Erkenntnis:** 
- Display 1 = MAIN_LCD (DSI)
- Display 2 = HDMI0
- Display 7 = HDMI1

**Aber:** Die Firmware muss diese Displays melden!

---

## Root Cause Hypothesis

**Problem:** fkms erstellt CRTCs nur für Displays, die die **Firmware** meldet.

**Warum kein CRTC für DSI:**
1. fkms fragt Firmware: `RPI_FIRMWARE_FRAMEBUFFER_GET_NUM_DISPLAYS`
2. Firmware meldet nur HDMI-Displays (wenn HDMI aktiv)
3. DSI wird nicht gemeldet, weil:
   - Firmware erkennt DSI nicht automatisch
   - Oder: DSI wird erst nach Firmware-Initialisierung erkannt
   - Oder: Firmware braucht spezielle Konfiguration für DSI

**"Bogus possible_crtcs: possible_crtcs=0x0"** bedeutet:
- Encoder wurde erstellt (von Panel-Driver)
- Aber kein CRTC wurde zugewiesen
- Weil fkms keinen CRTC für DSI erstellt hat

---

## Web Search Findings

**Finding:** FKMS wird als veraltet markiert in neueren Raspberry Pi OS Versionen

**Source:** Raspberry Pi Dokumentation
- Bookworm unterstützt FKMS nicht mehr
- FKMS ist Legacy-Grafikstack

**Finding:** Einige User berichten, dass FKMS DSI-Displays wiederherstellt

**Source:** LibreELEC Forum
- Wechsel von KMS zu FKMS hat Display funktionsfähig gemacht
- Aber: In neueren Versionen funktioniert das nicht mehr

---

## Next Steps

1. **Prüfe Firmware-Display-Liste:** Welche Displays meldet die Firmware?
2. **Prüfe ob DSI in Firmware erkannt wird:** Device Tree prüfen
3. **Vergleiche mit echtem KMS:** Warum funktioniert echtes KMS nicht?

---

## Conclusion

**fkms unterstützt DSI theoretisch**, aber:
- CRTC-Erstellung hängt von Firmware ab
- Firmware muss DSI als Display melden
- Wenn Firmware DSI nicht meldet → kein CRTC → "Bogus possible_crtcs"

**Mögliche Lösung:**
- Firmware-Konfiguration anpassen
- Oder: Echtes KMS verwenden (aber das funktioniert auch nicht bei uns)

---

**Status:** Research continues... Next: Prüfe welche Displays die Firmware meldet

