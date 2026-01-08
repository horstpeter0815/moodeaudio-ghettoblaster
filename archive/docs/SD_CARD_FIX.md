# SD-Karte Fix - Moode Audio

## Was ich gemacht habe
- SD-Karte gesucht und gefunden
- config.txt bereinigt (problematische Timings entfernt)
- Nur sichere Einstellungen behalten

## Neue Konfiguration
```ini
[pi5]
hdmi_force_hotplug=1
disable_overscan=1
display_rotate=0
```

## Entfernt
- hdmi_timings (verursachte Flackern)
- hdmi_cvt (verursachte Probleme)
- framebuffer_width/height (nicht nötig)

## Nächste Schritte
1. SD-Karte sicher auswerfen
2. In Moode Audio Pi einstecken
3. Booten
4. Display sollte stabil sein (kein Flackern)
5. Rotation wird via xinitrc gemacht (stabiler)

