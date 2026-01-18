# 🔄 Reboot Pi with Ethernet Connected

**Steps to ensure Ethernet works:**

---

## ✅ STEP 1: Ensure Ethernet Cable is Connected

**Before rebooting:**
- ✅ Ethernet cable is plugged into Pi
- ✅ Ethernet cable is plugged into Mac
- ✅ Cable is securely connected on both ends

---

## 🔌 STEP 2: Reboot Pi

**Power cycle the Pi:**
1. **Power off Pi** (unplug power cable)
2. **Wait 5 seconds**
3. **Plug power cable back in**
4. **Wait 2-3 minutes** for Pi to fully boot

---

## ⏰ STEP 3: Wait for Boot

**After powering on:**
- LED will blink during boot
- Wait until LED stops rapid blinking
- Give it **2-3 minutes** for full boot

---

## 🌐 STEP 4: Test Connection

**After 2-3 minutes, test:**

1. **In Terminal, run:**
   ```bash
   ping -c 3 192.168.10.2
   ```

2. **In Browser, try:**
   ```
   http://192.168.10.2
   ```

---

## ✅ EXPECTED RESULT

**After reboot:**
- ✅ Ping should work (packets received)
- ✅ Browser should load moOde
- ✅ You can access moOde web interface

---

## 🎯 ONCE IT WORKS

**When moOde loads:**
1. Navigate to **Audio** page
2. Click **"Run Wizard"** button
3. Test all 6 wizard steps!

---

**Go ahead and reboot the Pi now. After it boots, I'll test the connection again!**

