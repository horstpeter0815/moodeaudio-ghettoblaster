#!/bin/bash
# Apply Bose Wave filters with correct left/right channel split at 96kHz
# Channel 0 (Left): Bass driver with waveguide (20-300 Hz)
# Channel 1 (Right): Mids/Highs driver (300 Hz - 20 kHz)

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}')

echo "=== APPLYING BOSE WAVE FILTERS (CORRECT CHANNELS) AT 96kHz ==="

mkdir -p /usr/share/camilladsp
cat > /usr/share/camilladsp/working_config.yml <<'EOF'
description: Bose Wave Stereo - Bass/Mids Split - 96kHz
title: Bose Wave Stereo 96kHz

devices:
  samplerate: 96000
  chunksize: 4096
  queuelimit: 1
  silence_threshold: 0
  silence_timeout: 0
  target_level: 0
  volume_ramp_time: 150
  capture:
    type: Stdin
    channels: 2
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "plughw:CARD_NUM,0"
    format: S32LE

filters:
  # ============================================
  # CROSSOVER FILTERS (300 Hz Linkwitz-Riley)
  # ============================================
  crossover_lowpass_1:
    type: Biquad
    parameters:
      type: LowpassFO
      freq: 300
      q: 0.707
  crossover_lowpass_2:
    type: Biquad
    parameters:
      type: LowpassFO
      freq: 300
      q: 0.707
  crossover_highpass_1:
    type: Biquad
    parameters:
      type: HighpassFO
      freq: 300
      q: 0.707
  crossover_highpass_2:
    type: Biquad
    parameters:
      type: HighpassFO
      freq: 300
      q: 0.707

  # ============================================
  # BASS CHANNEL (Ch 0 - Waveguide Driver)
  # ============================================
  bass_gain:
    type: Gain
    parameters:
      gain: 0
  bass_subbass:
    type: Biquad
    parameters:
      type: Lowshelf
      freq: 36
      gain: 12.0
      q: 0.5
  bass_presence:
    type: Biquad
    parameters:
      type: Peaking
      freq: 80
      gain: 4.0
      q: 1.0
  bass_punch:
    type: Biquad
    parameters:
      type: Peaking
      freq: 150
      gain: 2.0
      q: 1.5
  bass_resonance_1:
    type: Biquad
    parameters:
      type: Peaking
      freq: 142
      gain: -8.0
      q: 7.5
  bass_resonance_2:
    type: Biquad
    parameters:
      type: Peaking
      freq: 180
      gain: -6.0
      q: 10.0
  bass_resonance_3:
    type: Biquad
    parameters:
      type: Peaking
      freq: 256
      gain: -10.0
      q: 3.0

  # ============================================
  # MIDS/HIGHS CHANNEL (Ch 1 - Direct Driver)
  # ============================================
  mids_gain:
    type: Gain
    parameters:
      gain: 0
  mids_warmth:
    type: Biquad
    parameters:
      type: Peaking
      freq: 400
      gain: 2.0
      q: 1.0
  mids_presence:
    type: Biquad
    parameters:
      type: Peaking
      freq: 1000
      gain: -2.0
      q: 2.0
  mids_detail:
    type: Biquad
    parameters:
      type: Peaking
      freq: 2500
      gain: 1.5
      q: 1.5
  highs_brilliance:
    type: Biquad
    parameters:
      type: Highshelf
      freq: 5000
      gain: 3.0
      q: 0.707
  highs_air:
    type: Biquad
    parameters:
      type: Peaking
      freq: 10000
      gain: 2.0
      q: 2.0
  mids_correction_1:
    type: Biquad
    parameters:
      type: Peaking
      freq: 463
      gain: -5.0
      q: 6.4
  mids_correction_2:
    type: Biquad
    parameters:
      type: Peaking
      freq: 603
      gain: -8.0
      q: 1.0
  mids_correction_3:
    type: Biquad
    parameters:
      type: Peaking
      freq: 1317
      gain: -4.0
      q: 1.0
  mids_correction_4:
    type: Biquad
    parameters:
      type: Peaking
      freq: 1592
      gain: -3.0
      q: 1.0

mixers:
  # Mix stereo to mono for both drivers
  stereo_to_mono:
    channels:
      in: 2
      out: 2
    mapping:
      - dest: 0
        sources:
          - channel: 0
            gain: -3
          - channel: 1
            gain: -3
      - dest: 1
        sources:
          - channel: 0
            gain: -3
          - channel: 1
            gain: -3

pipeline:
  # Mix stereo to mono
  - type: Mixer
    name: stereo_to_mono
  # Bass channel (0): Lowpass + Bass EQ
  - type: Filter
    channel: 0
    names:
      - crossover_lowpass_1
      - crossover_lowpass_2
      - bass_gain
      - bass_subbass
      - bass_presence
      - bass_punch
      - bass_resonance_1
      - bass_resonance_2
      - bass_resonance_3
  # Mids/Highs channel (1): Highpass + Mids EQ
  - type: Filter
    channel: 1
    names:
      - crossover_highpass_1
      - crossover_highpass_2
      - mids_gain
      - mids_warmth
      - mids_presence
      - mids_detail
      - highs_brilliance
      - highs_air
      - mids_correction_1
      - mids_correction_2
      - mids_correction_3
      - mids_correction_4
EOF

sed -i "s/CARD_NUM/$AMP100_CARD/g" /usr/share/camilladsp/working_config.yml

echo "✅ Bose Wave config created (96kHz)"
echo "   Channel 0 (Left):  Bass (20-300 Hz) with waveguide EQ"
echo "   Channel 1 (Right): Mids/Highs (300+ Hz) with direct driver EQ"
echo "   Crossover: 300 Hz Linkwitz-Riley"

systemctl restart camilladsp.service
sleep 2
systemctl restart mpd.service
sleep 2

echo "✅ DONE"
echo "CamillaDSP: $(systemctl is-active camilladsp.service)"
echo "Bose Wave drivers properly configured!"
