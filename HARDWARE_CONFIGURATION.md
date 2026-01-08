# Hardware Configuration - moOde Audio System

**Date:** 2025-01-03  
**System:** Raspberry Pi 5 with HiFiBerry AMP100 and WaveShare Display

---

## Hardware Components

### 1. Raspberry Pi 5
- **Model:** Raspberry Pi 5
- **Connection:** Directly connected to HiFiBerry AMP100 via GPIO header
- **Function:** Main system running moOde Audio

### 2. HiFiBerry AMP100
- **Model:** HiFiBerry AMP100
- **Addon Board:** Built-in DSP Addon Board
- **Power Supply:** 20V, 8A (160W)
- **Connection:**
  - Connected directly to Raspberry Pi 5 via GPIO header
  - Power supply: 20V/8A connector

### 3. WaveShare Display
- **Model:** WaveShare Display (7.9" HDMI)
- **Connections:**
  - **HDMI:** Connected to Raspberry Pi 5 via HDMI cable
  - **Touch:** Connected to Raspberry Pi 5 via USB cable
  - **Power:** Connected to Raspberry Pi 5 via USB cable (power supply)

---

## Connection Diagram

```
┌─────────────────────┐
│  WaveShare Display  │
│   (7.9" HDMI)       │
├─────────────────────┤
│  HDMI ────────────┐ │
│  USB (Touch) ─────┼─┼─┐
│  USB (Power) ─────┼─┼─┼─┐
└─────────────────────┘ │ │ │
                        │ │ │
        ┌───────────────┘ │ │
        │                 │ │
┌───────▼─────────────────▼─▼─┐
│    Raspberry Pi 5           │
│                              │
│  GPIO Header                │
│       │                      │
└───────┼──────────────────────┘
        │
        │ GPIO Connection
        │
┌───────▼──────────────────────┐
│   HiFiBerry AMP100           │
│   (with DSP Addon Board)     │
│                              │
│  Power: 20V / 8A ─────────┐  │
└────────────────────────────┘  │
                                 │
                          ┌──────▼──────┐
                          │  Power Supply│
                          │   20V / 8A   │
                          │    (160W)    │
                          └─────────────┘
```

---

## Connection Details

### HiFiBerry AMP100 to Raspberry Pi 5
- **Type:** Direct GPIO header connection
- **Interface:** GPIO pins on Raspberry Pi 5
- **Purpose:** Audio output and control

### WaveShare Display Connections
1. **HDMI Connection:**
   - **From:** WaveShare Display HDMI port
   - **To:** Raspberry Pi 5 HDMI port
   - **Purpose:** Video/Display output

2. **USB Touch Connection:**
   - **From:** WaveShare Display USB port (Touch)
   - **To:** Raspberry Pi 5 USB port
   - **Purpose:** Touchscreen input

3. **USB Power Connection:**
   - **From:** WaveShare Display USB port (Power)
   - **To:** Raspberry Pi 5 USB port
   - **Purpose:** Power supply for display

### HiFiBerry AMP100 Power
- **Voltage:** 20V
- **Current:** 8A
- **Power:** 160W
- **Connector:** Dedicated power connector on AMP100

---

## System Specifications

### Audio System
- **DAC/Amp:** HiFiBerry AMP100
- **DSP:** Built-in DSP Addon Board
- **Power:** 20V/8A (160W) power supply
- **Connection:** Direct GPIO to Raspberry Pi 5

### Display System
- **Display:** WaveShare 7.9" HDMI Display
- **Resolution:** 1280x400 (landscape, rotated)
- **Touch:** USB touch interface
- **Connections:** HDMI + 2x USB (touch + power)

### Computing
- **Board:** Raspberry Pi 5
- **OS:** moOde Audio (Linux-based audio player)
- **Network:** Ethernet/WiFi capable
- **Storage:** SD card

---

## Power Requirements

### Total System Power
- **HiFiBerry AMP100:** 20V / 8A (160W)
- **Raspberry Pi 5:** ~5V / 3A (15W) - supplied via GPIO from AMP100 or separate
- **WaveShare Display:** Supplied via USB from Raspberry Pi 5
- **Total:** ~175W peak

### Power Supply
- **Main:** 20V / 8A (160W) for HiFiBerry AMP100
- **Note:** Raspberry Pi 5 and display may require separate power or be powered via GPIO/USB

---

## Physical Setup

1. **HiFiBerry AMP100** is mounted directly on Raspberry Pi 5 via GPIO header
2. **WaveShare Display** is positioned separately and connected via cables:
   - HDMI cable for video
   - USB cable for touch input
   - USB cable for power
3. **Power supply** (20V/8A) connected to HiFiBerry AMP100

---

## Software Configuration

- **OS:** moOde Audio Player
- **User:** andre
- **Audio Output:** HiFiBerry AMP100 (configured in moOde)
- **Display:** WaveShare 7.9" (rotated to landscape 1280x400)
- **Network:** Ethernet or WiFi (configurable)

---

## Notes

- All connections should be secure and properly seated
- Power supply for AMP100 must provide 20V/8A (160W)
- Display requires both HDMI and USB connections
- Touch interface requires USB connection to function
- System runs moOde Audio software for audio playback

---

**Hardware configuration documented. System ready for setup and use.**

