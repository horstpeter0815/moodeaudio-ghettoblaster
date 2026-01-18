# WireGuard Connection Troubleshooting Guide

## For Your Friend - Complete Checklist

### ✅ Server Status (Verified Working)
- **Server Public Key:** `NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU=`
- **Server Endpoint:** `223.206.210.138:51820`
- **Server is running and listening** ✅
- **Port 51820/UDP is open** ✅
- **Firewall rules are correct** ✅

### ⚠️ Client Configuration Must Match Exactly

Your friend's WireGuard config must have:

```ini
[Interface]
PrivateKey = FRIEND_PRIVATE_KEY_HERE
Address = 10.8.0.2/24

[Peer]
PublicKey = NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU=
Endpoint = 223.206.210.138:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
```

### 🔍 Critical Checks for Your Friend

#### 1. Verify Private Key Matches Public Key
The private key MUST generate this exact public key:
```
0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w=
```

**To verify on Windows:**
- Install WireGuard tools or use online tool
- Or check in WireGuard GUI - the public key shown must match exactly

#### 2. Check Server Public Key in Client Config
Must be exactly:
```
NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU=
```

#### 3. Check Server Endpoint
Must be exactly:
```
223.206.210.138:51820
```

#### 4. Check WireGuard App Status
- Is WireGuard showing "Active" (green)?
- Are there any error messages in the app?
- Check WireGuard logs for errors

#### 5. Network/Firewall Checks
- Can ping the server? `ping 223.206.210.138`
- Is outbound UDP 51820 allowed?
- Try from different network (mobile hotspot)

#### 6. Reconnect Steps
1. Disconnect WireGuard completely
2. Wait 5 seconds
3. Reconnect WireGuard
4. Wait 10 seconds
5. Check if handshake appears

### 🛠️ What We Can Do on Server Side

1. ✅ Server config is correct
2. ✅ Firewall rules are in place
3. ✅ WireGuard is running
4. ✅ Port is open and accessible
5. ✅ ICMP rules are configured

### 📋 Next Steps

1. **Verify client's private key** generates the correct public key
2. **Double-check all config values** match exactly
3. **Try reconnecting** WireGuard
4. **Check client-side logs** for errors
5. **Test from different network** if possible

### 🔗 Quick Test Commands (for your friend)

**On Windows (if WireGuard tools installed):**
```cmd
wg show
ping 10.8.0.1
```

**Check if server is reachable:**
```cmd
ping 223.206.210.138
```

---

*Last updated: After server config fix with NFTlD key*
