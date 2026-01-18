# Checking Mac Ethernet Connection

## Quick Test

Run on your Mac:
```bash
cd ~/moodeaudio-cursor
bash TEST_MAC_ETHERNET.sh
```

## Manual Check

1. **Check if Ethernet interface exists:**
   ```bash
   ifconfig | grep -A 5 "en"
   ```
   Look for something like `en0`, `en1`, etc.

2. **Check if cable is connected:**
   ```bash
   ifconfig en0
   ```
   (Replace `en0` with your Ethernet interface name)
   
   Look for `status: active` - this means cable is connected.

3. **Check current IP:**
   ```bash
   ifconfig en0 | grep "inet "
   ```

4. **Test Internet Sharing:**
   - System Preferences > Sharing > Internet Sharing
   - Share from: [Your internet connection]  
   - To computers using: Ethernet
   - Enable checkbox
   - Ethernet should get IP: 192.168.10.1

## What to Check

- ✅ Ethernet cable connected to Mac
- ✅ Ethernet cable connected to Pi
- ✅ Mac shows "status: active" for Ethernet
- ✅ Internet Sharing enabled (if using DHCP mode)
- ✅ Mac Ethernet has IP (either from network or 192.168.10.1 if sharing)

## If Ethernet Works on Mac But Not Pi

Then the issue is on the Pi side:
- Pi's Ethernet port might be broken
- Pi's Ethernet driver not working
- Pi's network configuration not applying

## If Ethernet Doesn't Work on Mac

Then it's a hardware/cable issue:
- Try different Ethernet cable
- Try different Ethernet port on Mac
- Check if Mac Ethernet works with another device



