# WireGuard Keys - Complete Information

## Server Keys (Pi - MoodePi5)

### Private Key (KEEP SECRET!)
```
SL0CtH2yKjsmS63SNRJXZvTsQyOnNbp6UcFycVmm4n8=
```

### Public Key (Share with clients)
```
MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=
```

---

## Server Configuration

**Server VPN IP:** `10.8.0.1/24`  
**WireGuard Port:** `51820/UDP`  
**Status:** ✅ Active and running

---

## Complete Server Config

```ini
[Interface]
# Pi's private key
PrivateKey = SL0CtH2yKjsmS63SNRJXZvTsQyOnNbp6UcFycVmm4n8=

# Pi's IP in VPN network
Address = 10.8.0.1/24

# Listen on port 51820 (standard WireGuard port)
ListenPort = 51820

# Forward traffic
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Peers will be added here
# [Peer]
# PublicKey = CLIENT_PUBLIC_KEY_HERE
# AllowedIPs = 10.8.0.2/32
```

---

## Client Configuration Template

When adding a client, they need to provide their public key, then use this template:

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY_HERE
Address = 10.8.0.2/24

[Peer]
PublicKey = MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=
Endpoint = YOUR_SERVER_PUBLIC_IP:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
```

**Replace:**
- `CLIENT_PRIVATE_KEY_HERE` - Client's private key (they generate this)
- `YOUR_SERVER_PUBLIC_IP` - Your server's public IP address or domain name
- `10.8.0.2` - Client's VPN IP (can be changed if needed)

---

## Current Status

- ✅ WireGuard service: Active
- ✅ Interface: wg0
- ✅ Listening port: 51820
- ⚠️  No peers configured yet

---

## Adding a Client

1. Client generates keys:
   ```bash
   wg genkey | tee private.key | wg pubkey > public.key
   cat public.key
   ```

2. Client sends you their **public key**

3. Add to server config:
   ```bash
   cd ~/moodeaudio-cursor
   ./tools/add-wireguard-peer.sh CLIENT_PUBLIC_KEY
   ```

4. Share client config template with them (they add their private key)

---

## Security Notes

⚠️ **IMPORTANT:**
- **NEVER share the server private key**
- Only share the server **public key**
- Keep private keys secure
- Server private key is stored at: `/etc/wireguard/private.key` (root only)

---

*Generated: 2026-01-14*  
*Server: MoodePi5 (192.168.2.3)*
