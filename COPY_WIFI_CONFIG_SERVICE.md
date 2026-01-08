# WiFi Config Copy Service - First Boot Network Solution

**Problem:** Standard moOde doesn't copy wpa_supplicant.conf from /boot/firmware to /etc/wpa_supplicant/

**Solution:** Create systemd service that copies file on boot

---

## Files to Create on SD Card (before boot)

### 1. Service File: `/Volumes/rootfs/etc/systemd/system/copy-wifi-config.service`

Create this file on the SD card rootfs partition:

```ini
[Unit]
Description=Copy WiFi Config from Boot Partition
After=local-fs.target
Before=NetworkManager.service
Before=wpa_supplicant.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    if [ -f /boot/firmware/wpa_supplicant.conf ]; then
        mkdir -p /etc/wpa_supplicant
        cp /boot/firmware/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
        chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
        echo "✅ WiFi config copied from boot partition"
    fi
'

[Install]
WantedBy=multi-user.target
```

### 2. Enable the service: `/Volumes/rootfs/etc/systemd/system/multi-user.target.wants/copy-wifi-config.service`

Create symlink:

```bash
cd /Volumes/rootfs/etc/systemd/system/multi-user.target.wants
ln -s ../copy-wifi-config.service copy-wifi-config.service
```

---

## OR: Use Script Approach (Simpler)

### Create script: `/Volumes/rootfs/usr/local/bin/copy-wifi-config.sh`

```bash
#!/bin/bash
if [ -f /boot/firmware/wpa_supplicant.conf ]; then
    mkdir -p /etc/wpa_supplicant
    cp /boot/firmware/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
    chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
    systemctl restart wpa_supplicant 2>/dev/null || true
fi
```

Make executable:
```bash
chmod +x /Volumes/rootfs/usr/local/bin/copy-wifi-config.sh
```

### Service file: `/Volumes/rootfs/etc/systemd/system/copy-wifi-config.service`

```ini
[Unit]
Description=Copy WiFi Config from Boot Partition
After=local-fs.target
Before=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/copy-wifi-config.sh

[Install]
WantedBy=multi-user.target
```

---

## Implementation Script

Create script to set this up on SD card:




