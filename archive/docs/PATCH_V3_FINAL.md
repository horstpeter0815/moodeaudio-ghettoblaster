# Patch V3 - Final Version mit Encoder-Zuweisung

## Verbesserungen in V3:

1. **CRTC wird erstellt** für DSI-Connector ohne CRTC
2. **Encoder-Zuweisung:** Nach CRTC-Erstellung wird der DSI-Encoder gefunden und der CRTC explizit zugewiesen
3. **possible_crtcs wird gesetzt:** `dsi_encoder->possible_crtcs |= drm_crtc_mask(&dsi_crtc->base)`

## Code-Änderung:
```c
/* After creating CRTC, find DSI encoder and assign CRTC */
drm_connector_list_iter_begin(drm, &conn_iter);
drm_for_each_connector_iter(connector, &conn_iter) {
    if (connector->connector_type == DRM_MODE_CONNECTOR_DSI) {
        dsi_encoder = connector->encoder;
        if (dsi_encoder) {
            dsi_encoder->possible_crtcs |= drm_crtc_mask(&dsi_crtc->base);
            break;
        }
    }
}
drm_connector_list_iter_end(&conn_iter);
```

## Erwartetes Ergebnis:

- "Found DSI connector without CRTC, creating one..."
- "Assigned CRTC to DSI encoder, possible_crtcs=0x..."
- "Successfully created CRTC for DSI display"
- KEINE "Bogus possible_crtcs" Fehler mehr
- Display sollte "enabled" sein

---

**Status:** V3 kompiliert, installiert, Reboot durchgeführt - warte auf Ergebnis

