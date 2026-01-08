# 📶 Setup Hotel WiFi on SD Card

**Network:** Centara Nova Hotel  
**Username:** 309  
**Password:** Password

---

## 🔧 MANUAL SETUP (Since I can't run sudo)

**Run these commands in Terminal:**

```bash
# 1. Create wpa_supplicant.conf on boot partition
sudo tee /Volumes/bootfs/wpa_supplicant.conf > /dev/null << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Centara Nova Hotel"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="309"
    password="Password"
    phase2="auth=MSCHAPV2"
}
EOF

# 2. Verify it was created
cat /Volumes/bootfs/wpa_supplicant.conf
```

---

## 📋 OR USE NANO

**If bootfs is mounted:**

```bash
sudo nano /Volumes/bootfs/wpa_supplicant.conf
```

**Paste this:**
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Centara Nova Hotel"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="309"
    password="Password"
    phase2="auth=MSCHAPV2"
}
```

**Save:** Ctrl+X, Y, Enter

---

## ✅ AFTER CREATING

1. **Eject SD card**
2. **Boot Pi**
3. **Pi will connect to hotel WiFi**
4. **Find Pi's IP and test wizard!**

---

**Run the commands above to configure WiFi!**

