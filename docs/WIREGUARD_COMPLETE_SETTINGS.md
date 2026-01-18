# Complete WireGuard Settings - MoodePi5

**Generated:** 2026-01-15  
**Server:** MoodePi5 (andre@moodepi5.local)

---

## 🔧 SERVER CONFIGURATION

### Server Config File: `/etc/wireguard/wg0.conf`

```ini
[Interface]
PrivateKey = IDe7dpNlwCMsWS+LCxGWNRpf7J4pBtEbGgkrhzS2HFc=
Address = 10.8.0.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = 0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=
AllowedIPs = 10.8.0.2/32
PersistentKeepalive = 25
```

---

## 📊 SERVER STATUS

### Service Status
- **Status:** ✅ Active (running)
- **Service:** `wg-quick@wg0.service`
- **Enabled on Boot:** ✅ Yes
- **Started:** 2026-01-15 13:41:31 CET

### Interface Status
- **Interface:** `wg0`
- **State:** UP, LOWER_UP
- **MTU:** 1420
- **Server VPN IP:** `10.8.0.1/24`
- **Listening Port:** `51820/UDP`

### Server Keys
- **Server Public Key:** `NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU=`
- **Server Private Key:** `IDe7dpNlwCMsWS+LCxGWNRpf7J4pBtEbGgkrhzS2HFc=` (hidden in runtime)

---

## 🌐 NETWORK SETTINGS

### Public Network
- **Public IP:** `49.237.169.231` (current)
- **Previous Public IP (documented):** `223.206.210.138`
- **Note:** Public IP may change if using dynamic IP

### Local Network
- **Local IP (eth0):** `192.168.2.3/24`
- **VPN Network:** `10.8.0.0/24`
- **Server VPN IP:** `10.8.0.1`
- **Client VPN IP:** `10.8.0.2`

### Port Status
- **WireGuard Port:** `51820/UDP`
- **Status:** ✅ Listening on `0.0.0.0:51820` and `:::51820`

---

## 👥 PEER CONFIGURATION

### Client Peer
- **Client Public Key:** `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=`
- **Client VPN IP:** `10.8.0.2/32`
- **AllowedIPs:** `10.8.0.2/32`
- **PersistentKeepalive:** `25 seconds`

### Connection Status
- **Latest Handshake:** `0` (never connected or connection lost)
- **Transfer (RX/TX):** `0 / 0` bytes
- **Endpoint:** `(none)` (client not connected)
- **Status:** ⚠️ **NOT CONNECTED** - No active connection from client

---

## 🔥 FIREWALL & ROUTING

### IP Forwarding
- **Current Status:** ❌ **DISABLED (0)** - **CRITICAL ISSUE**
- **Should be:** `1` (enabled)
- **Impact:** Client cannot access internet through VPN

### iptables Rules

#### FORWARD Chain
```
Chain FORWARD (policy ACCEPT)
    0     0 ACCEPT     all  --  wg0    *       0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  *      wg0     0.0.0.0/0            0.0.0.0/0
```

#### NAT (POSTROUTING) Chain
```
Chain POSTROUTING
  263 71791 MASQUERADE  all  --  *      eth0    0.0.0.0/0            0.0.0.0/0
```

### Routing
- **wg0 Route:** `10.8.0.0/24 dev wg0 proto kernel scope link src 10.8.0.1`

---

## 📝 CLIENT CONFIGURATION (For Reference)

### Client Config Template

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

**Note:** Client must use their own private key (the one that generated public key `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=`)

---

## ⚠️ KNOWN ISSUES

### Critical Issues
1. **IP Forwarding Disabled**
   - Current: `0` (disabled)
   - Required: `1` (enabled)
   - **Fix:** `echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward`
   - **Persistent:** Add to `/etc/sysctl.conf`: `net.ipv4.ip_forward=1`

2. **No Active Connection**
   - Latest handshake: `0` (never connected)
   - Endpoint: `(none)`
   - Client is not currently connected

### Public IP Mismatch
- **Documented IP:** `223.206.210.138`
- **Current IP:** `49.237.169.231`
- **Action:** Update client config with current public IP if connection fails

---

## 🔍 DIAGNOSTIC COMMANDS

### Check WireGuard Status
```bash
sudo wg show
sudo wg show wg0 dump
sudo systemctl status wg-quick@wg0.service
```

### Check Network
```bash
ip addr show wg0
ip route | grep wg0
sudo netstat -tuln | grep 51820
```

### Check Firewall
```bash
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
cat /proc/sys/net/ipv4/ip_forward
```

### Check Logs
```bash
sudo journalctl -u wg-quick@wg0.service -n 50
```

---

## 📋 QUICK REFERENCE

| Item | Value |
|------|-------|
| **Server Public IP** | `49.237.169.231` (current) / `223.206.210.138` (documented) |
| **Server VPN IP** | `10.8.0.1` |
| **Client VPN IP** | `10.8.0.2` |
| **WireGuard Port** | `51820/UDP` |
| **Server Public Key** | `NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU=` |
| **Client Public Key** | `0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=` |
| **Service Status** | ✅ Active |
| **IP Forwarding** | ❌ Disabled (0) - **NEEDS FIX** |
| **Connection Status** | ⚠️ Not Connected |

---

## 🛠️ RECOMMENDED FIXES

### 1. Enable IP Forwarding (CRITICAL)
```bash
# Temporary (until reboot)
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Permanent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. Update Client Endpoint (if needed)
If client cannot connect, update their config:
```ini
Endpoint = 49.237.169.231:51820
```

### 3. Verify Firewall Rules
```bash
# Check FORWARD rules
sudo iptables -L FORWARD -n -v

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -n -v
```

---

## 📞 ACCESS INFORMATION

### Web Interface
- **URL:** `http://10.8.0.1/` (when connected via VPN)
- **Local:** `http://192.168.2.3/` (local network)

### SSH Access
- **Via VPN:** `ssh andre@10.8.0.1`
- **Local Network:** `ssh andre@192.168.2.3`
- **Password:** `0815`

---

*Last Updated: 2026-01-15*  
*Server: MoodePi5*
