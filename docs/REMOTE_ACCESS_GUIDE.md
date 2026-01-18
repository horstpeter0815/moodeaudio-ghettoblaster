# Remote Access Guide for moOde Audio Player

## Overview

This guide explains how to remotely access the moOde Audio Player (MoodePi5) using WireGuard VPN. Once connected, you can:
- Access the web interface from anywhere
- SSH into the system for troubleshooting
- Control audio playback remotely

---

## Prerequisites

- A computer (Windows, Mac, or Linux) with internet access
- WireGuard client installed on your device
- The server's public key (provided separately)
- Port 51820/UDP must be open on the router (if behind a firewall)

---

## Part 1: Installing WireGuard Client

### Windows
1. Download WireGuard from: https://www.wireguard.com/install/
2. Install the application
3. Open WireGuard

### Mac
1. Install from Mac App Store: Search "WireGuard"
2. Or download from: https://www.wireguard.com/install/
3. Open WireGuard application

### Linux
```bash
# Ubuntu/Debian
sudo apt-get install wireguard wireguard-tools

# Fedora
sudo dnf install wireguard-tools

# Arch
sudo pacman -S wireguard-tools
```

### Android/iOS
- Install "WireGuard" from Google Play Store or App Store

---

## Part 2: Setting Up Your Client

### Step 1: Generate Your Keys

