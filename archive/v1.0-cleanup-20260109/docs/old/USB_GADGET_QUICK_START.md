# USB Gadget Mode - Quick Start

## 🚀 Quick Setup

### 1. Configure Pi (Before Building/Flashing)

```bash
cd ~/moodeaudio-cursor
./SETUP_USB_GADGET_MODE.sh
```

### 2. Build and Flash Image

```bash
./tools/build.sh --deploy
```

### 3. Boot Pi with USB Cable Connected

- Connect USB-C cable from Mac to Pi
- Boot Pi
- Wait 30-60 seconds

### 4. Configure Mac

```bash
./SETUP_USB_GADGET_MAC.sh
```

### 5. Connect!

```bash
ssh andre@192.168.10.2
```

Or open in browser: `http://192.168.10.2`

## 📋 Configuration

- **Pi IP:** 192.168.10.2
- **Mac IP:** 192.168.10.1
- **Interface:** usb0 (Pi) / USB Ethernet (Mac)

## 📖 Full Guide

See `docs/USB_GADGET_MODE_GUIDE.md` for detailed information.

