# Network Configuration via WebSSH - Quick Guide

**Access:** `http://PI_IP:4200` (login: `andre` / `0815`)

---

## Option 1: Configure WiFi (Hotel Network)

**Copy and paste these commands in WebSSH:**

```bash
# Check current network status
ip addr show
hostname -I

# Configure WiFi (Centara Nova Hotel)
sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null << 'EOF'

network={
    ssid="Centara Nova Hotel"
    psk="password"
    key_mgmt=WPA2-PSK
}
EOF

# Restart networking
sudo wpa_cli -i wlan0 reconfigure
sudo systemctl restart networking

# Check WiFi connection
sudo wpa_cli status
ip addr show wlan0
```

---

## Option 2: Configure Ethernet (Static IP)

**If you want static IP on Ethernet:**

```bash
# Set static IP temporarily (for testing)
sudo ip addr add 192.168.10.2/24 dev eth0 2>/dev/null || true
sudo ip link set eth0 up
sudo ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true

# Check if it works
ip addr show eth0
ping -c 3 192.168.10.1
```

---

## Option 3: Enable DHCP on Ethernet (Easiest)

**Just restart networking to get DHCP:**

```bash
# Restart network services
sudo systemctl restart networking
sudo systemctl restart dhcpcd

# Check IP address
hostname -I
ip addr show eth0
ip addr show wlan0
```

---

## Quick Status Check

**See current network configuration:**

```bash
# All interfaces
ip addr show

# WiFi status
sudo wpa_cli status

# Routing
ip route show

# Current IP addresses
hostname -I
```

---

## After Configuration

1. **Check if Pi got IP:**
   ```bash
   hostname -I
   ```

2. **Test connectivity:**
   ```bash
   ping -c 3 8.8.8.8
   ```

3. **Access moOde Web UI:**
   - `http://PI_IP` (once you have the IP)

---

**Most common: Use Option 3 (DHCP) if Ethernet cable is connected - it should work automatically.**




