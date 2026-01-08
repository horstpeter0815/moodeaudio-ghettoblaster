# 🔍 Finding Boot Partition

**The boot partition needs to be mounted separately!**

---

## 📋 STEP 1: Find Boot Partition

**Run this command:**
```bash
diskutil list
```

**Look for:**
- External disk (SD card)
- FAT32 partition (usually first partition)
- Usually named "bootfs" or similar

---

## 📋 STEP 2: Mount Boot Partition

**If you see a FAT32 partition (usually diskXs1), mount it:**
```bash
sudo diskutil mount /dev/diskXs1
```

**Replace X with your disk number (usually 4 or 5)**

---

## 📋 STEP 3: Create WiFi Config

**Once boot partition is mounted, create config:**
```bash
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
```

---

## 🔧 ALTERNATIVE: Check Disk Utility

**Or use Disk Utility:**
1. Open Disk Utility
2. Find SD card
3. Find FAT32 partition (boot partition)
4. Mount it
5. Then create wpa_supplicant.conf on that partition

---

**Run `diskutil list` first to find the boot partition!**

