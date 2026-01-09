## Dev mode: fewer passwords (temporary)

Goal: make development fast and repeatable (after reboots/power cuts), then revert back to a locked-down system when finished.

### What “dev mode” does

- **SSH key auth**: removes repeated SSH password prompts from Mac → Pi.
- **Limited passwordless sudo**: removes most `sudo` prompts for common maintenance tasks (display + WebUI + MPD + logs + `moodeutl`).

This is intentionally **NOT** `NOPASSWD:ALL` by default.

### Enable dev mode (recommended)

Run from your Mac (home directory friendly):

```bash
cd ~/moodeaudio-cursor && ./tools/fix/pi-dev-mode-enable.sh 192.168.10.2 andre
```

### Disable dev mode (recommended rollback)

Removes the sudoers drop-in (keeps SSH key auth):

```bash
cd ~/moodeaudio-cursor && ./tools/fix/pi-dev-mode-disable.sh 192.168.10.2 andre
```

Also remove this Mac’s SSH key from the Pi:

```bash
cd ~/moodeaudio-cursor && ./tools/fix/pi-dev-mode-disable.sh 192.168.10.2 andre --remove-key
```

### Security notes

- SSH key auth is standard practice and usually *more* secure than passwords (no password reuse, no typing secrets).
- Passwordless sudo increases local privilege. That’s why we keep an allowlist and make it reversible via one file in `/etc/sudoers.d/`.

