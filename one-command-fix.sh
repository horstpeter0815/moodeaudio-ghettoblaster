#!/bin/bash
# One command to fix everything - run this once on moOde

DB="/var/local/www/db/moode-sqlite3.db"
CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

# Fix display conflict
[ "$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)" = "1" ] && \
[ "$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)" = "1" ] && \
sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"

# Fix CamillaDSP device if peppy
[ -f "$CONFIG" ] && grep -qi "peppy" "$CONFIG" && \
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "plughw") && \
CARDNUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "0") && \
DEVICE="${ALSA_MODE}:${CARDNUM},0" && \
python3 -c "import re; c=open('$CONFIG').read(); c=re.sub(r'device:\s*[\"'\']?peppy[\"'\']?', f'device: \"$DEVICE\"', c, flags=re.I); open('$CONFIG','w').write(c)" && \
sudo rm -f /usr/share/camilladsp/working_config.yml && \
sudo ln -s "$CONFIG" /usr/share/camilladsp/working_config.yml

# Start mpd2cdspvolume if needed
CAMILLADSP=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)
MIXER_TYPE=$(sqlite3 "$DB" "SELECT value FROM cfg_mpd WHERE param='mixer_type';" 2>/dev/null)
[ "$CAMILLADSP" != "off" ] && [ "$MIXER_TYPE" = "null" ] && ! systemctl is-active --quiet mpd2cdspvolume && \
sudo systemctl start mpd2cdspvolume

# Restart services
sudo systemctl restart worker 2>/dev/null
sudo systemctl restart mpd

echo "✓ Fix complete - clear browser cache (Cmd+Shift+R)"

