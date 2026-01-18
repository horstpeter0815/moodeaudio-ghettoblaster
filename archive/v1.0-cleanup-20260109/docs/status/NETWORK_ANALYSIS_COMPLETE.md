# Network Analysis - moOde Audio

## CONFIRMED: moOde Uses NetworkManager

**Source:** `moode-source/www/inc/network.php`

### Key Findings:

1. **NetworkManager is used** (NOT systemd-networkd, NOT wpa_supplicant directly)
   - Line 16: `sysCmd('rm -f /etc/NetworkManager/system-connections/*');`
   - Function `cfgNetworks()` creates NetworkManager connection files

2. **Ethernet Configuration:**
   - File: `/etc/NetworkManager/system-connections/Ethernet.nmconnection`
   - UUID: `f8eba0b7-862d-4ccc-b93a-52815eb9c28d` (fixed)
   - autoconnect=true
   - method=auto (DHCP) by default
   - Created by cfgNetworks() from database

3. **WiFi Configuration:**
   - worker.php (line 397) imports `/etc/NetworkManager/system-connections/preconfigured.nmconnection`
   - If found, imports SSID/PSK into database
   - Then cfgNetworks() creates connection file from database
   - Format: `{SSID}.nmconnection`

4. **The Problem:**
   - Pi Imager creates `wpa_supplicant.conf` on `/boot/firmware/`
   - moOde expects `preconfigured.nmconnection` in `/etc/NetworkManager/system-connections/`
   - worker.php runs AFTER boot (via cron/daemon)
   - Conversion must happen BEFORE worker.php runs OR before NetworkManager starts

## Solution Requirements:

1. Convert `wpa_supplicant.conf` → `preconfigured.nmconnection`
2. Place in `/etc/NetworkManager/system-connections/preconfigured.nmconnection`
3. Must happen BEFORE worker.php runs OR NetworkManager must be configured to import from /boot/firmware/

## Correct Approach:

Create a systemd service that:
1. Runs VERY EARLY (Before NetworkManager)
2. Checks `/boot/firmware/wpa_supplicant.conf`
3. Converts to `/etc/NetworkManager/system-connections/preconfigured.nmconnection`
4. OR copies `/boot/firmware/preconfigured.nmconnection` if it exists
5. Ensures NetworkManager can import it




