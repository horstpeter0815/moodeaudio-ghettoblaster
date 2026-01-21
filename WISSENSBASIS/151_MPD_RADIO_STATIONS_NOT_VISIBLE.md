# MPD Radio Stations Not Visible - Issue Analysis

**Date:** 2026-01-20  
**Symptom:** MPD database shows 0 radio stations even though 233 .pls files exist in RADIO folder  
**Status:** IN PROGRESS - Need to restore working configuration from GitHub

## The Problem

User reported: "I cannot play a radio session because I don't see some [radio stations]"

### Evidence:
```bash
# RADIO folder has files:
ls -la /var/lib/mpd/music/RADIO/
233 pls files in RADIO folder

# But MPD shows:
mpc stats
Artists:      2
Albums:       2
Songs:        2
# Radio stations: 0

# MPD can't see radio stations:
mpc listall RADIO
# Returns 0 results
```

## Investigation

### MPD Configuration Looks Correct:
```
music_directory "/var/lib/mpd/music"
playlist_directory "/var/lib/mpd/playlists"
```

### Permissions Are Correct:
```
drwxrwxrwx 2 root root  12288 Jan 19 08:29 RADIO
```

## Next Steps (Following .cursorrules)

According to `.cursorrules`, I should:
1. ✅ Check GitHub for working configuration FIRST
2. ⏳ Restore from working commit instead of applying new fixes
3. ⏳ Verify with GitHub commit hash

### GitHub Working Commits Found:
- `e11c929` - v1.0 VERIFIED WORKING - Boot Optimized Ghettoblaster
- `84aa8c2` - Version 1.0 - Ghettoblaster working configuration
- Tag: `v1.0-verified-working`

## Root Cause (Hypothesis)

MPD may not be indexing .pls files correctly, OR there's a configuration difference between the working v1.0 and current system.

**ACTION NEEDED:** Restore MPD configuration from GitHub working commit e11c929
