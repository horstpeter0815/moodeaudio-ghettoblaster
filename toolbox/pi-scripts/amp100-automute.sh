#!/bin/bash
# AMP100 Auto-Mute Configuration
# Sets Auto-Mute register on PCM5122 after boot
# This complements the dtoverlay=hifiberry-amp100,automute setting

# PCM5122 I2C Address: 0x4d
# AUTO_MUTE Register: 0x3B (Page 0, Register 59)
# Value 0x11 = Auto-Mute enabled (left and right channels)

I2C_BUS=1
I2C_ADDR=0x4d
AUTO_MUTE_REG=0x3b
AUTO_MUTE_VAL=0x11

echo "=== AMP100 Auto-Mute Configuration ==="

# Wait for I2C bus to be ready
for i in {1..10}; do
    if i2cdetect -y $I2C_BUS >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Check if PCM5122 is present on I2C bus
if i2cdetect -y $I2C_BUS 2>/dev/null | grep -q "$(printf '%02x' $I2C_ADDR)"; then
    echo "✅ PCM5122 detected at I2C address $I2C_ADDR"
    
    # Set Auto-Mute register
    if i2cset -y $I2C_BUS $I2C_ADDR $AUTO_MUTE_REG $AUTO_MUTE_VAL 2>/dev/null; then
        echo "✅ Auto-Mute register set to 0x$AUTO_MUTE_VAL"
        
        # Verify register value
        REG_VAL=$(i2cget -y $I2C_BUS $I2C_ADDR $AUTO_MUTE_REG 2>/dev/null)
        if [ -n "$REG_VAL" ]; then
            echo "✅ Verified Auto-Mute register: $REG_VAL"
        fi
    else
        echo "⚠️  Failed to set Auto-Mute register"
        exit 1
    fi
else
    echo "⚠️  PCM5122 not detected at I2C address $I2C_ADDR"
    echo "   (This is normal if AMP100 is not connected or overlay not loaded)"
    exit 0
fi

echo "=== Auto-Mute Configuration Complete ==="

