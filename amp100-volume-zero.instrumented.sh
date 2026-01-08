#!/bin/bash
# AMP100 Volume Zero - Instrumented for debug (do not remove logs until verification)

region_marker_start="#region agent log"
region_marker_end="#endregion"

#region agent log
python3 - <<'PYLOG' 2>/dev/null || true
import json, time
log = {
  "sessionId": "debug-session",
  "runId": "pre-fix",
  "hypothesisId": "H1",
  "location": "amp100-volume-zero.sh:start",
  "message": "Volume-zero service start",
  "data": {},
  "timestamp": int(time.time()*1000)
}
open("/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log","a").write(json.dumps(log)+"\n")
PYLOG
#endregion

echo "=== AMP100 Volume Zero ==="

# Wait for sound system to be ready (max 10 seconds)
SOUND_READY=false
for i in {1..10}; do
    if systemctl is-active sound.target >/dev/null 2>&1 || [ -d /proc/asound ]; then
        SOUND_READY=true
        break
    fi
    sleep 1
done

if [ "$SOUND_READY" != "true" ]; then
    echo "⚠️  Sound system not ready after 10 seconds - continuing anyway"
fi

# Find AMP100 Card (sndrpihifiberry or similar)
AMP100_CARD=""
for card in /proc/asound/card*; do
    if [ -d "$card" ]; then
        CARD_NAME=$(cat "$card/id" 2>/dev/null || echo "")
        if echo "$CARD_NAME" | grep -qiE "hifiberry|sndrpihifiberry|amp100"; then
            CARD_NUM=$(basename "$card" | sed "s/card//")
            AMP100_CARD="$CARD_NUM"
            echo "✅ Found AMP100 Card: $CARD_NUM ($CARD_NAME)"
            break
        fi
    fi
done

if [ -z "$AMP100_CARD" ]; then
    echo "⚠️  AMP100 Card not found - trying default card 0"
    AMP100_CARD="0"
fi

#region agent log
python3 - <<'PYLOG' 2>/dev/null || true
import json, time, subprocess
cards = subprocess.getoutput("cat /proc/asound/cards 2>/dev/null")
log = {
  "sessionId": "debug-session",
  "runId": "pre-fix",
  "hypothesisId": "H1",
  "location": "amp100-volume-zero.sh:card-detect",
  "message": "Detected cards",
  "data": {"cards": cards},
  "timestamp": int(time.time()*1000)
}
open("/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log","a").write(json.dumps(log)+"\n")
PYLOG
#endregion

# Try multiple mixer controls (AMP100 might use PCM or Digital)
MIXER_CONTROLS="PCM Digital Master"
TARGET_MIXER_VOL="60"

for MIXER in $MIXER_CONTROLS; do
    echo "🔧 Setting $MIXER to ${TARGET_MIXER_VOL}% on Card $AMP100_CARD..."
    amixer -c "$AMP100_CARD" sset "$MIXER" ${TARGET_MIXER_VOL}% unmute 2>/dev/null || \
    amixer -c "$AMP100_CARD" sset "$MIXER" ${TARGET_MIXER_VOL}% 2>/dev/null || true
    
    VOLUME=$(amixer -c "$AMP100_CARD" get "$MIXER" 2>/dev/null | grep -oE "\[[0-9]+%\]" | head -1 | tr -d "[]%" || echo "")
    if [ -n "$VOLUME" ]; then
        echo "✅ $MIXER set to ${VOLUME}%"
    else
        echo "⚠️  $MIXER volume: ${VOLUME}% (attempted to set to ${TARGET_MIXER_VOL}%)"
    fi

    #region agent log
    MIXER_EXPORT="$MIXER" VOLUME_EXPORT="$VOLUME" CARD_EXPORT="$AMP100_CARD" python3 - <<'PYLOG' 2>/dev/null || true
import json, time, os, subprocess
mixer = os.environ.get('MIXER_EXPORT','')
card = os.environ.get('CARD_EXPORT','')
volume = os.environ.get('VOLUME_EXPORT','')
vol_out = subprocess.getoutput(f"amixer -c {card} get '{mixer}' 2>/dev/null | head -5") if mixer else ""
log = {
  "sessionId": "debug-session",
  "runId": "pre-fix",
  "hypothesisId": "H1",
  "location": "amp100-volume-zero.sh:mixer-check",
  "message": "Mixer state after set",
  "data": {"mixer": mixer, "card": card, "volumeParsed": volume, "output": vol_out},
  "timestamp": int(time.time()*1000)
}
open("/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log","a").write(json.dumps(log)+"\n")
PYLOG
    #endregion
done

# Also set via MPD mixer if available (but MPD might not be running yet)
TARGET_MPD_VOL="40"
if command -v mpc >/dev/null 2>&1; then
    mpc volume ${TARGET_MPD_VOL} 2>/dev/null || true
    echo "✅ MPD volume set to ${TARGET_MPD_VOL} (if MPD was running)"
fi

#region agent log
python3 - <<'PYLOG' 2>/dev/null || true
import json, time, subprocess
try:
    mpc_vol = subprocess.check_output(["mpc","volume"],stderr=subprocess.DEVNULL).decode().strip()
except Exception:
    mpc_vol = ""
log = {
  "sessionId": "debug-session",
  "runId": "pre-fix",
  "hypothesisId": "H2",
  "location": "amp100-volume-zero.sh:mpd-volume",
  "message": "MPD volume after zero",
  "data": {"mpcVolume": mpc_vol},
  "timestamp": int(time.time()*1000)
}
open("/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log","a").write(json.dumps(log)+"\n")
PYLOG
#endregion

echo "=== Volume Zero Complete ==="

