# 📶 WiFi Configuration Guide

**Network:** `309`  
**Password:** `Password`

---

## 🚀 QUICK SETUP

**Run this command:**
```bash
sudo ./configure-wifi-309.sh
```

**What it does:**
- Creates `wpa_supplicant.conf` on boot partition
- Configures Pi to connect to network "309"
- WiFi will connect automatically on next boot

---

## 📋 MANUAL SETUP (Alternative)

If the script doesn't work, create the file manually:

**1. Create file on boot partition:**
```bash
sudo nano /Volumes/bootfs/wpa_supplicant.conf
```

**2. Paste this content:**
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="309"
    psk="Password"
    key_mgmt=WPA-PSK
}
```

**3. Save and exit (Ctrl+X, Y, Enter)**

---

## ✅ VERIFICATION

**After booting Pi:**

1. **Check if Pi connected:**
   - Look for WiFi LED on Pi (if available)
   - Check router admin page for device "raspberrypi" or "moode"

2. **Find Pi's IP address:**
   ```bash
   arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01"
   ```

3. **Access moOde:**
   - Mac: `http://<PI_IP>`
   - iPhone: `https://<PI_IP>`

---

## 🔧 TROUBLESHOOTING

**If Pi doesn't connect:**

1. **Check file exists:**
   ```bash
   ls -la /Volumes/bootfs/wpa_supplicant.conf
   ```

2. **Check file content:**
   ```bash
   cat /Volumes/bootfs/wpa_supplicant.conf
   ```

3. **Verify network name and password are correct:**
   - Network: `309`
   - Password: `Password`

4. **Check if boot partition is writable:**
   ```bash
   touch /Volumes/bootfs/test.txt && rm /Volumes/bootfs/test.txt
   ```

---

## 📱 AFTER CONFIGURATION

**Once Pi boots and connects:**

1. **Connect Mac to network "309"**
2. **Find Pi's IP address**
3. **Access moOde web interface**
4. **Test wizard!**

---

**Ready to configure? Run: `sudo ./configure-wifi-309.sh`**

