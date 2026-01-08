# Alternative Approach: DSI Encoder Patch

## Problem:
FKMS Patch funktioniert nicht, weil:
1. Kompilierung schlägt fehl (fehlende Header)
2. DSI-Connectors existieren noch nicht beim FKMS-Bind

## Alternative Lösung:
Statt FKMS zu patchen, patche den DSI-Encoder selbst, damit er FKMS-CRTCs findet.

## Ansatz:
1. In `vc4_dsi.c` nach `drm_encoder_init` für DSI suchen
2. Nach der Encoder-Initialisierung prüfen, ob `possible_crtcs == 0`
3. Falls ja, durch alle CRTCs iterieren und FKMS-CRTCs finden
4. `possible_crtcs` entsprechend setzen

## Vorteil:
- DSI-Encoder wird später initialisiert (nach FKMS)
- Kann FKMS-CRTCs finden
- Einfacher zu kompilieren (nur eine Datei)

---

**Status:** Ansatz dokumentiert, noch nicht implementiert

