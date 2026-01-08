# Parallel Setup - Beide Pis

## Übersicht

- **ghettopi5**: Mit AMP100
- **ghettopi5-2**: Ohne AMP100 (neu formatiert)

## Schnellstart

### 1. Beide Pis einrichten

```bash
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

bash setup_both_pis.sh
```

### 2. Display-Fix auf beiden Pis

```bash
# ghettopi5 (mit AMP100)
ssh andre@ghettopi5 ./supervisor.sh display-fix

# ghettopi5-2 (ohne AMP100)
ssh andre@ghettopi5-2 ./supervisor.sh display-fix
```

### 3. Reboot beide Pis

```bash
ssh andre@ghettopi5 sudo reboot
ssh andre@ghettopi5-2 sudo reboot
```

### 4. Video-Test auf beiden Pis (sicher, überschreibt nichts)

```bash
ssh andre@ghettopi5 ./supervisor.sh video-test
ssh andre@ghettopi5-2 ./supervisor.sh video-test
```

## Supervisor-Befehle

Beide Pis haben jetzt:
- `./supervisor.sh status` - Status anzeigen
- `./supervisor.sh display-fix` - Display konfigurieren
- `./supervisor.sh video-test` - Video-Pipeline testen (READ-ONLY)

## Unterschiede

- **ghettopi5**: Mit AMP100 (Audio über HiFiBerry)
- **ghettopi5-2**: Ohne AMP100 (Audio über HDMI/Pi)

Beide haben:
- Gleiches Display (Waveshare 7.9" HDMI 1280x400)
- Gleiche Display-Konfiguration
- Gleiche X11/Chromium-Setup

