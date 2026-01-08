# ⚡ Quick Ethernet Fix

**Mac connected to Pi via Ethernet cable**

---

## ✅ CURRENT STATUS

- ✅ Ethernet cable connected
- ✅ Mac interface `en8` is up
- ⚠️ Mac has auto-assigned IP (169.254.x.x)
- 🎯 Pi should be at: `192.168.10.2`

---

## 🚀 QUICK TEST

**Try this in your browser RIGHT NOW:**
```
http://192.168.10.2
```

**If it works, great! If not, configure Mac:**

---

## 🔧 CONFIGURE MAC (If needed)

**If browser doesn't work, configure Mac's Ethernet:**

1. **Open System Settings** (or System Preferences)
2. **Network** → Find **Ethernet** (or USB Ethernet adapter)
3. **Click "Details" or gear icon**
4. **TCP/IP tab:**
   - Configure IPv4: **Manually**
   - IP Address: `192.168.10.1`
   - Subnet Mask: `255.255.255.0`
   - Router: (leave empty)
5. **Click OK / Apply**
6. **Wait 10 seconds**
7. **Try browser:** `http://192.168.10.2`

---

## 🎯 ALTERNATIVE: Try These URLs

**While Ethernet is connected, try:**

- `http://192.168.10.2` ← **Most likely!**
- `http://moode.local`
- `http://raspberrypi.local`

---

## ✅ ONCE IT WORKS

**When moOde loads:**
1. Navigate to **Audio** page
2. Click **"Run Wizard"**
3. Test all 6 steps!

---

**Try `http://192.168.10.2` in browser first - it might work already!**

