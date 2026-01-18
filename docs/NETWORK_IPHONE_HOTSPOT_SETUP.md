# Network Setup: Mac + iPhone Hotspot + Pi

## Overview
You can connect your Mac to iPhone hotspot for internet **AND** still access the Pi via Ethernet simultaneously. macOS supports multiple network interfaces (multi-homing).

## Configuration

### Mac Network Setup

**1. WiFi Interface (iPhone Hotspot):**
- Connect to iPhone hotspot via WiFi
- Gets internet access automatically
- IP assigned by iPhone (typically 172.20.10.x)

**2. Ethernet Interface (Pi Connection):**
- Connect Ethernet cable to Pi
- Configure with **static IP**:
  - IP Address: `192.168.10.1`
  - Subnet Mask: `255.255.255.0` (or `/24`)
  - **DO NOT set default gateway** (keeps internet via WiFi)
  - **DO NOT set DNS** (uses WiFi DNS)

### Pi Configuration
- IP: `192.168.10.2`
- Gateway: `192.168.10.1` (Mac Ethernet)
- Subnet: `192.168.10.0/24`

## How to Configure Mac Ethernet

### Via System Settings (macOS Ventura+):
1. System Settings → Network
2. Select Ethernet interface
3. Configure IPv4: **Manually**
4. IP Address: `192.168.10.1`
5. Subnet Mask: `255.255.255.0`
6. **Leave Router/DNS empty** (or set to 192.168.10.1 if required, but don't use as default route)

### Via Terminal:
```bash
# Set static IP on Ethernet (replace en1 with your Ethernet interface)
sudo ifconfig en1 192.168.10.1 netmask 255.255.255.0

# Verify
ifconfig en1
ping -c 2 192.168.10.2
```

## Verification

```bash
# Check Mac interfaces
ifconfig | grep -E "^[a-z]|inet "

# Test Pi connectivity
ping -c 2 192.168.10.2

# Test internet (should work via WiFi)
ping -c 2 8.8.8.8

# Check routing
netstat -rn | grep default
```

## Important Notes

1. **Service Order**: macOS automatically routes internet traffic via WiFi (higher priority) and local traffic via Ethernet
2. **No Conflicts**: The two networks (iPhone hotspot and Pi Ethernet) are separate and don't interfere
3. **Pi Internet**: If Pi needs internet, it can route through Mac Ethernet (192.168.10.1), which forwards to WiFi
4. **SSH Access**: `ssh andre@192.168.10.2` will work normally

## Troubleshooting

**Problem**: Can't reach Pi after connecting to iPhone hotspot
- **Solution**: Ensure Ethernet has static IP 192.168.10.1 and no default gateway

**Problem**: Mac loses internet when Ethernet is connected
- **Solution**: Remove default gateway from Ethernet interface (keep WiFi as default route)

**Problem**: Pi can't access internet
- **Solution**: Enable IP forwarding on Mac (if needed):
  ```bash
  sudo sysctl -w net.inet.ip.forwarding=1
  ```

## Summary

✅ **This setup works perfectly!**
- Mac gets internet via iPhone hotspot
- Mac accesses Pi via Ethernet (192.168.10.2)
- No conflicts or issues
- Standard macOS multi-homing behavior
