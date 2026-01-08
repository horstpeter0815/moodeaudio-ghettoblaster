# 🔧 Ethernet Troubleshooting

**Connection still not working after reboot**

---

## 🔍 CURRENT STATUS

- ✅ Mac configured: `192.168.10.1`
- ⚠️ Pi detected but not responding: `192.168.10.2`
- ❌ Connection timeout

---

## 🔧 TROUBLESHOOTING STEPS

### **Step 1: Check Ethernet Cable**

- ✅ Cable plugged into Pi?
- ✅ Cable plugged into Mac?
- ✅ Try unplugging and replugging both ends
- ✅ Try a different Ethernet cable if available

---

### **Step 2: Check Mac Ethernet Settings**

**Verify Mac is still configured:**

1. **System Settings** → **Network** → **Ethernet**
2. **Check TCP/IP:**
   - Should be: **Manually**
   - IP: `192.168.10.1`
   - Subnet: `255.255.255.0`
3. **If wrong, fix it and Apply**

---

### **Step 3: Check Pi Ethernet LED**

**On the Pi:**
- Is Ethernet LED blinking? (shows activity)
- If no LED, check if cable is detected

---

### **Step 4: Try Different Approach**

**The Pi might be using WiFi instead of Ethernet:**

1. **Check Pi screen** - does it show an IP address?
2. **If it shows an IP, try that IP in browser**
3. **Or disconnect WiFi on Pi** (if possible) to force Ethernet

---

### **Step 5: Alternative - Use WiFi**

**If Ethernet doesn't work:**
- Connect Mac to WiFi network "309"
- Find Pi's WiFi IP address
- Access moOde via WiFi

---

## 🎯 QUICK TEST

**Try in browser:**
```
http://192.168.10.2
```

**If still timeout:**
- Check Ethernet cable connection
- Check Mac network settings
- Check Pi screen for IP address

---

## 📋 WHAT TO CHECK

1. ✅ Ethernet cable securely connected?
2. ✅ Mac still configured at 192.168.10.1?
3. ✅ Pi Ethernet LED blinking?
4. ✅ What IP does Pi screen show?

---

**Check these and let me know what you find!**

