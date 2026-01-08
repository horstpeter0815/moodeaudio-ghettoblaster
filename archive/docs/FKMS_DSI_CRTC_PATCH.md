# FKMS DSI CRTC Patch

## Problem
FKMS erstellt nur CRTCs für Displays, die die Firmware meldet. Wenn die Firmware DSI nicht meldet (was bei Waveshare-Panels der Fall ist), wird kein CRTC erstellt, obwohl ein DSI-Connector existiert.

## Lösung
Patch für `vc4_firmware_kms.c`, der nach dem Erstellen der Firmware-CRTCs prüft, ob es DSI-Connectors ohne CRTC gibt, und für diese einen zusätzlichen CRTC erstellt.

## Patch Details
- **Datei:** `drivers/gpu/drm/vc4/vc4_firmware_kms.c`
- **Funktion:** `vc4_fkms_bind()`
- **Position:** Nach Zeile 2032 (nach dem Erstellen der Firmware-CRTCs)

## Was der Patch macht:
1. Iteriert durch alle DRM-Connectors
2. Prüft, ob es DSI-Connectors gibt
3. Prüft, ob diese Connectors einen Encoder mit `possible_crtcs=0x0` haben
4. Erstellt einen zusätzlichen CRTC für DSI (display_num 0 = MAIN_LCD)
5. Verknüpft den CRTC mit dem DSI-Encoder

## Nächste Schritte:
1. Patch anwenden
2. Kernel-Modul kompilieren
3. Auf Pi installieren und testen

