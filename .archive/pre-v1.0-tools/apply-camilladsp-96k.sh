#!/bin/bash
# Configure CamillaDSP for 96kHz sample rate
# Run: sudo bash apply-camilladsp-96k.sh

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}')

echo "=== CONFIGURING CAMILLADSP FOR 96kHz ==="

# Create CamillaDSP config with 96kHz
mkdir -p /usr/share/camilladsp
cat > /usr/share/camilladsp/working_config.yml <<EOF
---
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
    device: "plughw:$AMP100_CARD,0"
    format: S32LE

mixers:
  to_output:
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

filters: {}

pipeline:
  - type: Mixer
    name: to_output
EOF

echo "✅ CamillaDSP config created with 96kHz sample rate"

# Restart CamillaDSP
systemctl restart camilladsp.service
sleep 2

if systemctl is-active --quiet camilladsp.service; then
    echo "✅ CamillaDSP running with 96kHz"
else
    echo "❌ CamillaDSP failed"
    journalctl -u camilladsp.service -n 10 --no-pager
fi

# Restart MPD
systemctl restart mpd.service
sleep 2

echo "✅ DONE - Sample rate: 96kHz"
