# Favorite Radio Stations List

This document lists the favorite radio stations configured in moOde Audio Player.

## Stations

### 1. FM4 (Austria)
- **URL**: `https://orf-live.ors-shoutcast.at/fm4-q2a`
- **Quality**: 192 kbps MP3
- **Genre**: Alternative
- **Description**: Austrian radio station focusing on alternative music and youth culture

### 2. Radio Ton Heilbronn (Germany)
- **URL**: `https://stream.radioton.de/radioton-heilbronn/mp3-192`
- **Quality**: 192 kbps MP3
- **Genre**: Regional
- **Description**: Regional radio station from Heilbronn, Germany

### 3. Deutschlandfunk (Germany)
- **URL**: `https://st01.sslstream.dlf.de/dlf/01/high/aac/stream.aac?aggregator=web`
- **Quality**: 192 kbps AAC
- **Genre**: News
- **Description**: German public radio focusing on news and current affairs

### 4. Deutschlandfunk Kultur (Germany)
- **URL**: `https://st02.sslstream.dlf.de/dlf/02/high/aac/stream.aac?aggregator=web`
- **Quality**: 192 kbps AAC
- **Genre**: Culture
- **Description**: German public radio focusing on culture, arts, and science

### 5. Deutschlandfunk Nova (Germany)
- **URL**: `https://st03.sslstream.dlf.de/dlf/03/high/aac/stream.aac?aggregator=web`
- **Quality**: 192 kbps AAC
- **Genre**: Youth
- **Description**: German public radio targeting younger audiences with music and informative content

## Script

To add these stations, use:
```bash
cd ~/moodeaudio-cursor && ./scripts/audio/ADD_FAVORITE_RADIO_STATIONS.sh
```

The script will:
- Check if stations already exist (skip if present)
- Add stations with best quality streams (192kbps AAC/MP3)
- Set appropriate metadata (genre, country, language)

## Notes

- All stations use high-quality streams (192kbps)
- Deutschlandfunk stations use AAC format for best quality
- FM4 and Radio Ton Heilbronn use MP3 format
- Stations are configured with German language and European region
- All stations are accessible in the moOde Radio section

