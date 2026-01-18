## Best moOde Dev Setup (Mac + Cursor) with Real Raspberry Pi “Truth”

moOde depends on **real Raspberry Pi hardware** (ALSA/I2S/USB DACs, kernel drivers).
Use a devcontainer for fast iteration and validate audio on an actual Pi.

### Devcontainer (fast iteration on Mac)

- **What it’s for**: editing PHP/JS/CSS, reviewing config behavior, quick UI checks.
- **What it is not**: a faithful audio stack on macOS (you won’t have `/dev/snd`).

Steps:

1. Open the repo in Cursor
2. Reopen in container (Cursor / VS Code “Dev Containers”)
3. Confirm services:

```bash
cd ~/moodeaudio-cursor && ./scripts/start.sh --status
```

Web UI (dev):
- `http://127.0.0.1:8080/`

### Sync to Pi 5 (final truth for audio/drivers)

Two common ways:

- **GitHub**: push changes from Mac, pull on Pi
- **rsync**: fastest when you iterate frequently

Example rsync (adjust hostname/IP):

```bash
cd ~/moodeaudio-cursor && rsync -av --delete \
  --exclude '.git' \
  --exclude 'archive' \
  ./ andre@192.168.10.2:~/moodeaudio-cursor/
```

Toolbox shortcut (preferred):

```bash
cd ~/moodeaudio-cursor && ./tools/dev.sh --sync-pi
```

### Validate on the Pi

Run audio diagnostics:

```bash
cd ~/moodeaudio-cursor && ./scripts/diagnose_audio.sh
```

From your Mac (SSH shortcut):

```bash
cd ~/moodeaudio-cursor && ./tools/dev.sh --ssh-diagnose-audio
```

Minimum “truth” checks:
- `aplay -l` shows your DAC/HAT
- MPD output + playback works (actual sound)

### Optional: Docker on Pi with real audio passthrough

```bash
docker run -it --rm \
  --network host \
  --device /dev/snd \
  --group-add audio \
  debian:bookworm bash
```

Inside container:

```bash
apt update && apt install -y alsa-utils mpd mpc
aplay -l
```

