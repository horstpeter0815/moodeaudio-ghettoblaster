# Internet Sharing Setup

## What You Did
You've enabled Internet Sharing on your Mac via Ethernet. This allows the Pi to access the internet through your Mac's connection.

## How It Works
- **Mac:** Shares internet connection via Ethernet
- **Pi:** Connects via Ethernet cable to Mac
- **DHCP:** Mac assigns IP address to Pi automatically
- **Internet:** Pi can access internet through Mac

## Benefits
- Pi can download updates
- Install packages via apt
- Update moOde software
- Download music files
- Access online services

## Checking Connection

### On Mac:
```bash
# Check if Pi is connected
ping GhettoBlaster.local

# Or check DHCP leases
cat /var/db/dhcpd_leases
```

### On Pi (if you have SSH access):
```bash
# Check IP address
ip addr show eth0

# Test internet
ping -c 3 8.8.8.8
```

## Pi IP Address
The Pi will get an IP address from Mac's DHCP server. Common ranges:
- `192.168.2.x` (if Mac uses this range)
- `192.168.10.x` (if configured)
- Check Mac's Internet Sharing settings for range

## Troubleshooting

### Pi not getting internet:
1. Check Ethernet cable is connected
2. Verify Internet Sharing is enabled in System Preferences
3. Check Mac's firewall settings
4. Verify Pi's Ethernet interface is up

### Find Pi's IP:
```bash
# On Mac
arp -a | grep -i "raspberry\|moode\|ghetto"

# Or check DHCP leases
cat /var/db/dhcpd_leases | grep -A 5 "hostname"
```

## Next Steps
1. Connect Pi via Ethernet to Mac
2. Wait for Pi to get IP address
3. Test connection: `ping GhettoBlaster.local`
4. SSH to Pi: `ssh pi@GhettoBlaster.local`
5. Test internet on Pi: `ping 8.8.8.8`

