# macOS SD Repair (ext4 rootfs) + Harden (moOde customizations)

This project includes a macOS one-shot tool that:

- Detects `bootfs` + `rootfs` mounts under `/Volumes`
- Repairs the ext4 `rootfs` (via `e2fsck`) when it is mounted read-only
- Re-applies project hardening/customizations after repair

## Requirements

- macOS (Apple Silicon or Intel)
- ext4 mounting via extFS (or equivalent), with volumes mounted as:
  - `/Volumes/bootfs`
  - `/Volumes/rootfs` (or `/Volumes/rootfs 1`, `/Volumes/rootfs 2`, …)
- Homebrew recommended (for `e2fsprogs` / `e2fsck`)

## Safe preflight (no changes)

Shows detected device node and which `e2fsck` would be used, **without** unmounting or running fsck:

```bash
cd ~/moodeaudio-cursor && ./tools/fix.sh --sd-macos-preflight
```

## Fix the SD (repair + harden)

Runs the full repair + hardening flow:

```bash
cd ~/moodeaudio-cursor && ./tools/fix.sh --sd-macos
```

Notes:

- If `e2fsck` is missing or too old, the script will install/upgrade `e2fsprogs` via Homebrew **as your normal user** (even though the script is run with `sudo`).
- If `rootfs` is not mounted, open extFS and mount the Linux/ext4 partition, then re-run.


