#!/bin/bash
# Run this on the moOde system to create the Bose Wave filter config

sudo tee /usr/share/camilladsp/configs/bose_wave_filters.yml > /dev/null << 'ENDOFFILE'
description: Room EQ Import - Bose Wave Filters
devices:
  adjust_period: 10
  capture:
    type: Stdin
    channels: 2
    extra_samples: null
    format: S24LE
    read_bytes: null
    skip_bytes: null
  capture_samplerate: null
  chunksize: 1024
  enable_rate_adjust: false
  playback:
    type: Alsa
    channels: 2
    device: hw:0,0
    format: S24LE
  queuelimit: 1
  rate_measure_interval: null
  samplerate: 44100
  silence_threshold: 0
  silence_timeout: 0
  stop_on_rate_change: null
  target_level: 0
  volume_ramp_time: 150
filters:
  peqgain:
    description: null
    parameters:
      gain: 0
      inverted: false
      mute: null
      scale: null
    type: Gain
  band_01:
    description: null
    parameters:
      freq: 36.35
      gain: 30.00
      q: 0.500
      type: Lowshelf
    type: Biquad
  band_02:
    description: null
    parameters:
      freq: 38.00
      gain: 16.50
      q: 5.000
      type: Peaking
    type: Biquad
  band_03:
    description: null
    parameters:
      freq: 64.50
      gain: 5.70
      q: 10.000
      type: Peaking
    type: Biquad
  band_04:
    description: null
    parameters:
      freq: 142.00
      gain: -14.90
      q: 7.473
      type: Peaking
    type: Biquad
  band_05:
    description: null
    parameters:
      freq: 156.00
      gain: 18.00
      q: 1.000
      type: Peaking
    type: Biquad
  band_06:
    description: null
    parameters:
      freq: 161.00
      gain: -13.60
      q: 6.744
      type: Peaking
    type: Biquad
  band_07:
    description: null
    parameters:
      freq: 180.00
      gain: -7.90
      q: 20.000
      type: Peaking
    type: Biquad
  band_08:
    description: null
    parameters:
      freq: 256.00
      gain: -13.10
      q: 2.755
      type: Peaking
    type: Biquad
  band_09:
    description: null
    parameters:
      freq: 278.00
      gain: 4.80
      q: 0.707
      type: Lowshelf
    type: Biquad
  band_10:
    description: null
    parameters:
      freq: 304.00
      gain: 6.00
      q: 7.496
      type: Peaking
    type: Biquad
  band_11:
    description: null
    parameters:
      freq: 359.00
      gain: -17.50
      q: 2.114
      type: Peaking
    type: Biquad
  band_12:
    description: null
    parameters:
      freq: 433.00
      gain: 18.00
      q: 1.000
      type: Peaking
    type: Biquad
  band_13:
    description: null
    parameters:
      freq: 463.00
      gain: -5.70
      q: 6.424
      type: Peaking
    type: Biquad
  band_14:
    description: null
    parameters:
      freq: 603.00
      gain: -11.40
      q: 1.000
      type: Peaking
    type: Biquad
  band_15:
    description: null
    parameters:
      freq: 850.00
      gain: 5.70
      q: 4.983
      type: Peaking
    type: Biquad
  band_16:
    description: null
    parameters:
      freq: 1000.00
      gain: 0.00
      q: 10.000
      type: Peaking
    type: Biquad
  band_17:
    description: null
    parameters:
      freq: 1317.00
      gain: -4.80
      q: 1.004
      type: Peaking
    type: Biquad
  band_18:
    description: null
    parameters:
      freq: 1468.00
      gain: 6.00
      q: 0.707
      type: Highshelf
    type: Biquad
  band_19:
    description: null
    parameters:
      freq: 1592.00
      gain: -0.70
      q: 1.008
      type: Peaking
    type: Biquad
  band_20:
    description: null
    parameters:
      freq: 7500.00
      gain: 9.50
      q: 3.000
      type: Peaking
    type: Biquad
mixers:
  stereo:
    channels:
      in: 2
      out: 2
    description: null
    mapping:
    - dest: 0
      mute: null
      sources:
      - channel: 0
        gain: 0
        inverted: false
        mute: null
        scale: null
    - dest: 1
      mute: null
      sources:
      - channel: 1
        gain: 0
        inverted: false
        mute: null
        scale: null
pipeline:
- bypassed: null
  description: null
  name: stereo
  type: Mixer
- bypassed: null
  channels:
  - 0
  description: null
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
  type: Filter
- bypassed: null
  channels:
  - 1
  description: null
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
  type: Filter
processors: null
title: Bose Wave Room EQ Filters
ENDOFFILE

sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_filters.yml
echo "✅ Bose Wave filter config created!"
echo ""
echo "Verify with:"
echo "  ls -la /usr/share/camilladsp/configs/bose_wave_filters.yml"
echo ""
echo "Then refresh your moOde web interface to see it in the dropdown."

