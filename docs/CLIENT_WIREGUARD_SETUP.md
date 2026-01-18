# WireGuard Client Setup - Complete Guide

## For: andre.vollmer.mail@gmail.com

Your peer has been added to the server! Here's everything you need to connect.

---

## ✅ Server Status

- **Peer Added:** ✅ Yes
- **Your Public Key:** `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=`
- **Your VPN IP:** `10.8.0.2/32`
- **Server Public IP:** `223.206.210.138`
- **Server Port:** `51820/UDP`

---

## Step 1: Install WireGuard on Your Mac

### Option A: Mac App Store (Easiest)
1. Open Mac App Store
2. Search for "WireGuard"
3. Click "Get" or "Install"
4. Open WireGuard application

### Option B: Homebrew
```bash
brew install --cask wireguard
```

---

## Step 2: Create Your Client Configuration

You need to create a configuration file with:
- Your **private key** (the one you used to generate your public key)
- Server information

### Configuration Template

Create a file called `moode-pi.conf` with this content:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.8.0.2/24

[Peer]
PublicKey = NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU=
Endpoint = 223.206.210.138:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
```

**Important:** Replace `YOUR_PRIVATE_KEY_HERE` with your actual private key (the one you used when generating your public key `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=`).

---

## Step 3: Import Configuration into WireGuard

### Using WireGuard GUI:
1. Open WireGuard application
2. Click the "+" button (bottom left) or "Add Tunnel"
3. Select "Import from file" or "Create from file"
4. Select your `moode-pi.conf` file
5. Give it a name like "MoodePi5"
6. Click "Save"

### Using Command Line:
```bash
# Copy config to WireGuard directory
sudo cp moode-pi.conf /usr/local/etc/wireguard/moode-pi.conf

# Or if using GUI, import via:
# WireGuard GUI → Add Tunnel → Import from file
```

---

## Step 4: Connect

1. In WireGuard GUI, click the toggle switch next to "MoodePi5"
2. Status should show "Active" (green indicator)
3. You're connected! 🎉

---

## Step 5: Test Connection

### Test VPN Connection:
```bash
# Ping the server
ping 10.8.0.1

# Should see responses like:
# PING 10.8.0.1 (10.8.0.1): 56 data bytes
# 64 bytes from 10.8.0.1: icmp_seq=0 ttl=64 time=XX ms
```

### Test Web Interface:
Open browser: `http://10.8.0.1/`

### Test SSH:
```bash
ssh andre@10.8.0.1
# Password: 0815
```

---

## Troubleshooting

### Cannot Connect
- Check WireGuard shows "Active" (green)
- Verify your private key is correct
- Check firewall allows UDP port 51820
- Try different network (some block VPNs)

### Connected but Can't Access
- Verify: `ping 10.8.0.1` works
- Check web interface: `http://10.8.0.1/`
- Try SSH: `ssh andre@10.8.0.1`

### Connection Drops
- Ensure `PersistentKeepalive = 25` is in config
- Check internet connection stability
- Update WireGuard to latest version

---

## What You Can Access

Once connected:
- **Web Interface:** `http://10.8.0.1/` - moOde Audio Player
- **SSH:** `ssh andre@10.8.0.1` - Remote shell access
- **Password:** `0815`

---

## Your Project: Touchscreen Driver Fix

You mentioned wanting to fix:
> "The Waveshare touchscreen driver initializes before the display panel, which causes I2C conflicts and unstable behavior on boot."

### Relevant Files to Check:
- `/boot/firmware/config.txt` - Device tree overlays
- `/etc/modules-load.d/` - Module loading order
- `/etc/systemd/system/` - Service dependencies
- Device tree overlays: `custom-components/overlays/`
- I2C stabilization: `custom-components/scripts/i2c-stabilize.sh`

### Useful Commands:
```bash
# Check I2C devices
i2cdetect -y 1

# Check module load order
ls -la /etc/modules-load.d/

# Check systemd services
systemctl list-units | grep -i touch
systemctl list-units | grep -i display

# Check boot logs
journalctl -b | grep -i "ft6236\|touch\|display\|i2c"
```

---

## Quick Reference

| Item | Value |
|------|-------|
| Server Public IP | `223.206.210.138` |
| Server VPN IP | `10.8.0.1` |
| Your VPN IP | `10.8.0.2` |
| WireGuard Port | `51820/UDP` |
| Server Public Key | `MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=` |
| Your Public Key | `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=` |
| SSH User | `andre` |
| SSH Password | `0815` |

---

## Need Help?

If you encounter issues:
1. Check WireGuard status: `sudo wg show` (on Mac)
2. Check server status: `ssh andre@10.8.0.1 "sudo wg show"`
3. Check server logs: `ssh andre@10.8.0.1 "sudo journalctl -u wg-quick@wg0 -n 50"`

---

*Setup Date: 2026-01-14*  
*Server: MoodePi5 (192.168.2.3 / 223.206.210.138)*
