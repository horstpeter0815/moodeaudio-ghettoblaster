# Patch V4 - Proaktiver Ansatz

## Problem mit V1-V3:
- DSI-Connectors existieren noch nicht, wenn `vc4_fkms_bind` aufgerufen wird
- Panel-Module laden später
- Patch findet keine DSI-Connectors zum Zeitpunkt der Ausführung

## V4 Lösung: Proaktiver CRTC
- Erstellt IMMER einen CRTC für DSI (display_num 0 = MAIN_LCD)
- Prüft ob bereits ein CRTC für display_num 0 existiert
- Falls nicht, wird ein CRTC erstellt
- Dieser CRTC ist dann verfügbar, wenn Panel-Module ihre Connectors registrieren

## Code-Änderung:
```c
/* Always create CRTC for DSI (display_num 0) if it doesn't exist */
bool has_display_0 = false;
for (i = 0; i < num_displays; i++) {
    if (crtc_list[i] && crtc_list[i]->display_number == 0) {
        has_display_0 = true;
        break;
    }
}

if (!has_display_0) {
    /* Create CRTC for DSI */
    vc4_fkms_create_screen(dev, drm, num_displays, 0, &new_crtc_list[num_displays]);
}
```

## Vorteil:
- CRTC existiert bevor Panel-Module laden
- Encoder kann CRTC finden wenn Connector registriert wird
- Keine Timing-Probleme

---

**Status:** V4 kompiliert, installiert, Reboot durchgeführt

