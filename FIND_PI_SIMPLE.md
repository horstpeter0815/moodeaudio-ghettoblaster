# 🔍 Simple Way to Find Pi IP

**Since automatic scan didn't work, here's the easiest way:**

---

## ✅ METHOD 1: Check Router (Easiest!)

1. **Open router admin page:**
   - Usually: `http://192.168.1.1` or `http://192.168.0.1`
   - Or check router label for admin URL

2. **Login** (password usually on router label)

3. **Look for "Connected Devices" or "DHCP Clients"**

4. **Find device named:**
   - "raspberrypi"
   - "moode"
   - "moodeaudio"
   - Or look for device with Raspberry Pi MAC address (starts with b8:27:eb or dc:a6:32)

5. **Note the IP address**

---

## ✅ METHOD 2: Check Pi Screen

If you have a display connected:
- moOde shows IP address on boot screen
- Or check moOde info page

---

## ✅ METHOD 3: Try Common IPs in Browser

**Just open these URLs one by one in your browser:**

- `http://192.168.1.100`
- `http://192.168.0.100`
- `http://192.168.1.50`
- `http://192.168.0.50`
- `http://172.27.3.100` (same network as your Mac)
- `http://172.27.3.50`

**One of them should show moOde!**

---

## 🎯 QUICKEST: Just Tell Me!

**What IP address do you see?**
- On Pi screen?
- In router admin?
- Or just try the URLs above and tell me which one works!

---

**Once we have the IP, we can test the wizard immediately!** 🚀

