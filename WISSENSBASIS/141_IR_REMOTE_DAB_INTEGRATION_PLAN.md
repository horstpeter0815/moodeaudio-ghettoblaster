# IR Remote + DAB+ Integration Plan

**Status:** Planned for future implementation  
**Date:** 2026-01-19  
**System:** Raspberry Pi 5 + moOde + Bose Wave

---

## 🎯 Goal

Integrate Bose Wave IR remote control and DAB+ digital radio receiver into the moOde system.

---

## 📡 Part 1: IR Receiver Setup

### Hardware Required

**Option 1: GPIO IR Receiver (RECOMMENDED)**
- Component: TSOP38238 or VS1838B IR receiver module
- Cost: ~$3-5
- Connection:
  ```
  TSOP38238 → Raspberry Pi GPIO
  ├─ VCC (Pin 1) → 3.3V (Pin 1)
  ├─ GND (Pin 2) → GND (Pin 6)
  └─ OUT (Pin 3) → GPIO 18 (Pin 12)
  ```

**Alternative: USB IR Receiver**
- MCE-compatible USB IR receiver
- Cost: ~$15-25
- Plug-and-play, no wiring needed

### Software Setup

#### 1. Install LIRC

```bash
sudo apt-get update
sudo apt-get install lirc
```

#### 2. Configure GPIO IR Receiver

Edit `/boot/firmware/config.txt`:
```ini
# Enable IR receiver on GPIO 18
dtoverlay=gpio-ir,gpio_pin=18
```

Edit `/etc/lirc/lirc_options.conf`:
```ini
driver = default
device = /dev/lirc0
```

#### 3. Test IR Receiver

```bash
# Stop lirc service
sudo systemctl stop lircd

# Test raw IR signals
mode2 -d /dev/lirc0

# Point Bose Wave remote at receiver and press buttons
# You should see pulse/space values
```

---

## 🎛️ Part 2: Bose Wave Remote Configuration

### Step 1: Learn Remote Codes

```bash
# Record Bose Wave remote codes
sudo irrecord -d /dev/lirc0 /etc/lirc/lircd.conf.d/bose_wave.conf

# Follow prompts to press each button:
# - Power
# - Volume +/-
# - Mute
# - Play/Pause
# - Next/Previous
# - Presets 1-6
# - AM/FM
# - AUX
# - Alarm 1/2
```

### Step 2: Create LIRC Configuration

**File: `/etc/lirc/lircd.conf.d/bose_wave.conf`**

```conf
# Bose Wave Remote Control
# Recorded: YYYY-MM-DD

begin remote
  name  Bose_Wave
  bits  16
  flags SPACE_ENC|CONST_LENGTH
  eps   30
  aeps  100
  
  header  9000 4500
  one     560  1690
  zero    560   565
  ptrail  560
  repeat  9000 2250
  gap     108000
  
  begin codes
    KEY_POWER        0x????
    KEY_VOLUMEUP     0x????
    KEY_VOLUMEDOWN   0x????
    KEY_MUTE         0x????
    KEY_PLAY         0x????
    KEY_PAUSE        0x????
    KEY_NEXT         0x????
    KEY_PREVIOUS     0x????
    KEY_1            0x????  # Preset 1
    KEY_2            0x????  # Preset 2
    KEY_3            0x????  # Preset 3
    KEY_4            0x????  # Preset 4
    KEY_5            0x????  # Preset 5
    KEY_6            0x????  # Preset 6
    KEY_RADIO        0x????  # AM/FM
    KEY_AUX          0x????  # AUX input
    KEY_ALARM1       0x????
    KEY_ALARM2       0x????
    KEY_SLEEP        0x????
  end codes
end remote
```

### Step 3: Map to moOde/MPD Commands

**File: `/etc/lirc/irexec.lircrc`**

