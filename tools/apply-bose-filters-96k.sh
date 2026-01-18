#!/bin/bash
# Apply Bose Wave filters with 96kHz sample rate
# Run: sudo bash apply-bose-filters-96k.sh

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}')

echo "=== APPLYING BOSE FILTERS AT 96kHz ==="

# Create CamillaDSP config with Bose filters at 96kHz
mkdir -p /usr/share/camilladsp
cat > /usr/share/camilladsp/working_config.yml <<'EOF'
description: Bose Wave Filters - 96kHz
devices:
  samplerate: 96000
  chunksize: 4096
  queuelimit: 1
  capture:
    type: Stdin
    channels: 2
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "plughw:CARD_NUM,0"
    format: S32LE
  volume_ramp_time: 150

filters:
  peqgain:
    type: Gain
    parameters:
      gain: 0
      inverted: false
  band_01:
    type: Biquad
    parameters:
      type: Lowshelf
      freq: 36.35
      gain: 20.00
      q: 0.500
  band_02:
    type: Biquad
    parameters:
      type: Peaking
      freq: 38.00
      gain: 6.50
      q: 5.000
  band_03:
    type: Biquad
    parameters:
      type: Peaking
      freq: 64.50
      gain: -4.30
      q: 10.000
  band_04:
    type: Biquad
    parameters:
      type: Peaking
      freq: 142.00
      gain: -24.90
      q: 7.473
  band_05:
    type: Biquad
    parameters:
      type: Peaking
      freq: 156.00
      gain: 8.00
      q: 1.000
  band_06:
    type: Biquad
    parameters:
      type: Peaking
      freq: 161.00
      gain: -23.60
      q: 6.744
  band_07:
    type: Biquad
    parameters:
      type: Peaking
      freq: 180.00
      gain: -17.90
      q: 20.000
  band_08:
    type: Biquad
    parameters:
      type: Peaking
      freq: 256.00
      gain: -23.10
      q: 2.755
  band_09:
    type: Biquad
    parameters:
      type: Lowshelf
      freq: 278.00
      gain: -5.20
      q: 0.707
  band_10:
    type: Biquad
    parameters:
      type: Peaking
      freq: 304.00
      gain: -4.00
      q: 7.496
  band_11:
    type: Biquad
    parameters:
      type: Peaking
      freq: 359.00
      gain: -27.50
      q: 2.114
  band_12:
    type: Biquad
    parameters:
      type: Peaking
      freq: 433.00
      gain: 8.00
      q: 1.000
  band_13:
    type: Biquad
    parameters:
      type: Peaking
      freq: 463.00
      gain: -15.70
      q: 6.424
  band_14:
    type: Biquad
    parameters:
      type: Peaking
      freq: 603.00
      gain: -21.40
      q: 1.000
  band_15:
    type: Biquad
    parameters:
      type: Peaking
      freq: 850.00
      gain: -4.30
      q: 4.983
  band_16:
    type: Biquad
    parameters:
      type: Peaking
      freq: 1000.00
      gain: -10.00
      q: 10.000
  band_17:
    type: Biquad
    parameters:
      type: Peaking
      freq: 1317.00
      gain: -14.80
      q: 1.004
  band_18:
    type: Biquad
    parameters:
      type: Highshelf
      freq: 1468.00
      gain: -4.00
      q: 0.707
  band_19:
    type: Biquad
    parameters:
      type: Peaking
      freq: 1592.00
      gain: -10.70
      q: 1.008
  band_20:
    type: Biquad
    parameters:
      type: Peaking
      freq: 7500.00
      gain: -0.50
      q: 3.000

mixers:
  stereo:
    channels:
      in: 2
      out: 2
    mapping:
    - dest: 0
      sources:
      - channel: 0
        gain: 0
        inverted: false
    - dest: 1
      sources:
      - channel: 1
        gain: 0
        inverted: false

pipeline:
- type: Mixer
  name: stereo
- type: Filter
  channel: 0
  names:
  - peqgain
  - band_01
  - band_02
  - band_03
  - band_04
  - band_05
  - band_06
  - band_07
  - band_08
  - band_09
  - band_10
  - band_11
  - band_12
  - band_13
  - band_14
  - band_15
  - band_16
  - band_17
  - band_18
  - band_19
  - band_20
- type: Filter
  channel: 1
  names:
  - peqgain
  - band_01
  - band_02
  - band_03
  - band_04
  - band_05
  - band_06
  - band_07
  - band_08
  - band_09
  - band_10
  - band_11
  - band_12
  - band_13
  - band_14
  - band_15
  - band_16
  - band_17
  - band_18
  - band_19
  - band_20

title: Bose Wave Room EQ Filters - 96kHz
EOF

# Replace card number
sed -i "s/CARD_NUM/$AMP100_CARD/g" /usr/share/camilladsp/working_config.yml

echo "✅ Bose filters config created with 96kHz sample rate"
echo "   - 20 EQ bands applied"
echo "   - Sample rate: 96kHz"
echo "   - Output: plughw:$AMP100_CARD,0"

# Restart services
systemctl restart camilladsp.service
sleep 2

if systemctl is-active --quiet camilladsp.service; then
    echo "✅ CamillaDSP running with Bose filters"
else
    echo "❌ CamillaDSP failed"
    journalctl -u camilladsp.service -n 10 --no-pager
    exit 1
fi

systemctl restart mpd.service
sleep 2

echo ""
echo "✅ COMPLETE"
echo "Audio: MPD → _audioout → camilladsp (Bose filters, 96kHz) → HiFiBerry"
