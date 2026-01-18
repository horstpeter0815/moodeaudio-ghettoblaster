# 🔍 Find Pi - Action Plan

**Status:** Mac not connected to network "309"

---

## 🚨 STEP 1: Connect Mac to Network "309"

**You need to connect first:**

1. **Click WiFi icon** (top right menu bar)
2. **Select network:** `309`
3. **Enter password:** `Password`
4. **Wait for connection** (WiFi icon should show connected)

**Then tell me when connected, and I'll find the Pi automatically!**

---

## 🔍 STEP 2: Find Pi (After Connection)

**Once connected, I'll run:**
```bash
./FIND_PI_IP.sh
```

**This will:**
- Scan ARP table
- Scan network for Pi
- Show you the IP address

---

## 🌐 STEP 3: Access moOde

**Once we have the IP:**
- Open browser
- Go to: `http://<PI_IP>`
- Navigate to Audio page
- Test wizard!

---

## 📋 ALTERNATIVE: Manual Methods

**If automatic scan doesn't work:**

### **Method A: Check Router**
1. Open router admin page (usually `192.168.1.1` or `192.168.0.1`)
2. Look for "Connected Devices"
3. Find "raspberrypi" or "moode"
4. Note the IP address

### **Method B: Try Common IPs**
Try these in browser:
- `http://192.168.1.100`
- `http://192.168.0.100`
- `http://10.0.0.100`
- `http://192.168.1.50`
- `http://192.168.0.50`

### **Method C: Check Pi Screen**
If display is connected, Pi shows IP on boot screen

---

## ✅ NEXT ACTION

**Connect Mac to network "309" first, then I'll find the Pi!**

**Or if you already know the IP, just tell me and we can test the wizard!**

