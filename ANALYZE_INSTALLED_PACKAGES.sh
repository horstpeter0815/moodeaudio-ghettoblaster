#!/bin/bash
################################################################################
#
# ANALYZE INSTALLED PACKAGES - Was ist bereits installiert?
#
# Analysiert die Paketlisten und zeigt, was bereits vorhanden ist
# und was noch nützlich sein könnte.
#
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[NOTE]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📦 ANALYSE: INSTALLIERTE PAKETE                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT="/Users/andrevollmer/moodeaudio-cursor"
STAGE2_PACKAGES="$PROJECT_ROOT/imgbuild/moode-cfg/stage2_04-moode-install_01-packages"
STAGE3_PACKAGES="$PROJECT_ROOT/imgbuild/moode-cfg/stage3_01-moode-install_01-packages"

echo "📋 BASIS: Raspberry Pi OS Lite"
echo "   → Minimales System ohne Desktop-Environment"
echo "   → Optimiert für Embedded/Headless-Anwendungen"
echo ""

################################################################################
# STAGE 2 PACKAGES (Standard Moode Packages)
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  STAGE 2: STANDARD MOODE PACKAGES                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ -f "$STAGE2_PACKAGES" ]; then
    TOTAL=$(grep -v "^#" "$STAGE2_PACKAGES" | grep -v "^$" | wc -l | tr -d ' ')
    log "Anzahl Pakete: $TOTAL"
    echo ""
    
    echo "📦 KATEGORIEN:"
    echo ""
    
    # Web & Network
    echo "🌐 Web & Network:"
    grep -E "nginx|php|avahi|shellinabox|samba|nfs|wsdd2" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
    
    # Audio
    echo "🎵 Audio:"
    grep -E "alsa|bluez|ffmpeg|sox|flac|bs2b" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
    
    # Display & Graphics
    echo "🖥️  Display & Graphics:"
    grep -E "chromium|xorg|xinit|fonts" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
    
    # Python
    echo "🐍 Python:"
    grep -E "python3" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
    
    # System Tools
    echo "🔧 System Tools:"
    grep -E "nmap|telnet|tree|lsof|sysstat|dos2unix|expect|triggerhappy" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
    
    # Storage
    echo "💾 Storage:"
    grep -E "ntfs|exfat|squashfs|xfs" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
    
    # Database
    echo "🗄️  Database:"
    grep -E "sqlite" "$STAGE2_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
else
    error "Stage 2 Paketliste nicht gefunden: $STAGE2_PACKAGES"
fi

################################################################################
# STAGE 3 PACKAGES (Moode-Specific Packages)
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  STAGE 3: MOODE-SPECIFIC PACKAGES                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ -f "$STAGE3_PACKAGES" ]; then
    TOTAL=$(grep -v "^#" "$STAGE3_PACKAGES" | grep -v "^$" | wc -l | tr -d ' ')
    log "Anzahl Pakete: $TOTAL"
    echo ""
    
    echo "📦 MOODE-AUDIO KOMPONENTEN:"
    echo ""
    grep -E "moode-player|mpd|alsa-cdsp|camilladsp|shairport|squeezelite|upmpdcli|peppy" "$STAGE3_PACKAGES" | grep -v "^#" | sed 's/^/  ✅ /'
    echo ""
else
    error "Stage 3 Paketliste nicht gefunden: $STAGE3_PACKAGES"
fi

################################################################################
# CUSTOM COMPONENTS
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  CUSTOM: GHETTOBLASTER KOMPONENTEN                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

CUSTOM_SCRIPT="$PROJECT_ROOT/imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh"

if [ -f "$CUSTOM_SCRIPT" ]; then
    echo "📦 ZUSÄTZLICHE PYTHON-PAKETE:"
    grep -E "python3-scipy|python3-soundfile|python3-numpy|xdotool" "$CUSTOM_SCRIPT" | grep "apt-get install" | sed 's/.*install -y //' | sed 's/ ||.*//' | tr ' ' '\n' | grep -v "^$" | sed 's/^/  ✅ /'
    echo ""
