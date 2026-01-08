#!/bin/bash
# Ghettoblaster - PeppyMeter Wrapper
# Startet PeppyMeter mit Auto-Restart

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Prüfe ob X Server bereit ist
/usr/local/bin/xserver-ready.sh || exit 1

# Prüfe ob MPD läuft
if ! systemctl is-active --quiet mpd.service; then
    echo "MPD nicht aktiv, warte..."
    sleep 5
fi

# Starte PeppyMeter
if [ -f "/opt/peppymeter/peppymeter.py" ]; then
    cd /opt/peppymeter
    python3 peppymeter.py
elif [ -f "/usr/local/bin/peppymeter" ]; then
    /usr/local/bin/peppymeter
else
    echo "PeppyMeter nicht gefunden"
    exit 1
fi

