# Network Fix - Minimal Approach

## The Problem
- Pi shows 127.0.1.1 (not reachable)
- Can't access moOde web interface
- Can't SSH to configure anything
- Catch-22: Need network to configure, but network doesn't work

## The Solution
ONE service that just sets an IP address. Nothing fancy.

## Apply It

```bash
cd ~/moodeaudio-cursor
sudo bash MINIMAL_NETWORK_FIX.sh
```

## What It Does

Creates ONE service: `minimal-network.service`

This service:
1. Waits for eth0 interface (up to 20 seconds)
2. Sets IP: 192.168.10.2/24
3. Sets gateway: 192.168.10.1
4. Sets DNS

That's it. No NetworkManager conflicts. No other services. Just IP address.

## After Boot

1. Boot Pi
2. Wait 30 seconds
3. Pi should have IP: 192.168.10.2
4. SSH: `ssh pi@192.168.10.2` (password: raspberry)
5. Or access moOde web: `http://192.168.10.2`

## If It Still Doesn't Work

Check on the Pi (if you have console access):
```bash
systemctl status minimal-network.service
journalctl -u minimal-network.service
ip addr show eth0
```

If eth0 doesn't exist, the Ethernet cable or interface is the issue, not the software.