fi

################################################################################
# FEHLENDE NÜTZLICHE TOOLS
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  💡 EMPFOHLENE ZUSÄTZLICHE KOMPONENTEN                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 DEBUGGING & MONITORING:"
echo "  ⚠️  htop - Interaktiver Prozess-Monitor (besser als top)"
echo "  ⚠️  strace - System-Call-Tracer (für Debugging)"
echo "  ⚠️  tcpdump - Netzwerk-Packet-Analyzer"
echo "  ⚠️  iotop - I/O-Monitoring"
echo "  ⚠️  net-tools - netstat, ifconfig (veraltet, aber nützlich)"
echo "  ⚠️  iftop - Netzwerk-Bandbreiten-Monitor"
echo ""

echo "📝 TEXT-EDITOREN:"
echo "  ⚠️  nano - Einfacher Text-Editor (könnte fehlen)"
echo "  ⚠️  vim - Erweiterter Text-Editor (könnte fehlen)"
echo ""

echo "🔧 ENTWICKLUNGS-TOOLS:"
echo "  ⚠️  git - Versionskontrolle (für Updates/Patches)"
echo "  ⚠️  build-essential - Compiler-Tools (gcc, make, etc.)"
echo "  ⚠️  curl - HTTP-Client (könnte schon da sein)"
echo "  ⚠️  wget - Download-Tool (könnte schon da sein)"
echo ""

echo "💾 BACKUP & SYNC:"
echo "  ⚠️  rsync - Effiziente Datei-Synchronisation"
echo ""

echo "🖥️  TERMINAL-TOOLS:"
echo "  ⚠️  screen - Terminal-Multiplexer"
echo "  ⚠️  tmux - Terminal-Multiplexer (moderner als screen)"
echo ""

echo "📊 DATA-TOOLS:"
echo "  ⚠️  jq - JSON-Parser (für API-Calls)"
echo ""

echo "🔐 SECURITY:"
echo "  ⚠️  fail2ban - Brute-Force-Schutz (wenn SSH exponiert)"
echo ""

################################################################################
# EMPFEHLUNG
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  💡 EMPFEHLUNG                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "✅ BEREITS INSTALLIERT (sehr gut):"
echo "   - Chromium (Display)"
echo "   - Xorg, xinit (X Server)"
echo "   - Python3, pip, pygame (PeppyMeter)"
echo "   - Shellinabox (WebSSH)"
echo "   - nmap, telnet (Netzwerk-Tools)"
echo "   - tree, lsof (System-Tools)"
echo "   - sysstat (Monitoring)"
echo "   - nginx, php-fpm (Web-Server)"
echo "   - ffmpeg, sox (Audio-Tools)"
echo "   - sqlite3 (Datenbank)"
echo "   - samba, nfs (File-Sharing)"
echo ""

echo "⚠️  EMPFOHLEN (für Debugging/Maintenance):"
echo "   1. htop - Bessere Prozess-Übersicht"
echo "   2. nano - Einfacher Text-Editor"
echo "   3. git - Für Updates/Patches"
echo "   4. rsync - Für Backups"
echo "   5. screen/tmux - Für persistente SSH-Sessions"
echo ""

echo "❓ OPTIONAL (nur wenn nötig):"
echo "   - build-essential - Nur wenn Kompilierung nötig"
echo "   - strace, tcpdump - Nur für erweiterte Debugging"
echo "   - jq - Nur wenn JSON-APIs verwendet werden"
echo ""

echo "📋 FAZIT:"
echo "   Das System ist bereits sehr gut ausgestattet für einen"
echo "   Audio-Player. Die empfohlenen Tools sind 'nice-to-have'"
echo "   für erweiterte Wartung, aber nicht kritisch."
echo ""

