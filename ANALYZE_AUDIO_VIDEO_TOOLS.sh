#!/bin/bash
################################################################################
#
# ANALYZE AUDIO & VIDEO DEBUGGING TOOLS
#
# Analysiert, welche Audio- und Video-Debugging-Tools bereits vorhanden sind
# und welche noch nützlich wären.
#
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[NOTE]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
audio() { echo -e "${CYAN}[AUDIO]${NC} $1"; }
video() { echo -e "${CYAN}[VIDEO]${NC} $1"; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎵🎬 AUDIO & VIDEO DEBUGGING TOOLS ANALYSE                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT="/Users/andrevollmer/moodeaudio-cursor"
STAGE2_PACKAGES="$PROJECT_ROOT/imgbuild/moode-cfg/stage2_04-moode-install_01-packages"
STAGE3_PACKAGES="$PROJECT_ROOT/imgbuild/moode-cfg/stage3_01-moode-install_01-packages"

################################################################################
# AUDIO TOOLS - BEREITS INSTALLIERT
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎵 AUDIO TOOLS - BEREITS INSTALLIERT                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ -f "$STAGE2_PACKAGES" ]; then
    echo "📦 ALSA (Advanced Linux Sound Architecture):"
    grep -E "alsa|bluez" "$STAGE2_PACKAGES" | grep -v "^#" | while read pkg; do
        audio "  ✅ $pkg"
    done
    echo ""
    
    echo "📦 Audio Processing:"
    grep -E "ffmpeg|sox|flac|bs2b" "$STAGE2_PACKAGES" | grep -v "^#" | while read pkg; do
        audio "  ✅ $pkg"
    done
    echo ""
    
    echo "📦 Audio Metadata:"
    grep -E "mediainfo|id3v2" "$STAGE2_PACKAGES" | grep -v "^#" | while read pkg; do
        audio "  ✅ $pkg"
    done
    echo ""
fi

if [ -f "$STAGE3_PACKAGES" ]; then
    echo "📦 Moode Audio Components:"
    grep -E "alsa-cdsp|camilladsp|mpd|shairport|squeezelite" "$STAGE3_PACKAGES" | grep -v "^#" | while read pkg; do
        audio "  ✅ $pkg"
    done
    echo ""
fi

################################################################################
# VIDEO TOOLS - BEREITS INSTALLIERT
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎬 VIDEO TOOLS - BEREITS INSTALLIERT                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ -f "$STAGE2_PACKAGES" ]; then
    echo "📦 Display & Graphics:"
    grep -E "chromium|xorg|xinit" "$STAGE2_PACKAGES" | grep -v "^#" | while read pkg; do
        video "  ✅ $pkg"
    done
    echo ""
    
    echo "📦 Video Processing:"
    grep -E "ffmpeg" "$STAGE2_PACKAGES" | grep -v "^#" | while read pkg; do
        video "  ✅ $pkg"
    done
    echo ""
fi

################################################################################
# FEHLENDE AUDIO DEBUGGING TOOLS
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎵 FEHLENDE AUDIO DEBUGGING TOOLS                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 ALSA DEBUGGING:"
echo "  ⚠️  alsa-utils - aplay, arecord, alsamixer, alsactl, amixer"
echo "     → WICHTIG: Für Audio-Device-Tests und Mixer-Kontrolle"
echo "     → Enthält: aplay (Playback-Test), arecord (Recording-Test)"
echo "     → Enthält: alsamixer (Mixer-GUI), alsactl (Mixer-Save/Restore)"
echo ""

echo "🔍 AUDIO ANALYSIS:"
echo "  ⚠️  pulseaudio-utils - pactl, pacmd (falls PulseAudio verwendet)"
echo "  ⚠️  pavucontrol - PulseAudio Volume Control (GUI, falls X11)"
echo "  ⚠️  pulseaudio - PulseAudio Server (falls benötigt)"
echo ""

echo "🔍 AUDIO HARDWARE INFO:"
echo "  ⚠️  alsa-tools - aplay -l, arecord -l (Device-Liste)"
echo "  ⚠️  alsa-oss - OSS-Emulation (für alte Tools)"
echo ""

echo "🔍 AUDIO TEST & GENERATION:"
echo "  ⚠️  sox - Bereits installiert ✅"
echo "  ⚠️  alsa-utils - Für aplay/arecord Tests"
echo "  ⚠️  speaker-test - ALSA Speaker Test (in alsa-utils)"
echo ""

echo "🔍 AUDIO MONITORING:"
echo "  ⚠️  alsa-utils - amixer (Mixer-Werte anzeigen)"
echo "  ⚠️  alsa-utils - alsactl monitor (Mixer-Änderungen überwachen)"
echo ""

echo "🔍 AUDIO FORMAT CONVERSION:"
echo "  ⚠️  ffmpeg - Bereits installiert ✅"
echo "  ⚠️  sox - Bereits installiert ✅"
echo "  ⚠️  lame - MP3-Encoding (falls nötig)"
echo ""

