#!/bin/bash
# Reset AMP100 via DSP Add-on GPIO 17
# This script is executed before the PCM5122 driver loads
# GPIO 17 is controlled by the DSP Add-on, not by the device tree overlay

# GPIO 17 exportieren (falls noch nicht exportiert)
if [ ! -d /sys/class/gpio/gpio17 ]; then
    echo 17 >/sys/class/gpio/export 2>/dev/null
    sleep 0.1
fi

# GPIO 17 als Output konfigurieren
if [ -d /sys/class/gpio/gpio17 ]; then
    echo out >/sys/class/gpio/gpio17/direction 2>/dev/null
    
    # GPIO 4 (Mute) auch exportieren und konfigurieren
    if [ ! -d /sys/class/gpio/gpio4 ]; then
        echo 4 >/sys/class/gpio/export 2>/dev/null
        sleep 0.1
    fi
    
    if [ -d /sys/class/gpio/gpio4 ]; then
        echo out >/sys/class/gpio/gpio4/direction 2>/dev/null
        
        # Mute aktivieren (HIGH = muted)
        echo 1 >/sys/class/gpio/gpio4/value 2>/dev/null
        sleep 0.01
    fi
    
    # Reset-Sequenz: LOW = Reset, HIGH = Normal
    # PCM5122 Reset ist ACTIVE LOW
    echo 0 >/sys/class/gpio/gpio17/value 2>/dev/null  # Reset (LOW)
    sleep 0.1
    echo 1 >/sys/class/gpio/gpio17/value 2>/dev/null  # Normal (HIGH)
    sleep 0.01
    
    # Unmute (LOW = unmuted)
    if [ -d /sys/class/gpio/gpio4 ]; then
        echo 0 >/sys/class/gpio/gpio4/value 2>/dev/null
    fi
fi

