# WiFi and AirPlay Fix - 2026-01-20

## Problem
- WiFi was not connecting (wlan0 showed "unavailable")
- AirPlay only worked on Ethernet, not WiFi
- User's iPhone on "NAM YANG 2" network couldn't see AirPlay

## Root Cause
**NetworkManager WiFi radio was DISABLED**

## Solution
```bash
sudo nmcli radio wifi on
sudo nmcli connection up 'NAM YANG 2'
```

## Result
- WiFi connected: **192.168.1.159** (NAM YANG 2 network)
- Ethernet still active: **192.168.2.3** (different network)
- AirPlay now advertised on BOTH interfaces:
  - `wlan0`: AirPlay services visible
  - `end0`: AirPlay services visible

## Verification
```bash
avahi-browse -a -t | grep -i airplay
# Shows AirPlay on wlan0 and end0
```

## Network Architecture Understanding
- Pi has TWO network interfaces active simultaneously:
  - **Ethernet (end0)**: 192.168.2.x network
  - **WiFi (wlan0)**: 192.168.1.x network (NAM YANG 2)
- Devices must be on the SAME network to see AirPlay
- If iPhone is on 192.168.1.x → use WiFi connection
- If device is on 192.168.2.x → use Ethernet connection

## To Make WiFi Persistent
Need to ensure WiFi radio is enabled on boot. Check moOde's network initialization in `worker.php`.

## Related Code
- `/var/www/inc/network.php`: `cfgNetworks()` function generates NetworkManager connection files
- Connection files: `/etc/NetworkManager/system-connections/*.nmconnection`
- Shairport Sync config: `/etc/shairport-sync.conf`