################################################################################
# FEHLENDE VIDEO DEBUGGING TOOLS
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎬 FEHLENDE VIDEO DEBUGGING TOOLS                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 DISPLAY INFO:"
echo "  ⚠️  xrandr - Bereits in xorg installiert ✅"
echo "  ⚠️  xdpyinfo - Display-Informationen (X11)"
echo "  ⚠️  xwininfo - Window-Informationen (X11)"
echo "  ⚠️  xdotool - Bereits installiert ✅"
echo ""

echo "🔍 FRAMEBUFFER DEBUGGING:"
echo "  ⚠️  fbset - Framebuffer-Einstellungen anzeigen/ändern"
echo "  ⚠️  fbi - Framebuffer Image Viewer (für Tests)"
echo ""

echo "🔍 VIDEO HARDWARE INFO:"
echo "  ⚠️  vcgencmd - Raspberry Pi VideoCore-Info (bereits in firmware)"
echo "     → vcgencmd get_display (Display-Info)"
echo "     → vcgencmd get_hdmi_timings (HDMI-Timings)"
echo "     → vcgencmd measure_temp (GPU-Temperatur)"
echo ""

echo "🔍 VIDEO CAPTURE (falls nötig):"
echo "  ⚠️  v4l-utils - Video4Linux Tools (v4l2-ctl, v4l2-info)"
echo "  ⚠️  v4l2loopback-utils - Virtual Video Device (falls nötig)"
echo ""

echo "🔍 VIDEO TEST & PLAYBACK:"
echo "  ⚠️  ffmpeg - Bereits installiert ✅"
echo "  ⚠️  ffplay - FFmpeg Video Player (in ffmpeg)"
echo "  ⚠️  mplayer - Video Player (falls nötig)"
echo ""

echo "🔍 X11 DEBUGGING:"
echo "  ⚠️  xev - X11 Event Viewer (für Touchscreen-Debugging)"
echo "  ⚠️  xinput - X11 Input-Device-Management"
echo "  ⚠️  xset - X11 Display-Einstellungen"
echo ""

################################################################################
# KRITISCHE FEHLENDE TOOLS
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ⚠️  KRITISCHE FEHLENDE TOOLS                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🎵 AUDIO (KRITISCH):"
echo "  ❌ alsa-utils - FEHLT!"
echo "     → Enthält: aplay, arecord, alsamixer, alsactl, amixer, speaker-test"
echo "     → WICHTIG für: Audio-Device-Tests, Mixer-Kontrolle, Playback-Tests"
echo ""

echo "🎬 VIDEO (WICHTIG):"
echo "  ⚠️  xdpyinfo - Display-Informationen (X11)"
echo "  ⚠️  xwininfo - Window-Informationen (X11)"
echo "  ⚠️  fbset - Framebuffer-Einstellungen"
echo "  ⚠️  xev - X11 Event Viewer (Touchscreen-Debugging)"
echo "  ⚠️  xinput - X11 Input-Device-Management"
echo ""

################################################################################
# EMPFEHLUNG
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  💡 EMPFEHLUNG                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "✅ KRITISCH (MUSS installiert werden):"
echo "   1. alsa-utils"
echo "      → aplay - Audio-Playback-Test"
echo "      → arecord - Audio-Recording-Test"
echo "      → alsamixer - Mixer-GUI (interaktiv)"
echo "      → alsactl - Mixer-Save/Restore"
echo "      → amixer - Mixer-Kontrolle (CLI)"
echo "      → speaker-test - Speaker-Test"
echo ""

echo "✅ WICHTIG (sollte installiert werden):"
echo "   2. x11-utils (enthält xdpyinfo, xwininfo, xev, xinput)"
echo "      → xdpyinfo - Display-Informationen"
echo "      → xwininfo - Window-Informationen"
echo "      → xev - X11 Event Viewer (Touchscreen)"
echo "      → xinput - Input-Device-Management"
echo ""

echo "✅ NÜTZLICH (optional):"
echo "   3. fbset - Framebuffer-Einstellungen"
echo "   4. fbi - Framebuffer Image Viewer"
echo "   5. v4l-utils - Video4Linux Tools (falls Video-Capture nötig)"
echo ""

echo "📋 INSTALLATION:"
echo "   Diese Pakete sollten in stage2_04-moode-install_01-packages"
echo "   oder in stage3_03-ghettoblaster-custom/00-run-chroot.sh"
echo "   hinzugefügt werden."
echo ""

echo "🔧 BEISPIEL-KOMMANDOS (nach Installation):"
echo ""
echo "   # Audio-Device-Liste:"
echo "   aplay -l"
echo "   arecord -l"
echo ""
echo "   # Audio-Test:"
echo "   speaker-test -c 2 -t wav"
echo "   aplay /usr/share/sounds/alsa/Front_Left.wav"
echo ""
echo "   # Mixer-Kontrolle:"
echo "   alsamixer"
echo "   amixer scontrols"
echo "   amixer sget 'Master'"
echo ""
echo "   # Display-Info:"
echo "   xdpyinfo | grep dimensions"
echo "   xrandr --query"
echo "   vcgencmd get_display"
echo ""
echo "   # Touchscreen-Debugging:"
echo "   xev | grep -A 5 'ButtonPress'"
echo "   xinput list"
echo "   xinput test <device-id>"
echo ""

