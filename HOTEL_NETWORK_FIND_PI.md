# 🏨 Finding Pi in Hotel Network

**Since we can't access router admin, here's what to do:**

---

## ✅ METHOD 1: Check Pi Screen (Easiest!)

**If you have a display connected to the Pi:**
- moOde shows IP address on boot screen
- Look for text like: "IP: 192.168.x.x" or "http://192.168.x.x"

**Just tell me the IP you see!**

---

## ✅ METHOD 2: Try Common Hotel Network IPs

**Hotel networks usually use these ranges. Try these URLs in browser:**

### **192.168.x.x range:**
- `http://192.168.1.100`
- `http://192.168.1.50`
- `http://192.168.0.100`
- `http://192.168.0.50`
- `http://192.168.2.100`

### **10.x.x.x range:**
- `http://10.0.0.100`
- `http://10.0.1.100`
- `http://10.1.1.100`

### **172.27.x.x range (your Mac's network):**
- `http://172.27.3.100`
- `http://172.27.3.50`
- `http://172.27.1.100`

**Just open each URL in browser and see which one shows moOde!**

---

## ✅ METHOD 3: Use Pi's Hostname

**Try these in browser:**
- `http://moode.local`
- `http://raspberrypi.local`
- `http://moodeaudio.local`

**If mDNS works, one of these should work!**

---

## 🎯 QUICKEST SOLUTION

**Just try these 3 URLs first:**
1. `http://moode.local`
2. `http://192.168.1.100`
3. `http://172.27.3.100`

**One of them should work!**

---

## 📱 ALTERNATIVE: Use iPhone

**If you have iPhone:**
1. Connect iPhone to network "309"
2. Open Safari
3. Try: `http://moode.local` or `http://raspberrypi.local`
4. Or try the IP addresses above

---

## 🔧 IF NOTHING WORKS

**We might need to:**
1. Wait until you're on a home network
2. Or connect Pi directly to Mac via Ethernet cable
3. Or check Pi's screen for IP address

---

**What IP do you see on the Pi screen? Or which URL works?**

