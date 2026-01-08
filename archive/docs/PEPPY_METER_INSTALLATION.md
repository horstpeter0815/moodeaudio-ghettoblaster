# Peppy Meter Installation - Ghetto Pi 5

## Installation durchgeführt: $(date)

### Was wurde installiert:

1. **Python-Abhängigkeiten:**
   - python3-pip
   - python3-pygame
   - python3-numpy
   - python3-pil
   - python3-alsaaudio
   - alsa-utils

2. **Peppy Meter Basis-Version:**
   - Installiert in: `/opt/peppymeter/`
   - Haupt-Script: `/opt/peppymeter/peppymeter.py`
   - Config: `/opt/peppymeter/config.ini`

3. **Systemd Service:**
   - Service: `peppymeter.service`
   - Startet automatisch nach Boot
   - Läuft als User: `andre`
   - Display: `:0`

### Konfiguration für 1280x400:

```ini
[display]
width = 1280
height = 400
fullscreen = true

[audio]
device = default
rate = 44100
channels = 2

[visualizer]
type = spectrum
bars = 64
```

### Service-Befehle:

```bash
# Service starten
sudo systemctl start peppymeter

# Service stoppen
sudo systemctl stop peppymeter

# Service aktivieren (Auto-Start)
sudo systemctl enable peppymeter

# Service deaktivieren
sudo systemctl disable peppymeter

# Status prüfen
sudo systemctl status peppymeter
```

### Manuell starten:

```bash
export DISPLAY=:0
/usr/bin/python3 /opt/peppymeter/peppymeter.py
```

### Nächste Schritte:

1. Service aktivieren: `sudo systemctl enable peppymeter`
2. Service starten: `sudo systemctl start peppymeter`
3. Testen ob Visualisierung funktioniert
4. Mit Moode Audio integrieren (falls nötig)

## Status: ✅ Installiert

