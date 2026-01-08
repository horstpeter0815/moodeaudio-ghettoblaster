# Unified Network Manager

## Overview

The Unified Network Manager is a mode-based network configuration system that automatically selects the appropriate connectivity method based on available interfaces and configuration.

## Network Modes

### 1. USB Gadget Mode (usb0)
- **Interface:** usb0
- **IP Address:** 192.168.10.2/24 (static)
- **When Used:** Automatically detected when USB gadget interface exists
- **Use Case:** Direct USB cable connection to Mac

### 2. Ethernet Static Mode (eth0)
- **Interface:** eth0
- **IP Address:** 192.168.10.2/24 (static)
- **Gateway:** 192.168.10.1
- **When Used:** Default mode for Ethernet connection (unless DHCP mode is selected)
- **Use Case:** Direct Ethernet cable connection to Mac

### 3. Ethernet DHCP Mode (eth0)
- **Interface:** eth0
- **IP Address:** Assigned via DHCP
- **When Used:** When `/boot/firmware/network-mode` file exists with content `ethernet-dhcp`
- **Use Case:** Mac Internet Sharing via Ethernet cable

### 4. WiFi Mode (wlan0)
- **Interface:** wlan0
- **IP Address:** Assigned via DHCP
- **Priority:** Lowest (only used if Ethernet not available)
- **When Used:** Automatically if no Ethernet interface available
- **Use Case:** WiFi network connection (when Ethernet unavailable)

## Priority Order

1. **USB Gadget** (highest priority)
2. **Ethernet Static** (default for Ethernet)
3. **Ethernet DHCP** (if explicitly configured)
4. **WiFi** (lowest priority)

## Configuration

### Enabling Ethernet DHCP Mode

To use Ethernet DHCP mode (for Mac Internet Sharing):

```bash
# On Mac, after mounting SD card boot partition:
echo "ethernet-dhcp" > /Volumes/bootfs/network-mode
```

Or create the file on the Pi after boot:
```bash
sudo bash -c 'echo "ethernet-dhcp" > /boot/firmware/network-mode'
sudo systemctl restart network-mode-manager.service
```

### Switching Back to Static Mode

Delete the network-mode file:
```bash
sudo rm /boot/firmware/network-mode
sudo systemctl restart network-mode-manager.service
```

## Services

### Main Service
- `network-mode-manager.service` - Main service that detects mode and configures network

### Mode-Specific Services
- `network-mode-usb-gadget.service` - USB gadget configuration
- `network-mode-ethernet-static.service` - Ethernet static IP configuration
- `network-mode-ethernet-dhcp.service` - Ethernet DHCP configuration
- `network-mode-wifi.service` - WiFi configuration

## Disabled Services

The following conflicting services are automatically disabled:
- `00-boot-network-ssh.service`
- `02-eth0-configure.service`
- `03-network-configure.service`
- `04-network-lan.service`

## Application to SD Card

To apply the unified network manager to a mounted SD card:

```bash
cd ~/moodeaudio-cursor
sudo bash scripts/network/APPLY_UNIFIED_NETWORK.sh
```

## Logs

Network mode manager logs are available at:
```bash
tail -f /var/log/network-mode-manager.log
```

## Troubleshooting

### Check Current Mode
```bash
systemctl status network-mode-manager.service
journalctl -u network-mode-manager.service -n 50
```

### Check Active Interface
```bash
ip addr show
```

### Manually Trigger Mode Detection
```bash
sudo /usr/local/bin/network-mode-manager.sh
```

### Verify NetworkManager Configuration
```bash
nmcli connection show
nmcli connection show "Ethernet"
```

## Architecture

The unified network manager works as follows:

1. **Detection Phase**: Scans for available interfaces (usb0, eth0, wlan0)
2. **Mode Selection**: Chooses mode based on interface availability and configuration files
3. **Configuration Phase**: Configures selected interface with appropriate IP method
4. **Conflict Resolution**: Disables conflicting services
5. **NetworkManager Integration**: Configures NetworkManager if DHCP or WiFi mode

This ensures only one service manages network configuration, eliminating conflicts.



