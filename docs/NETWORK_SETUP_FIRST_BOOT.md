# Network Setup - First Boot (moOde Standard)

**Problem:** Pi boots but has no network (IP: 127.0.1.1)  
**Date:** 2025-01-03

---

## Problem

After booting moOde standard image:
- IP address: 127.0.1.1 (loopback, no real network)
- No Ethernet connection
- WiFi not configured
- Cannot access via SSH or Web UI

---

## Solution Options

### Option 1: Connect Ethernet Cable (Easiest)

1. **Connect Ethernet cable** to Raspberry Pi
2. **Wait 30 seconds** for DHCP
3. **Find IP address:**
   - Check router admin panel
   - Or use network scanner
4. **Access via SSH:**
   ```bash
   ssh pi@PI_IP_ADDRESS
   # Default password: moodeaudio
   ```

---

### Option 2: Configure WiFi via moOde Web UI

If you can access the Web UI somehow:

1. **Access Web UI** (if IP known or via direct connection)
2. **Go to:** Configure → Network
3. **Select:** WiFi
4. **Enter credentials:**
   - SSID: Centara Nova Hotel
   - Security: WPA2/WPA3 (or as required)
   - Username: 309 (if required)
   - Password: password
5. **Save and restart**

---

### Option 3: Configure WiFi via SD Card (Before Boot)

**If SD card is accessible:**

1. **Mount boot partition** of SD card
2. **Create WiFi configuration file:**

File: `/Volumes/bootfs/wpa_supplicant.conf`

```conf
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Centara Nova Hotel"
    psk="password"
    # If hotel requires username:
    # identity="309"
    # password="password"
    # key_mgmt=WPA-EAP
    # eap=PEAP
}
```

3. **Eject SD card**
4. **Boot Pi**
5. **WiFi should connect automatically**

---

### Option 4: Configure WiFi via SSH (If Accessible)

If you can access Pi via SSH (local network, serial, etc.):

```bash
# Edit WiFi configuration
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

# Add network:
network={
    ssid="Centara Nova Hotel"
    psk="password"
}

# Restart networking
sudo systemctl restart networking
# Or
sudo wpa_cli reconfigure
```

---

## Hotel WiFi Specific

**Hotel:** Centara Nova Hotel  
**SSID:** Centara Nova Hotel  
**Username:** 309  
**Password:** password

**Note:** Hotel WiFi often requires:
- Web portal login (captive portal)
- WPA2-Enterprise with username
- Special authentication

If standard WPA2 doesn't work, you may need to:
1. Connect via Ethernet first
2. Access hotel WiFi portal
3. Configure WiFi via moOde Web UI

---

## Recommended Approach

1. **Connect Ethernet cable** (easiest, most reliable)
2. **Find IP address** (router or network scan)
3. **Access via SSH or Web UI**
4. **Configure WiFi through moOde interface**
5. **Disconnect Ethernet** (if WiFi works)

---

## Finding Pi IP Address

### Method 1: Router Admin Panel
- Log into router
- Check DHCP client list
- Look for "raspberrypi" or "moode" hostname

### Method 2: Network Scanner
```bash
# Scan local network
nmap -sn 192.168.1.0/24
# Or
arp -a | grep -i "raspberry\|moode"
```

### Method 3: Check Serial Console
- Connect serial cable
- Check IP address in boot messages

---

## After Network is Working

Once Pi has network:
1. ✅ SSH works
2. ✅ Web UI accessible
3. ✅ Can configure further settings
4. ✅ Can set up remote access

---

**Try Ethernet first - it's the easiest way to get network working.**




