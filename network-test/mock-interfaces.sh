#!/bin/bash
################################################################################
#
# MOCK NETWORK INTERFACES FOR DOCKER TESTING
#
# Creates fake network interfaces to simulate different connectivity modes
#
################################################################################

set -e

MODE="${1:-eth0}"

case "$MODE" in
    "usb0")
        echo "Creating mock USB gadget interface (usb0)..."
        ip link add name usb0 type dummy
        ip link set usb0 up
        echo "✅ Mock usb0 interface created"
        ;;
    "eth0")
        echo "Creating mock Ethernet interface (eth0)..."
        ip link add name eth0 type dummy
        ip link set eth0 up
        echo "✅ Mock eth0 interface created"
        ;;
    "wlan0")
        echo "Creating mock WiFi interface (wlan0)..."
        ip link add name wlan0 type dummy
        ip link set wlan0 up
        echo "✅ Mock wlan0 interface created"
        ;;
    "all")
        echo "Creating all mock interfaces..."
        ip link add name usb0 type dummy 2>/dev/null || true
        ip link add name eth0 type dummy 2>/dev/null || true
        ip link add name wlan0 type dummy 2>/dev/null || true
        ip link set usb0 up 2>/dev/null || true
        ip link set eth0 up 2>/dev/null || true
        ip link set wlan0 up 2>/dev/null || true
        echo "✅ All mock interfaces created"
        ;;
    *)
        echo "Usage: $0 {usb0|eth0|wlan0|all}"
        exit 1
        ;;
esac



