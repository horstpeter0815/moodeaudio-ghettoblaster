#!/bin/bash
################################################################################
# CREATE PLAYLIST FOR MOODE
# Creates a playlist file in /Volumes/Playlists
################################################################################

PLAYLIST_NAME="${1:-My_Playlist}"
PLAYLIST_FILE="/Volumes/Playlists/${PLAYLIST_NAME}.m3u"

if [ ! -d "/Volumes/Playlists" ]; then
    echo "❌ Playlists folder not found"
    echo "   Make sure GhettoBlaster is connected"
    exit 1
fi

cat > "$PLAYLIST_FILE" << EOF
#EXTM3U
#EXTINF:-1,${PLAYLIST_NAME}
# Playlist created for moOde Audio
# 
# To add music files, edit this file and add paths like:
# /var/lib/mpd/music/YourSong.mp3
# /var/lib/mpd/music/AnotherSong.flac
#
# Or use moOde web interface to add songs to this playlist
EOF

echo "✅ Created playlist: ${PLAYLIST_NAME}.m3u"
echo "   Location: $PLAYLIST_FILE"
echo ""
echo "To use in moOde:"
echo "  1. Open moOde web interface"
echo "  2. Go to Playlists"
echo "  3. Load this playlist file"

