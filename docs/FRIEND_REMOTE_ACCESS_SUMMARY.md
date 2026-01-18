# Remote Access Summary - moOde Audio Player

## 🎵 Welcome!

This document provides everything you need to remotely access and control the moOde Audio Player system.

---

## 📋 What You Can Do

Once connected, you can:
- ✅ Access the web-based audio player interface
- ✅ Control playback (play, pause, skip, volume)
- ✅ Browse and play music library
- ✅ Access radio stations
- ✅ SSH into the system for troubleshooting
- ✅ View system status and logs

---

## 🚀 Quick Setup (5 Minutes)

### 1. Install WireGuard
- **Windows/Mac:** https://www.wireguard.com/install/
- **Mobile:** "WireGuard" app from app store
- **Linux:** `sudo apt-get install wireguard wireguard-tools`

### 2. Generate Your Keys

**Easy way (Windows/Mac GUI):**
- Open WireGuard → "Add Tunnel" → "Add Empty Tunnel"
- Copy your **Public Key** from the config window

**Command line:**
```bash
wg genkey | tee private.key | wg pubkey > public.key
cat public.key
```

### 3. Send Your Public Key
Email or message your public key to the administrator.

### 4. Receive Configuration
You'll get a configuration file. Import it into WireGuard.

### 5. Connect & Access
- Connect WireGuard (toggle switch)
- Open browser: `http://10.8.0.1/`
- Enjoy! 🎶

---

## 🔧 Access Information

| Service | Address | Details |
|---------|---------|---------|
| **Web Player** | `http://10.8.0.1/` | Main interface |
| **SSH Access** | `ssh andre@10.8.0.1` | Password: `0815` |
| **VPN Server** | `10.8.0.1` | Your IP: `10.8.0.2` |

---

## ❗ Common Problems & Quick Fixes

### Problem: "Cannot connect to WireGuard"

**Quick Fix:**
1. Check server is online: `ping YOUR_SERVER_IP`
2. Verify port 51820/UDP is not blocked
3. Try different network (some block VPNs)
4. Contact administrator to check server status

---

### Problem: "Web interface won't load"

**Quick Fix:**
1. Verify WireGuard is connected (green indicator)
2. Test connection: `ping 10.8.0.1`
3. Clear browser cache: `Ctrl+Shift+Delete`
4. Try incognito/private mode
5. Try different browser

---

### Problem: "SSH connection fails"

**Quick Fix:**
1. Verify WireGuard connection: `ping 10.8.0.1`
2. Try: `ssh andre@10.8.0.1`
3. Password: `0815`
4. If "host key changed" error:
   ```bash
   ssh-keygen -R 10.8.0.1
   ssh -o StrictHostKeyChecking=accept-new andre@10.8.0.1
   ```

---

### Problem: "Connection drops frequently"

**Quick Fix:**
1. Ensure `PersistentKeepalive = 25` is in your config
2. Check your internet connection stability
3. Update WireGuard to latest version

---

### Problem: "Audio not playing"

**Quick Fix:**
1. Check volume in web interface (not muted)
2. Verify MPD is running (ask administrator)
3. Try different audio source (radio vs library)
4. Check browser console for errors (F12)

---

### Problem: "Slow or laggy interface"

**Quick Fix:**
1. Check your internet speed
2. Close other bandwidth-heavy applications
3. Try reducing MTU in WireGuard config to 1280
4. Check server resources (ask administrator)

---

## 📚 Detailed Documentation

For comprehensive troubleshooting and advanced setup:
- **Full Guide:** `docs/REMOTE_ACCESS_GUIDE.md`
- **Quick Start:** `docs/QUICK_START_REMOTE_ACCESS.md`

---

## 🔐 Security Notes

1. **Keep your private key secret** - Never share it
2. **Only share your public key** - Safe to share
3. **Use strong SSH password** - Consider changing from default
4. **Keep WireGuard updated** - Regular updates improve security

---

## 📞 Getting Help

If you encounter issues:

1. **Check the troubleshooting section above**
2. **Verify your connection:**
   ```bash
   ping 10.8.0.1
   curl http://10.8.0.1/
   ```

3. **Collect information:**
   - WireGuard status: `sudo wg show` (Linux) or check GUI
   - Error messages from browser console (F12)
   - Connection test results

4. **Contact administrator:**
   - Describe the problem clearly
   - Include error messages
   - Share test results

---

## 🎯 Quick Reference Commands

```bash
# Check WireGuard status
sudo wg show                    # Linux
# Or check GUI on Windows/Mac

# Test connection
ping 10.8.0.1

# Test web interface
curl http://10.8.0.1/

# SSH access
ssh andre@10.8.0.1
# Password: 0815

# Restart WireGuard (Linux)
sudo wg-quick down wg0
sudo wg-quick up wg0
```

---

## 📊 System Information

**Server Details:**
- Hostname: MoodePi5
- OS: Debian GNU/Linux 13
- moOde Version: 10.0.1
- Audio: HiFiBerry AMP100

**Network:**
- VPN Network: 10.8.0.0/24
- Server VPN IP: 10.8.0.1
- Your VPN IP: 10.8.0.2
- WireGuard Port: 51820/UDP

**Server Public Key:**
```
MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ=
```

---

## ✅ Checklist

Before contacting support, verify:

- [ ] WireGuard is installed and running
- [ ] WireGuard shows "Active" (green indicator)
- [ ] Can ping server: `ping 10.8.0.1` works
- [ ] Browser can access: `http://10.8.0.1/`
- [ ] Tried clearing browser cache
- [ ] Tried different browser
- [ ] Checked firewall/antivirus settings
- [ ] WireGuard is up to date

---

## 🎉 Enjoy Your Remote Access!

Once everything is set up, you can control the audio player from anywhere in the world. The web interface provides full control over playback, library management, and system settings.

**Happy listening! 🎵**

---

*Document Version: 1.0*  
*Last Updated: 2026-01-14*  
*For technical support, contact the system administrator*
