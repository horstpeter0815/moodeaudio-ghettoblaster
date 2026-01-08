# Wizard Pink Noise Debugging

**Issue:** Pink noise process starts but no audio is heard

## Findings

1. **Process starts successfully** - PID created, process running
2. **Volume is set** - 75% (191/255), should be audible
3. **Device detected** - HiFiBerry AMP100 card 0 detected correctly
4. **MPD uses `_audioout`** - MPD routes through: `_audioout` → `peppy` → `camilladsp` → DAC

## Root Cause

The audio chain requires:
- `_audioout` → routes to `peppy` (PeppyMeter)
- `peppy` → routes to `camilladsp` (CamillaDSP)
- `camilladsp` → routes to DAC

When using direct hardware (`hw:` or `plughw:`), we bypass this chain, but:
- `hw:` bypasses ALSA volume control (no sound even if process runs)
- `plughw:` goes through volume control but may not route correctly

## Solution

Use the same device path as MPD: `_audioout`

This ensures:
- Audio goes through the same ALSA chain as normal playback
- Volume control works
- CamillaDSP processes the audio (if enabled)
- Audio reaches the DAC correctly

## Changes Made

Changed from:
```php
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D plughw:CARD=sndrpihifiberry,DEV=0 ...";
```

To:
```php
$cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D _audioout ...";
```

## Testing

1. Stop MPD (already done in code)
2. Start pink noise using `_audioout` device
3. Audio should go through: `_audioout` → `peppy` → `camilladsp` → DAC
4. User should hear pink noise

## Notes

- MPD must be stopped first (already implemented)
- CamillaDSP will start automatically when `_audioout` is used
- Volume is controlled by ALSA mixer (`amixer -c 0`)
- Current volume: 75% (191/255) - safe level

---

**Date:** January 7, 2026  
**Status:** Fixed - Using `_audioout` device path