```conf
# Bose Wave Remote → moOde Integration

# Volume Up
begin
  remote = Bose_Wave
  button = KEY_VOLUMEUP
  prog = irexec
  config = mpc volume +5
  repeat = 1
end

# Volume Down
begin
  remote = Bose_Wave
  button = KEY_VOLUMEDOWN
  prog = irexec
  config = mpc volume -5
  repeat = 1
end

# Mute
begin
  remote = Bose_Wave
  button = KEY_MUTE
  prog = irexec
  config = mpc volume 0
end

# Play
begin
  remote = Bose_Wave
  button = KEY_PLAY
  prog = irexec
  config = mpc play
end

# Pause
begin
  remote = Bose_Wave
  button = KEY_PAUSE
  prog = irexec
  config = mpc pause
end

# Next Track
begin
  remote = Bose_Wave
  button = KEY_NEXT
  prog = irexec
  config = mpc next
end

# Previous Track
begin
  remote = Bose_Wave
  button = KEY_PREVIOUS
  prog = irexec
  config = mpc prev
end

# Preset 1 - Radio Station 1
begin
  remote = Bose_Wave
  button = KEY_1
  prog = irexec
  config = mpc clear && mpc load "Radio_Preset_1" && mpc play
end

# Preset 2 - Radio Station 2
begin
  remote = Bose_Wave
  button = KEY_2
  prog = irexec
  config = mpc clear && mpc load "Radio_Preset_2" && mpc play
end

# Continue for presets 3-6...

# AM/FM - Switch to Radio
begin
  remote = Bose_Wave
  button = KEY_RADIO
  prog = irexec
  config = mpc clear && mpc load "Radio_Stations" && mpc play
end

# Power - Toggle Display
begin
  remote = Bose_Wave
  button = KEY_POWER
  prog = irexec
  config = /usr/local/bin/toggle-display.sh
end
```

### Step 4: Create Helper Scripts

**File: `/usr/local/bin/toggle-display.sh`**

```bash
#!/bin/bash
# Toggle display on/off via HDMI CEC or blanking

# Check if display is on
if xset q | grep -q "Monitor is On"; then
    # Turn off
    xset dpms force off
    vcgencmd display_power 0
else
    # Turn on
    xset dpms force on
    vcgencmd display_power 1
fi
```

### Step 5: Enable Services

```bash
# Enable LIRC services
sudo systemctl enable lircd
sudo systemctl enable irexec
sudo systemctl start lircd
sudo systemctl start irexec

# Test
sudo systemctl status lircd
sudo systemctl status irexec
```

---

## 📻 Part 3: DAB+ Receiver Integration

### Hardware Options

**Option 1: USB DAB+ Dongle**
- RTL-SDR USB dongle with DAB+ support
- Software: `dablin`, `welle.io`, or `rtl_fm`

**Option 2: Standalone DAB+ Receiver**
- External DAB+ receiver (your "green" one)
- Connected via:
  - AUX line-in to HiFiBerry AMP100
  - Bluetooth (if supported)
  - USB (if has digital output)

### Integration Approach

#### If USB DAB+ Dongle:

```bash
# Install DAB+ software
sudo apt-get install rtl-sdr dablin welle-cli

# Scan for DAB+ stations
welle-cli --scan

# Play DAB+ station
welle-cli --station "Station Name"
```

**Add to moOde as Radio Streams:**
```bash
# Create playlist with DAB+ command
cat > /var/lib/mpd/playlists/DAB_Station.m3u << EOF
#EXTM3U
#EXTINF:-1,DAB+ Station Name
pipe:///usr/bin/welle-cli --station "Station Name" --raw | aplay
EOF
```

#### If Standalone DAB+ Receiver (AUX):

**Option A: Line-in Integration**
1. Connect DAB+ receiver AUX out → HiFiBerry line-in
2. Configure ALSA to mix line-in with MPD output
3. Use remote to switch between moOde and DAB+

**Option B: Bluetooth Integration**
1. Pair DAB+ receiver as Bluetooth source
2. Use moOde's Bluetooth input feature
3. Switch input via moOde UI or remote

