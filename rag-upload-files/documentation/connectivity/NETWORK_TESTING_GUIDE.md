# Network Testing Guide

## Overview

This guide explains how to test the unified network manager in Docker before deploying to physical hardware.

## Prerequisites

- Docker installed and running
- Docker Compose (optional, for easier management)

## Quick Start

Run all network simulation tests:

```bash
cd ~/moodeaudio-cursor
./tools/test/network-simulation-tests.sh
```

## Test Suite

The network simulation test suite includes:

### Test 1: USB Gadget Mode
- Creates mock `usb0` interface
- Verifies USB gadget mode is detected
- Verifies IP 192.168.10.2 is configured

### Test 2: Ethernet Static Mode
- Creates mock `eth0` interface
- No `/boot/firmware/network-mode` file
- Verifies static IP 192.168.10.2 is configured

### Test 3: Ethernet DHCP Mode
- Creates mock `eth0` interface
- Creates `/boot/firmware/network-mode` with `ethernet-dhcp`
- Verifies DHCP mode is detected

### Test 4: Interface Priority
- Creates all interfaces (usb0, eth0, wlan0)
- Verifies USB gadget is selected (highest priority)

### Test 5: Conflict Resolution
- Verifies conflicting services are disabled

## Manual Testing

### Test USB Gadget Mode

```bash
docker run -it --privileged --cap-add=NET_ADMIN \
  -v $(pwd)/network-test:/test:rw \
  network-test:latest /bin/bash

# Inside container:
/usr/local/bin/mock-interfaces.sh usb0
/usr/local/bin/network-mode-manager.sh
ip addr show usb0
```

### Test Ethernet Static Mode

```bash
docker run -it --privileged --cap-add=NET_ADMIN \
  -v $(pwd)/network-test:/test:rw \
  -v $(pwd)/network-test-boot:/boot/firmware:rw \
  network-test:latest /bin/bash

# Inside container:
rm -f /boot/firmware/network-mode
/usr/local/bin/mock-interfaces.sh eth0
/usr/local/bin/network-mode-manager.sh
ip addr show eth0
```

### Test Ethernet DHCP Mode

```bash
# Create mode file
echo "ethernet-dhcp" > network-test-boot/network-mode

docker run -it --privileged --cap-add=NET_ADMIN \
  -v $(pwd)/network-test:/test:rw \
  -v $(pwd)/network-test-boot:/boot/firmware:rw \
  network-test:latest /bin/bash

# Inside container:
/usr/local/bin/mock-interfaces.sh eth0
/usr/local/bin/network-mode-manager.sh
ip addr show eth0
```

## Docker Compose Testing

Use Docker Compose for easier management:

```bash
docker-compose -f docker-compose.network-test.yml build
docker-compose -f docker-compose.network-test.yml up
```

## Checking Logs

Network mode manager logs are in `/var/log/network-mode-manager.log`:

```bash
docker exec -it network-test tail -f /var/log/network-mode-manager.log
```

Or check container logs:

```bash
docker logs network-test
```

## Troubleshooting Tests

### Container Fails to Start

Check Docker is running:
```bash
docker info
```

Check privileges:
```bash
docker run --privileged --cap-add=NET_ADMIN ...
```

### Interface Creation Fails

Ensure `NET_ADMIN` capability is added:
```bash
docker run --cap-add=NET_ADMIN ...
```

### Network Mode Not Detected

Check mock interfaces are created:
```bash
docker exec -it network-test ip link show
```

Check network mode manager script:
```bash
docker exec -it network-test /usr/local/bin/network-mode-manager.sh
```

## Integration with Main Test Suite

The network tests can be run as part of the complete test suite:

```bash
./tools/test.sh --network
```

Or run all tests:
```bash
./complete_test_suite.sh
```

## Next Steps

After Docker tests pass:
1. Apply unified network manager to SD card
2. Test on physical Pi
3. Verify all connectivity modes work
4. Update build script to include in builds



