# Fix SMB Connection to GhettoBlaster

## Problem
- GhettoBlaster appears in Finder Network
- Connection window appears but connection fails
- Can't connect via SMB

## Solutions

### Solution 1: Check Pi IP Address

1. **In Finder:**
   - Right-click on GhettoBlaster
   - Select "Get Info"
   - Note the IP address shown

2. **Connect directly via IP:**
   - Press Cmd+K in Finder
   - Enter: `smb://[IP_ADDRESS]` (replace with actual IP)
   - Click Connect
   - Try credentials: `pi` / `raspberry`

### Solution 2: Try Different Connection Methods

**SSH (if available):**
```bash
ssh pi@[IP_ADDRESS]
# Password: raspberry
```

**Web Interface:**
```
http://[IP_ADDRESS]
```

### Solution 3: Check SMB Service on Pi

If you have SSH access:

```bash
# Check if SMB is running
sudo systemctl status smbd

# Start SMB if not running
sudo systemctl start smbd
sudo systemctl enable smbd

# Check SMB configuration
sudo cat /etc/samba/smb.conf | grep -A 5 "\["
```

### Solution 4: Reset SMB Connection

On Mac:

```bash
cd ~/moodeaudio-cursor
./RESET_GHETTOBLASTER_CONNECTION.sh
```

Then try connecting again.

### Solution 5: Check Credentials

Try these combinations:
- `pi` / `raspberry`
- `andre` / `0815`
- `moode` / `moodeaudio`
- Guest (no password)

### Solution 6: Use Alternative Access

If SMB doesn't work, use:
- **SSH:** `ssh pi@[IP]`
- **Web:** `http://[IP]`
- **SCP:** `scp file pi@[IP]:/path`

## Common Issues

1. **SMB service not running on Pi**
   - Fix: SSH to Pi and start smbd service

2. **Wrong credentials**
   - Fix: Try different username/password combinations

3. **User doesn't have SMB access**
   - Fix: Configure Samba on Pi to allow user access

4. **Network connectivity issue**
   - Fix: Check if Pi is on same network as Mac

5. **Firewall blocking**
   - Fix: Check firewall settings on Pi

## Quick Test

1. Find Pi IP address (from Finder Get Info)
2. Test ping: `ping [IP_ADDRESS]`
3. Test SSH: `ssh pi@[IP_ADDRESS]`
4. Test Web: Open `http://[IP_ADDRESS]` in browser
5. Test SMB: `smb://[IP_ADDRESS]` in Finder

