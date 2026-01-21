#!/bin/bash
# Setup only requested radio stations

PI_IP="192.168.2.3"
PI_USER="andre"
PI_PASS="0815"

echo "========================================="
echo "SETTING UP RADIO STATIONS"
echo "========================================="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no "$PI_USER@$PI_IP" << 'ENDSSH'

echo "==> Backing up current radio stations..."
sqlite3 /var/local/www/db/moode-sqlite3.db \
  ".output /tmp/cfg_radio_backup.sql" \
  ".dump cfg_radio"

echo "==> Deleting all radio stations..."
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "DELETE FROM cfg_radio"

echo "==> Adding requested stations..."

# Deutschlandfunk (best quality streams)
sqlite3 /var/local/www/db/moode-sqlite3.db << 'SQL'
INSERT INTO cfg_radio (station, name, type, logo) VALUES
('https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3', 'Deutschlandfunk 128k MP3', 'r', 'local'),
('https://st02.sslstream.dlf.de/dlf/02/high/aac/stream.aac', 'Deutschlandfunk High AAC', 'r', 'local'),
('https://st03.sslstream.dlf.de/dlf/03/high/opus/stream.opus', 'Deutschlandfunk High Opus', 'r', 'local');
SQL

# FM4 (Austria) - already exists, re-add
sqlite3 /var/local/www/db/moode-sqlite3.db << 'SQL'
INSERT INTO cfg_radio (station, name, type, logo) VALUES
('https://orf-live.ors-shoutcast.at/fm4-q2a', 'Radio FM4 Austria', 'r', 'local');
SQL

# Radio SRF 1 (Switzerland)
sqlite3 /var/local/www/db/moode-sqlite3.db << 'SQL'
INSERT INTO cfg_radio (station, name, type, logo) VALUES
('http://streaming.swisstxt.ch/m/drs1/mp3_128', 'Radio SRF 1 Schweiz', 'r', 'local');
SQL

# Radio Ton (Heilbronn)
sqlite3 /var/local/www/db/moode-sqlite3.db << 'SQL'
INSERT INTO cfg_radio (station, name, type, logo) VALUES
('https://stream.radioton.de/rt-live-mp3', 'Radio Ton Heilbronn', 'r', 'local');
SQL

echo ""
echo "==> Verifying stations..."
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT id, name FROM cfg_radio ORDER BY name"

echo ""
echo "✅ Radio stations configured"
echo ""
echo "Total stations: $(sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio')"

ENDSSH

echo ""
echo "========================================="
echo "✅ SETUP COMPLETE"
echo "========================================="
echo ""
echo "Your radio stations:"
echo "  - Deutschlandfunk (3 quality versions)"
echo "  - Radio FM4 (Austria)"
echo "  - Radio SRF 1 (Switzerland)"
echo "  - Radio Ton (Heilbronn)"
echo ""
echo "Refresh browser to see the stations"
