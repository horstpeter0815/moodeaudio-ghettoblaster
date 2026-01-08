# USB Gadget Mode - Credentials & Setup

## ✅ Current Status

### Configuration:
- ✅ `config.txt`: USB gadget overlay configured (`dtoverlay=dwc2`)
- ✅ `cmdline.txt`: USB gadget modules configured (`modules-load=dwc2,g_ether`)
- ⏳ Service file: Created, needs sudo to complete setup

### Users Found:
- ✅ **andre** (UID 1000) - Password: **0815**

## 🔧 Complete Setup

Run this command to finish the setup:

```bash
cd ~/moodeaudio-cursor
sudo bash FINISH_USB_SETUP.sh
```

This will:
1. Set proper permissions on service file
2. Enable the USB gadget network service
3. Verify credentials

## 📋 Connection Credentials

### SSH Access:
- **Username:** `andre`
- **Password:** `0815`
- **Command:** `ssh andre@192.168.10.2`

### SMB File Sharing (Finder):
- **Username:** `andre`
- **Password:** `0815`
- **Server:** `smb://GhettoBlaster.local` or `smb://192.168.10.2`

### moOde Web Interface:
- **URL:** `http://192.168.10.2` or `http://GhettoBlaster.local`
- **Default moOde login:** Usually no login required, or check moOde docs

## 🚀 After Setup

1. **Eject SD card**
2. **Boot Pi with USB cable connected to Mac**
3. **On Mac, run:** `./SETUP_USB_GADGET_MAC.sh`
4. **Connect:** `ssh andre@192.168.10.2`

## 🔍 Troubleshooting

If connection doesn't work:
- Wait 30-60 seconds after Pi boots
- Check USB cable is data-capable (not power-only)
- Verify Mac shows USB Ethernet interface in System Preferences > Network
- Try: `ping 192.168.10.2`

