# 🔌 Direct Ethernet Connection Guide

**Mac connected to Pi via Ethernet cable**

---

## 🔧 STEP 1: Configure Mac Ethernet

**The Mac might need to configure the Ethernet interface:**

1. **Open System Settings** (or System Preferences)
2. **Go to Network**
3. **Select Ethernet** (or "USB 10/100/1000 LAN" if using adapter)
4. **Configure IPv4:**
   - Set to: **Manually**
   - IP Address: `192.168.10.1`
   - Subnet Mask: `255.255.255.0`
   - Router: (leave empty)
5. **Click Apply**

---

## 🔍 STEP 2: Test Connection

**After configuring, test:**

```bash
ping -c 3 192.168.10.2
```

**If ping works, then try:**
```
http://192.168.10.2
```

---

## 🌐 STEP 3: Access moOde

**Once connection works:**
1. Open browser
2. Go to: `http://192.168.10.2`
3. moOde should load!

---

## 🔧 ALTERNATIVE: Let Mac Auto-Configure

**Or try DHCP (let Mac get IP automatically):**

1. **System Settings** → **Network** → **Ethernet**
2. **Configure IPv4:** Set to **Using DHCP**
3. **Apply**
4. **Wait 30 seconds**
5. **Then try:** `http://192.168.10.2` or check what IP Mac got

---

## 📋 QUICK TEST

**Try these in browser while Ethernet is connected:**

- `http://192.168.10.2` (Pi's configured IP)
- `http://moode.local`
- `http://raspberrypi.local`

---

**Configure Mac's Ethernet first, then we can access moOde!**

