# USB Gadget Mode - Mac to Pi Connection Guide

This guide explains how to connect your Mac to the Raspberry Pi via USB cable using USB gadget mode.

## Overview

USB gadget mode allows the Raspberry Pi to act as a USB Ethernet device when connected to your Mac via USB cable. This is useful when:
- You don't have network access (no WiFi/Ethernet)
- You want a direct connection without a router
- You need to configure the Pi for the first time

## How It Works

- **Pi acts as:** USB Ethernet device (usb0 interface)
- **Mac sees:** USB Ethernet adapter
- **Pi IP:** 192.168.10.2
- **Mac IP:** 192.168.10.1

## Prerequisites

- Raspberry Pi 5 (or Pi 4)
- USB-C to USB-C cable (or USB-A to USB-C)
- Mac computer
- SD card with moOde image

## Setup Process

### Step 1: Configure Pi (Before Booting)

Run the setup script to configure USB gadget mode in the build:

```bash
cd ~/moodeaudio-cursor
./SETUP_USB_GADGET_MODE.sh
```

This script:
- Adds `dtoverlay=dwc2` to `config.txt`
- Adds `modules-load=dwc2,g_ether` to `cmdline.txt`
- Creates `usb-gadget-network.service` systemd service
- Configures Pi IP address (192.168.10.2)

### Step 2: Build and Flash Image

Build your custom image with USB gadget mode enabled:

```bash
cd ~/moodeaudio-cursor
./tools/build.sh --deploy
```

Or if using a pre-built image, apply the configuration to the SD card:

1. Mount SD card (bootfs and rootfs)
2. Run: `./SETUP_USB_GADGET_MODE.sh`
3. Eject SD card

### Step 3: Boot Pi with USB Cable

1. **Connect USB cable:**
   - Use USB-C to USB-C cable
   - Connect to USB port on Pi (not power-only port)
   - Connect to Mac USB port

2. **Boot Pi:**
   - Insert SD card
   - Power on Pi
   - Wait 30-60 seconds for boot

### Step 4: Configure Mac

Once Pi is booted, run the Mac configuration script:

```bash
cd ~/moodeaudio-cursor
./SETUP_USB_GADGET_MAC.sh
```

This script:
- Detects USB Ethernet interface
- Configures Mac IP address (192.168.10.1)
- Tests connection to Pi

### Step 5: Connect

After configuration, you can connect via SSH:

```bash
ssh andre@192.168.10.2
```

Or access moOde web interface:

```
http://192.168.10.2
```

## Troubleshooting

### Mac doesn't detect USB Ethernet

1. **Check cable:** Use data-capable USB cable (not power-only)
2. **Check port:** Use USB port on Pi (not power-only port)
3. **Wait:** Pi needs 30-60 seconds to boot and initialize USB gadget
4. **Check System Preferences:** Look for new network interface

### Pi not responding

1. **Check Pi boot:** Look for activity LED or display
2. **Wait longer:** USB gadget initialization can take time
3. **Check Mac IP:** Verify Mac has IP 192.168.10.1
4. **Ping test:** `ping 192.168.10.2`

### Connection works but SSH fails

1. **Check SSH service:** `systemctl status ssh` on Pi
2. **Check user:** Make sure `andre` user exists
3. **Check password:** Default password is `0815`
4. **Try serial console:** Use serial connection to debug

## Manual Configuration

### Mac Side (Manual)

1. Open **System Preferences > Network**
2. Find USB Ethernet interface
3. Configure manually:
   - IP Address: 192.168.10.1
   - Subnet Mask: 255.255.255.0
   - Router: (leave empty)

### Pi Side (Manual)

If USB gadget interface exists but no IP:

```bash
sudo ip link set usb0 up
sudo ip addr add 192.168.10.2/24 dev usb0
```

## Technical Details

### Files Modified

- `config.txt`: Added `dtoverlay=dwc2`
- `cmdline.txt`: Added `modules-load=dwc2,g_ether`
- `usb-gadget-network.service`: Systemd service for network configuration

### Network Configuration

- **Pi:** 192.168.10.2/24 on usb0 interface
- **Mac:** 192.168.10.1/24 on USB Ethernet interface
- **Subnet:** 192.168.10.0/24

### Service Details

The `usb-gadget-network.service`:
- Starts after network-pre.target
- Waits 2 seconds for usb0 interface
- Configures IP address automatically
- Runs on boot

## Notes

- USB gadget mode works alongside WiFi/Ethernet
- You can use USB connection and network simultaneously
- USB connection is useful for initial setup
- After network is configured, USB connection is optional

## Related Scripts

- `SETUP_USB_GADGET_MODE.sh` - Configure Pi for USB gadget mode
- `SETUP_USB_GADGET_MAC.sh` - Configure Mac for USB connection
- `CONFIGURE_MAC_ETHERNET_FOR_PI.sh` - Configure Mac for Ethernet connection