**On Windows/Mac (using WireGuard GUI):**
1. Click "Add Tunnel" → "Add Empty Tunnel"
2. WireGuard will automatically generate keys
3. Copy your **Public Key** (you'll need to share this)

**On Linux/Command Line:**
```bash
# Generate private key
wg genkey | tee private.key | wg pubkey > public.key

# View your public key (share this)
cat public.key
```

### Step 2: Share Your Public Key

Send your **Public Key** to the system administrator. They will add you to the server configuration.

### Step 3: Receive Your Configuration

Once added, you'll receive a configuration file that looks like this:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.8.0.2/24

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
```

**Important:** Replace `YOUR_SERVER_IP` with the actual server's public IP address or domain name.

### Step 4: Import Configuration

**Windows/Mac (GUI):**
1. Copy the configuration text
2. In WireGuard, click "Add Tunnel" → "Import from file" or paste the config
3. Save the configuration

**Linux (Command Line):**
```bash
# Save config to file
sudo nano /etc/wireguard/wg0.conf
# Paste the configuration, save and exit

# Set permissions
sudo chmod 600 /etc/wireguard/wg0.conf
```

---

## Part 3: Connecting

### Windows/Mac (GUI)
1. Open WireGuard application
2. Click the toggle switch next to your configuration
3. Status should show "Active" with a green indicator

### Linux (Command Line)
```bash
# Start WireGuard
sudo wg-quick up wg0

# Check status
sudo wg show

# Stop WireGuard
sudo wg-quick down wg0
```

### Verify Connection
```bash
# Ping the server
ping 10.8.0.1

# Should see responses like:
# PING 10.8.0.1 (10.8.0.1) 56(84) bytes of data.
# 64 bytes from 10.8.0.1: icmp_seq=1 ttl=64 time=XX ms
```

---

## Part 4: Accessing the Web Interface

Once connected via WireGuard:

1. **Open your web browser**
2. **Navigate to:** `http://10.8.0.1/`
3. **You should see:** The moOde Audio Player web interface

**Note:** The web interface may take a few seconds to load. If you see a login screen, try:
- Clearing browser cache (Ctrl+Shift+Delete)
- Using incognito/private mode
- Refreshing the page

---

## Part 5: SSH Access

To SSH into the system for troubleshooting:

```bash
ssh andre@10.8.0.1
```

**Password:** `0815`

**Example:**
```bash
$ ssh andre@10.8.0.1
andre@10.8.0.1's password: [enter 0815]
andre@MoodePi5:~$
```

---

## Part 6: Common Problems and Solutions

### Problem 1: Cannot Connect to WireGuard Server

**Symptoms:**
- WireGuard shows "Connecting..." but never connects
- Error: "Handshake did not complete"

**Solutions:**
1. **Check server is online:**
   ```bash
   ping YOUR_SERVER_IP
   ```

2. **Check port 51820 is open:**
   - Verify router/firewall allows UDP port 51820
   - Test with: `nc -u -v YOUR_SERVER_IP 51820`

3. **Check server WireGuard status:**
   - Ask administrator to check: `sudo systemctl status wg-quick@wg0`

4. **Verify configuration:**
   - Double-check PublicKey matches server's public key
   - Ensure Endpoint IP/domain is correct
   - Check AllowedIPs is set correctly

5. **Try different network:**
   - Some networks block VPN connections
   - Try from mobile hotspot or different WiFi

---

### Problem 2: Connected but Cannot Access Web Interface

**Symptoms:**
- WireGuard shows "Active" (green)
- Cannot access `http://10.8.0.1/`
- Browser shows "Connection refused" or timeout

**Solutions:**
1. **Verify connection:**
   ```bash
   ping 10.8.0.1
   ```
   If ping fails, WireGuard connection is not working properly.

2. **Check web server is running:**
   - Ask administrator to check: `sudo systemctl status nginx`
   - Or: `sudo systemctl status lighttpd`

3. **Try different browser:**
   - Clear cache and cookies
   - Use incognito/private mode
   - Try Firefox, Chrome, or Safari

4. **Check firewall:**
   - Server firewall might block connections
   - Ask administrator to verify firewall rules

5. **Try SSH first:**
   ```bash
   ssh andre@10.8.0.1
   ```
   If SSH works but web doesn't, it's a web server issue.

---

### Problem 3: SSH Connection Fails

**Symptoms:**
- `ssh andre@10.8.0.1` fails
- "Connection refused" or "Connection timed out"

**Solutions:**
1. **Verify WireGuard is connected:**
   ```bash
   ping 10.8.0.1
   ```

2. **Check SSH is running on server:**
   - Ask administrator: `sudo systemctl status ssh`

3. **Verify SSH listens on WireGuard interface:**
   - Ask administrator to check: `sudo ss -tlnp | grep 22`
   - Should show: `10.8.0.1:22`

4. **Check for host key issues:**
   ```bash
   # Remove old host key
   ssh-keygen -R 10.8.0.1
   
   # Try connecting again
   ssh -o StrictHostKeyChecking=accept-new andre@10.8.0.1
   ```

5. **Verify credentials:**
   - Username: `andre`
   - Password: `0815`

---

### Problem 4: Slow Connection or High Latency

**Symptoms:**
- Web interface loads slowly
- High ping times
- Audio streaming is choppy

**Solutions:**
1. **Check internet speed:**
   - Run speed test on both ends
   - WireGuard adds minimal overhead (~5-10%)

2. **Check server resources:**
   - Ask administrator: `htop` or `top`
   - High CPU usage can slow things down

3. **Try different DNS:**
   ```bash
   # In WireGuard config, add:
   DNS = 8.8.8.8
   ```

4. **Reduce MTU:**
   - Some networks require lower MTU
   - In WireGuard config, add:
   ```ini
   [Interface]
   MTU = 1280
   ```

---

### Problem 5: Connection Drops Frequently

**Symptoms:**
- WireGuard disconnects randomly
- Need to reconnect often

**Solutions:**
1. **Enable PersistentKeepalive:**
   ```ini
   [Peer]
   PersistentKeepalive = 25
   ```
   This sends keepalive packets every 25 seconds.

2. **Check network stability:**
   - Test with: `ping -c 100 10.8.0.1`
   - Look for packet loss

3. **Check server logs:**
   - Ask administrator: `sudo journalctl -u wg-quick@wg0 -n 50`

4. **Update WireGuard:**
   - Ensure both client and server are up to date

---

### Problem 6: Web Interface Shows Login Screen

**Symptoms:**
- Browser shows "MoodePi5 login" or login form
- Cannot access the player interface

**Solutions:**
1. **Clear browser cache:**
   - Press `Ctrl+Shift+Delete` (Windows/Linux)
   - Press `Cmd+Shift+Delete` (Mac)
   - Clear "Cached images and files"

2. **Use incognito/private mode:**
   - Chrome: `Ctrl+Shift+N` (Windows) or `Cmd+Shift+N` (Mac)
   - Firefox: `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac)

3. **Try different browser:**
   - Firefox, Chrome, Safari, Edge

4. **Check browser console:**
   - Press `F12` → Console tab
   - Look for JavaScript errors

5. **Try direct URL:**
   - `http://10.8.0.1/?nocache=12345`

---

### Problem 7: Audio Not Playing

**Symptoms:**
- Web interface loads but audio doesn't play
- Play button doesn't work

**Solutions:**
1. **Check MPD service:**
   - Ask administrator: `sudo systemctl status mpd`
   - Should show "active (running)"

2. **Check audio device:**
   - Ask administrator: `aplay -l`
   - Should show HiFiBerry AMP100

3. **Verify audio chain:**
   - Ask administrator to run audio fix script
   - Or check: `mpc status`

4. **Check volume:**
   - In web interface, check volume is not muted
   - Try: `mpc volume 20` (via SSH)

---

## Part 7: Useful Commands

### Check WireGuard Status
```bash
# Client side
sudo wg show

# Should show:
# interface: wg0
#   public key: YOUR_PUBLIC_KEY
#   private key: (hidden)
#   listening port: XXXXX
#
# peer: SERVER_PUBLIC_KEY
#   endpoint: SERVER_IP:51820
#   allowed ips: 10.8.0.1/32
#   latest handshake: XX seconds ago
#   transfer: XXX received, XXX sent
```

### Test Connection
```bash
# Ping server
ping 10.8.0.1

# Test web interface
curl http://10.8.0.1/

# Test SSH
ssh -v andre@10.8.0.1
```

### Restart WireGuard
```bash
# Linux
sudo wg-quick down wg0
sudo wg-quick up wg0

# Windows/Mac: Use GUI toggle
```

---

## Part 8: Security Notes

1. **Keep your private key secure:**
   - Never share your private key
   - Only share your public key

2. **Use strong passwords:**
   - SSH password should be changed from default
   - Consider using SSH keys instead of passwords

3. **Keep WireGuard updated:**
   - Regularly update WireGuard client
   - Server will be updated by administrator

4. **Monitor connections:**
   - Check `sudo wg show` regularly
   - Report suspicious activity

---

## Part 9: Getting Help

If you encounter problems not covered here:

1. **Check server status:**
   - Ask administrator to verify server is online
   - Check: `sudo systemctl status wg-quick@wg0`

2. **Collect information:**
   ```bash
   # WireGuard status
   sudo wg show
   
   # Connection test
   ping 10.8.0.1
   
   # Web interface test
   curl -v http://10.8.0.1/
   ```

3. **Contact administrator:**
   - Provide error messages
   - Include output from commands above
   - Describe what you were trying to do

---

## Quick Reference

| Service | Address | Port | Notes |
|---------|---------|------|-------|
| WireGuard Server | 10.8.0.1 | 51820/UDP | VPN endpoint |
| Web Interface | http://10.8.0.1/ | 80/HTTP | moOde player UI |
| SSH | andre@10.8.0.1 | 22/TCP | Remote shell access |

**SSH Credentials:**
- Username: `andre`
- Password: `0815`

**WireGuard Network:**
- Server IP: `10.8.0.1`
- Client IP: `10.8.0.2` (or assigned by admin)

---

## Appendix: Server Information

**Server Details:**
- Hostname: MoodePi5
- OS: Debian GNU/Linux 13
- moOde Version: 10.0.1
- Audio Device: HiFiBerry AMP100

**Network:**
- Local IP: 192.168.2.3
- VPN IP: 10.8.0.1
- WireGuard Port: 51820/UDP

---

*Last Updated: 2026-01-14*
*For technical support, contact the system administrator*
