# Saubere Config.txt - Wie Waveshare Wiki

## Konfiguration nach Waveshare Wiki

### [all] Sektion:
```
[all]
dtoverlay=vc4-kms-v3d
```

### Am Ende der config.txt (wie Waveshare Wiki):
```
#DSI1 Use
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch

#DSI0 Use
#dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,dsi0
```

## Wichtig
- Waveshare Overlay wird **am Ende** der config.txt hinzugefügt (nicht in [pi4] Sektion!)
- vc4-kms-v3d in [all] Sektion
- Keine Duplikate
- Keine redundanten Parameter
- Saubere, bereinigte Config

## Status
Config.txt wurde komplett bereinigt und nach Waveshare Wiki-Vorgabe aufgebaut.

