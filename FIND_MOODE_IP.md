# 🔍 Finding moOde IP Address

**Methods to find moOde:**

---

## 🌐 METHOD 1: Try Common Fixed IPs

**Try these URLs in your browser:**

1. `http://192.168.10.2` (common static IP)
2. `http://192.168.178.161` (from previous config)
3. `http://10.10.11.39` (from previous config)
4. `http://192.168.1.100`
5. `http://192.168.0.100`

**Just open each one in browser and see which one shows moOde!**

---

## 📋 METHOD 2: Check Router Admin

1. Open router admin page (usually `192.168.1.1` or `192.168.0.1`)
2. Look for "Connected Devices" or "DHCP Clients"
3. Find device named:
   - "raspberrypi"
   - "moode"
   - "moodeaudio"
4. Note the IP address

---

## 🖥️ METHOD 3: Check Pi Screen

If you have a display connected to the Pi:
- moOde shows IP address on boot screen
- Or check moOde info page

---

## 🔧 METHOD 4: Scan Network

**Run this command:**
```bash
nmap -sn 192.168.1.0/24 | grep -i raspberry
```

**Or try:**
```bash
nmap -sn 192.168.0.0/24 | grep -i raspberry
```

---

## ✅ QUICKEST METHOD

**Just try these URLs one by one:**
- `http://192.168.10.2`
- `http://192.168.178.161`
- `http://10.10.11.39`

**One of them should work!**

---

**What IP address do you see on the Pi screen, or what does your router show?**