### Remote Control Integration

If DAB+ receiver has its own remote:
- Use IR receiver to learn DAB+ remote codes
- Add to LIRC configuration
- Map buttons to control DAB+ source selection

---

## 🔄 Integration Workflow

### When You Get Hardware:

1. **IR Receiver First**
   ```bash
   # Connect GPIO IR receiver
   # Update config.txt (add dtoverlay=gpio-ir,gpio_pin=18)
   # Reboot
   # Test with mode2
   # Learn Bose Wave remote codes
   # Configure mappings
   ```

2. **DAB+ Receiver Second**
   ```bash
   # Connect DAB+ hardware (USB or AUX)
   # Install DAB+ software (if USB dongle)
   # Configure as moOde input
   # Add to playlists or input sources
   ```

3. **Test Integration**
   - Press Bose Wave remote buttons
   - Verify moOde responds
   - Test presets for radio stations
   - Test DAB+ source switching

---

## 📦 Package Installation Script

**File: `/usr/local/bin/install-ir-dab-support.sh`**

```bash
#!/bin/bash
# Install IR receiver and DAB+ support

echo "Installing IR receiver support..."
sudo apt-get update
sudo apt-get install -y lirc

echo "Installing DAB+ support (if USB dongle)..."
sudo apt-get install -y rtl-sdr dablin welle-cli

echo "Configuring IR receiver..."
# Add to config.txt
if ! grep -q "dtoverlay=gpio-ir" /boot/firmware/config.txt; then
    echo "dtoverlay=gpio-ir,gpio_pin=18" | sudo tee -a /boot/firmware/config.txt
fi

# Configure LIRC
sudo tee /etc/lirc/lirc_options.conf > /dev/null << EOF
driver = default
device = /dev/lirc0
EOF

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Connect IR receiver to GPIO 18"
echo "2. Reboot: sudo reboot"
echo "3. Test: mode2 -d /dev/lirc0"
echo "4. Learn remote: sudo irrecord -d /dev/lirc0 /etc/lirc/lircd.conf.d/bose_wave.conf"
```

---

## 🎯 Future Enhancements

### Advanced Features

1. **Context-Aware Mappings**
   - Power button behavior based on system state
   - Long-press vs short-press actions
   - Different mappings for different screens

2. **Visual Feedback**
   - Display IR commands on screen
   - Volume OSD overlay
   - Station info display

3. **Multi-Remote Support**
   - Bose Wave remote
   - DAB+ receiver remote
   - Universal remote learning

4. **Automation**
   - Wake on remote press
   - Sleep timer via remote
   - Scheduled DAB+ recording

---

## 📚 Resources

### Documentation
- LIRC: https://lirc.org/
- GPIO IR: https://www.raspberrypi.org/documentation/usage/gpio/
- DAB+: https://github.com/Opendigitalradio/
- moOde integration: https://moodeaudio.org/

### Hardware Links
- TSOP38238: Amazon, AliExpress (~$3)
- RTL-SDR DAB+: Amazon (~$25)
- USB IR receivers: Amazon (~$15)

---

## ✅ Implementation Checklist

- [ ] Order IR receiver module
- [ ] Order DAB+ hardware (if needed)
- [ ] Install IR receiver packages
- [ ] Connect IR receiver to GPIO 18
- [ ] Test IR reception with mode2
- [ ] Learn Bose Wave remote codes
- [ ] Create LIRC configuration
- [ ] Map buttons to moOde commands
- [ ] Create helper scripts
- [ ] Test all button mappings
- [ ] Install DAB+ software (if USB)
- [ ] Configure DAB+ integration
- [ ] Test source switching
- [ ] Document final configuration

---

**Status:** Ready to implement when hardware arrives!  
**Estimated time:** 2-3 hours for full setup  
**Difficulty:** Intermediate (soldering optional, configuration required)
