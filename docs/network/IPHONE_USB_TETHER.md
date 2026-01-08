# iPhone USB Tether → Raspberry Pi (standard moOde download)

## Goal

- **Pi gets Internet via iPhone USB tethering** (Personal Hotspot)
- **Mac keeps Internet via hotel Wi‑Fi**
- (Optional but recommended) **Mac can still reach Pi via direct Ethernet** (static LAN), independent of Internet.

## iPhone steps

1. iPhone: **Settings → Personal Hotspot** → enable
2. Connect iPhone to the Pi via USB
3. On iPhone: tap **Trust** when prompted

## Pi behavior (with our fix installed)

- Detects the iPhone USB network interface (Apple vendor `05ac` / `ipheth`)
- Brings it up, runs DHCP, and prefers it as the **default route**
- Does **not** change `eth0` addressing (so you can keep a Mac↔Pi direct link)

## Install (standard moOde download workflow)

After flashing and mounting the SD card (`/Volumes/bootfs` and `/Volumes/rootfs`), run:

```bash
cd ~/moodeaudio-cursor && sudo ./INSTALL_FIXES_AFTER_FLASH.sh
```

## Verify on the Pi

```bash
ip -4 addr
ip route
systemctl status iphone-usb-tether.service --no-pager
ping -c 1 1.1.1.1
```

## Recommended Mac↔Pi access (direct Ethernet)

- Mac Ethernet: `192.168.10.1/24` (no router)
- Pi eth0: `192.168.10.2/24` (no router)
- Then open: `http://192.168.10.2/`

### Why we avoid a gateway on eth0

This setup keeps `eth0` as a **safe management link** only. Internet routing is provided by:
- **iPhone USB tether** when plugged in, or
- Wi‑Fi client when configured.

So `eth0` is configured with **no default gateway** and is marked **never-default** in NetworkManager, preventing it from stealing the default route.

## Optional: moOde Hotspot password

If you enable moOde’s Access Point/Hotspot, this project sets the default password to:

- `08150815`

## Optional: remove old custom Wi‑Fi profiles

On boot, the cleanup service removes only these profiles (if present):
- `Ghettoblaster`
- `Ghetto LAN`


