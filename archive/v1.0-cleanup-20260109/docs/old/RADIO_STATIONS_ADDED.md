# Radio Stations Added to moOde

**Date:** January 7, 2026

## Stations Added

### Austria
1. **FM4** - ORF FM4
   - Stream: `https://orf-live.ors-shoutcast.at/fm4-q2a`
   - Quality: High quality AAC stream

### Germany (Deutschlandfunk)
2. **Deutschlandfunk** - Main station
   - Stream: `https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3`
   - Quality: 128kbps MP3

3. **Deutschlandfunk Nova** - Alternative music
   - Stream: `https://st01.sslstream.dlf.de/dlf/02/128/mp3/stream.mp3`
   - Quality: 128kbps MP3

4. **Deutschlandfunk Kultur** - Culture and classical
   - Stream: `https://st01.sslstream.dlf.de/dlf/03/128/mp3/stream.mp3`
   - Quality: 128kbps MP3

## How to Add

Run the script when the Pi is booted:

```bash
cd ~/moodeaudio-cursor && ./scripts/audio/ADD_RADIO_STATIONS.sh
```

Or manually via moOde web interface:
1. Go to Radio section
2. Click "Add Station"
3. Enter station name and URL
4. Save

## Stream URLs Reference

- **FM4**: `https://orf-live.ors-shoutcast.at/fm4-q2a`
- **Deutschlandfunk**: `https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3`
- **Deutschlandfunk Nova**: `https://st01.sslstream.dlf.de/dlf/02/128/mp3/stream.mp3`
- **Deutschlandfunk Kultur**: `https://st01.sslstream.dlf.de/dlf/03/128/mp3/stream.mp3`

---

**Status:** Script ready, waiting for Pi to boot

