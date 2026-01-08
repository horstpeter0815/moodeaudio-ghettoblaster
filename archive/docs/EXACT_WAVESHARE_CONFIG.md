# Exakte Waveshare Wiki Konfiguration

## Wie auf Waveshare Website beschrieben

### Am Ende der config.txt (nach allen anderen Einstellungen):

```
dtoverlay=vc4-kms-v3d

#DSI1 Use
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch

#DSI0 Use
#dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,dsi0
```

## Wichtig
- vc4-kms-v3d kommt ZUERST
- Dann Waveshare Overlay für DSI1
- DSI0 Version ist auskommentiert
- Alles AM ENDE der config.txt (nicht in [pi4] oder [all] Sektion!)
- Keine zusätzlichen Parameter
- Keine Duplikate

## Status
Config.txt wurde exakt wie Waveshare Wiki aufgebaut.

