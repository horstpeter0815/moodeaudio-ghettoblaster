# Quick Start: Remote Access Setup

## For the Friend (Client Setup)

### Step 1: Install WireGuard
- **Windows/Mac:** Download from https://www.wireguard.com/install/
- **Linux:** `sudo apt-get install wireguard wireguard-tools`
- **Mobile:** Install "WireGuard" app from app store

### Step 2: Generate Your Keys

**Windows/Mac (GUI):**
1. Open WireGuard
2. Click "Add Tunnel" → "Add Empty Tunnel"
3. Copy your **Public Key** (shown in the config)

**Linux/Command Line:**
```bash
wg genkey | tee private.key | wg pubkey > public.key
cat public.key
```

### Step 3: Share Your Public Key
Send your **Public Key** to the system administrator.

### Step 4: Receive and Import Configuration
You'll receive a configuration file. Import it into WireGuard:

**Windows/Mac:** Copy-paste into WireGuard GUI
**Linux:** Save to `/etc/wireguard/wg0.conf`

### Step 5: Connect
- **Windows/Mac:** Toggle the switch in WireGuard GUI
- **Linux:** `sudo wg-quick up wg0`

### Step 6: Access Web Interface
Open browser: `http://10.8.0.1/`

---

## For the Administrator (Adding a Friend)

### Step 1: Get Friend's Public Key
Friend should send you their public key.

### Step 2: Add Friend to Server
```bash
cd ~/moodeaudio-cursor
./tools/add-wireguard-peer.sh FRIEND_PUBLIC_KEY_HERE
```

### Step 3: Share Configuration with Friend
The script will output a configuration template. Share it with your friend.

**Important:** Friend needs to:
1. Replace `FRIEND_PRIVATE_KEY_HERE` with their private key
2. Replace `YOUR_SERVER_PUBLIC_IP` with your server's public IP

### Step 4: Verify Connection
```bash
# On server, check WireGuard status
sudo wg show

# Should show the peer with recent handshake
```

---

## Server Information

**Server Public Key:**
```
MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=
```

**Server VPN IP:** `10.8.0.1`

**WireGuard Port:** `51820/UDP`

**SSH Access:**
- Address: `andre@10.8.0.1`
- Password: `0815`

**Web Interface:** `http://10.8.0.1/`

---

## Troubleshooting

**Cannot connect?**
1. Check server is online: `ping YOUR_SERVER_IP`
2. Verify port 51820/UDP is open
3. Check WireGuard status on server: `sudo systemctl status wg-quick@wg0`

**Connected but can't access web?**
1. Verify connection: `ping 10.8.0.1`
2. Try: `http://10.8.0.1/` in browser
3. Clear browser cache
4. Check server web service: `sudo systemctl status nginx`

**SSH not working?**
1. Verify WireGuard connection: `ping 10.8.0.1`
2. Try: `ssh andre@10.8.0.1`
3. Password: `0815`

For detailed troubleshooting, see: `docs/REMOTE_ACCESS_GUIDE.md`
