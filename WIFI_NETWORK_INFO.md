# 📶 WiFi Network Information

**Date:** 2025-01-20  
**Network Changed**

---

## 🔐 NEW NETWORK CREDENTIALS

**Network Name (SSID):** `309`  
**Password:** `Password`

---

## 🔍 FINDING YOUR PI'S IP ADDRESS

### **Method 1: Check Router Admin Page**

1. Connect Mac to WiFi network `309`
2. Open router admin page (usually `192.168.1.1` or `192.168.0.1`)
3. Look for connected devices
4. Find "raspberrypi" or "moode" device
5. Note the IP address

---

### **Method 2: Scan Network (Mac Terminal)**

**Run this command:**
```bash
arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01"
```

**This searches for Raspberry Pi MAC addresses:**
- `b8:27:eb` - Raspberry Pi Foundation
- `dc:a6:32` - Raspberry Pi Foundation (newer)
- `e4:5f:01` - Raspberry Pi Foundation

---

### **Method 3: Use nmap (if installed)**

```bash
# Install nmap if needed: brew install nmap
# Then scan network:
nmap -sn 192.168.1.0/24 | grep -i raspberry
```

---

### **Method 4: Check moOde Screen**

If you have a display connected to the Pi:
- moOde shows IP address on boot screen
- Or check moOde web interface info page

---

## 🚀 CONNECTING TO NEW NETWORK

### **On Mac:**

1. **Click WiFi icon** in menu bar
2. **Select network:** `309`
3. **Enter password:** `Password`
4. **Wait for connection**

---

### **On iPhone:**

1. **Settings** → **WiFi**
2. **Select network:** `309`
3. **Enter password:** `Password`
4. **Connect**

---

## 📱 AFTER CONNECTING

**Once connected to `309` network:**

1. **Find Pi's IP address** (use methods above)
2. **Access moOde:**
   - Mac: `http://<PI_IP>`
   - iPhone: `https://<PI_IP>` (for microphone access)

---

## 🔧 IF PI ISN'T ON NEW NETWORK

**If Pi is still on old network:**

1. **Option A:** Connect Mac to old network temporarily
2. **Option B:** Reconfigure Pi to connect to new network `309`
   - SSH into Pi (if you know old IP)
   - Edit WiFi config
   - Reboot Pi

---

**Let me check your current network status...**

