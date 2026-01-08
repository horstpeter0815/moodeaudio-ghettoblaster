# Fix USB Gadget 127.x.x.x Issue

## Problem
Pi shows 127.x.x.x IP address (localhost) instead of 192.168.10.2

## What 127.x.x.x Means
- **127.0.0.1** = localhost (the Pi itself)
- This means USB gadget network interface (usb0) is NOT configured
- The USB gadget hardware might be working, but network isn't set up

## Possible Causes

1. **Service file not created/enabled** on SD card
2. **USB gadget interface exists but no IP assigned**
3. **Mac not configured** to recognize USB Ethernet
4. **USB cable issue** (power-only vs data-capable)

## Solutions

### Solution 1: Check if USB Gadget Interface Exists

On Pi (via SSH if you have network access, or serial console):

```bash
# Check if usb0 interface exists
ls /sys/class/net/usb0

# If it exists, manually configure it:
sudo ip link set usb0 up
sudo ip addr add 192.168.10.2/24 dev usb0

# Check if it worked:
ip addr show usb0
```

### Solution 2: Verify Service File Was Created

If you have SD card mounted or SSH access:

```bash
# Check if service file exists:
ls -la /lib/systemd/system/usb-gadget-network.service

# Check if service is enabled:
ls -la /etc/systemd/system/multi-user.target.wants/usb-gadget-network.service

# If missing, create it (see FINISH_USB_SETUP.sh)
```

### Solution 3: Check Mac Side

On Mac, check if USB Ethernet interface appears:

```bash
# List network interfaces
networksetup -listallhardwareports | grep -i usb

# Check if any interface has 192.168.10.1
ifconfig | grep "192.168.10"
```

### Solution 4: Manual Configuration on Pi

If USB gadget hardware works but network doesn't auto-configure:

```bash
# On Pi, create manual network script:
sudo nano /usr/local/bin/usb-gadget-network.sh

# Add:
#!/bin/bash
sleep 5
if [ -d /sys/class/net/usb0 ]; then
    ip link set usb0 up
    ip addr add 192.168.10.2/24 dev usb0
fi

# Make executable:
sudo chmod +x /usr/local/bin/usb-gadget-network.sh

# Add to /etc/rc.local or create systemd service
```

## Quick Test

1. **Check USB gadget hardware:**
   ```bash
   ls /sys/class/net/usb0
   ```

2. **If exists, manually configure:**
   ```bash
   sudo ip link set usb0 up
   sudo ip addr add 192.168.10.2/24 dev usb0
   ```

3. **On Mac, configure USB Ethernet:**
   ```bash
   cd ~/moodeaudio-cursor
   ./SETUP_USB_GADGET_MAC.sh
   ```

4. **Test connection:**
   ```bash
   ping 192.168.10.2
   ```

## If Nothing Works

1. **Power off Pi**
2. **Re-mount SD card on Mac**
3. **Run:** `sudo bash FINISH_USB_SETUP.sh`
4. **Verify service file exists and is enabled**
5. **Eject and boot again**

