# 🎯 DO THIS NOW - WiFi Setup

## Step 1: Apply WiFi Config to SD Card

**Run this command:**
```bash
cd ~/moodeaudio-cursor
sudo ./APPLY_WIFI_CONFIG.sh
```

**OR manually:**
```bash
sudo cp /tmp/wpa_moode.conf /Volumes/bootfs/wpa_supplicant.conf
```

## Step 2: Set Up Mac Hotspot

1. **System Preferences > Sharing**
2. **Enable "Internet Sharing"**
3. **Share from:** Ethernet
4. **To:** Wi-Fi
5. **Wi-Fi Options:**
   - Network Name: `moode-audio`
   - Password: `moode0815`
   - Channel: 11
   - Security: WPA2/WPA3
6. **Enable Internet Sharing**

## Step 3: Boot Pi

- Pi will connect to "moode-audio" automatically
- Find Pi IP: `ping moode.local` or check router
- Access: `http://moode.local` or `http://[Pi IP]`

---

**Run the commands NOW!**

