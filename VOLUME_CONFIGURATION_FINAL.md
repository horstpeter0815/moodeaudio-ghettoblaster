# Final Volume Configuration
**Date:** 2026-01-21  
**Status:** ✅ Working and Optimized

## Volume Control Architecture

**Hardware Mixers (FIXED):**
- **Digital Mixer:** 75% (-26.0dB) - FIXED, never changes
- **Analogue Mixer:** 100% (0.0dB) - FIXED, never changes

**Software Volume Control:**
- **MPD Volume:** 0-100% - PRIMARY CONTROL (user adjusts via UI slider)
- **Mixer Type:** Software (MPD handles volume)

## Configuration Details

### Hardware Settings
```bash
# Digital Mixer: 75%
amixer sset Digital 75%

# Analogue Mixer: 100%
amixer sset Analogue 100%
```

### Database Settings
```sql
cfg_system.volknob = '75'
cfg_system.amixname = 'Digital'
cfg_system.mpdmixer = 'null'
cfg_mpd.mixer_type = 'software'
```

### MPD Configuration
```conf
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "software"
}
```

## How It Works

1. **Hardware mixers are FIXED** at optimal levels
2. **User controls volume ONLY through MPD slider** (0-100%)
3. **Volume changes are immediate and predictable**
4. **No hardware mixer adjustments needed**

## Volume Response

- **MPD 0-10%:** Very quiet to quiet
- **MPD 10-20%:** Quiet background listening
- **MPD 20-30%:** Normal listening level
- **MPD 30-50%:** Moderate to loud
- **MPD 50-100%:** Very loud to maximum

## Audio Chain

```
MPD (Software Volume 0-100%)
    ↓
Direct to HiFiBerry AMP100
    ↓
Digital Mixer (75% FIXED)
    ↓
Analogue Mixer (100% FIXED)
    ↓
Amplifier Output
```

## Notes

- **Digital Mixer at 75%** provides good balance between volume and signal quality
- **Analogue Mixer at 100%** ensures no additional attenuation
- **MPD software volume** gives precise control without hardware limitations
- **Volume control is responsive** and works immediately in UI

## Commands to Restore

```bash
# Set hardware mixers
amixer sset Digital 75%
amixer sset Analogue 100%

# Set MPD mixer type
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_mpd SET value='software' WHERE param='mixer_type'"

# Restart MPD
sudo systemctl restart mpd
```

---

**This configuration is tested and working!**
