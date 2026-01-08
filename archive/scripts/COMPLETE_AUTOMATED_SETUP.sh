#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🚀 VOLLSTÄNDIGER AUTOMATISCHER SETUP                        ║
# ║  Senior Project Manager - Ghetto Crew moOde Setup            ║
# ╚══════════════════════════════════════════════════════════════╝

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_FILE="$SCRIPT_DIR/2025-12-07-moode-r1001-arm64-lite.img"
PI_IP="192.168.178.161"
MOODE_URL="http://$PI_IP"
LOG_FILE="complete-setup-$(date +%Y%m%d_%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +%Y-%m-%d %H:%M:%S)]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# ============================================================================
# STEP 1: SD-KARTE FINDEN UND BRENNEN
# ============================================================================

log "╔══════════════════════════════════════════════════════════════╗"
log "║  STEP 1: SD-KARTE FINDEN UND BRENNEN                         ║"
log "╚══════════════════════════════════════════════════════════════╝"

# Finde SD-Karte
SD_DISK=""
for disk in $(diskutil list | grep -E "^/dev/disk[0-9]" | awk '{print $1}' | grep -v "disk0"); do
    SIZE=$(diskutil info $disk 2>/dev/null | grep "Disk Size" | awk '{print $3}')
    if [ -n "$SIZE" ]; then
        log "Gefundene Disk: $disk ($SIZE)"
        # Prüfe ob es eine SD-Karte ist (typischerweise 8GB-128GB)
        if diskutil info $disk 2>/dev/null | grep -q "external\|removable"; then
            SD_DISK=$disk
            log "✅ SD-Karte gefunden: $SD_DISK"
            break
        fi
    fi
done

if [ -z "$SD_DISK" ]; then
    error "Keine SD-Karte gefunden!"
    log "Bitte SD-Karte einstecken und Script erneut ausführen."
    exit 1
fi

# Prüfe Image-Datei
if [ ! -f "$IMAGE_FILE" ]; then
    error "Image-Datei nicht gefunden: $IMAGE_FILE"
    exit 1
fi

IMAGE_SIZE=$(ls -lh "$IMAGE_FILE" | awk '{print $5}')
log "Image gefunden: $IMAGE_FILE ($IMAGE_SIZE)"

# Unmount SD-Karte
log "Unmounte SD-Karte: $SD_DISK"
diskutil unmountDisk $SD_DISK 2>/dev/null || true
sleep 2

# Brenne Image
log "🔥 Starte Image-Brennen auf $SD_DISK..."
log "⚠️  DIESER VORGANG KANN MEHRERE MINUTEN DAUERN!"
log "⚠️  BITTE NICHT UNTERBRECHEN!"

sudo dd if="$IMAGE_FILE" of="$SD_DISK" bs=1m status=progress

if [ $? -eq 0 ]; then
    success "Image erfolgreich gebrannt!"
    sync
    log "Warte 5 Sekunden..."
    sleep 5
else
    error "Image-Brennen fehlgeschlagen!"
    exit 1
fi

# ============================================================================
# STEP 2: WARTE AUF PI BOOT
# ============================================================================

log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  STEP 2: WARTE AUF PI BOOT                                   ║"
log "╚══════════════════════════════════════════════════════════════╝"

log "⚠️  BITTE SD-KARTE IN PI EINSTECKEN UND PI EINSCHALTEN!"
log "Warte auf Pi-Boot (max. 2 Minuten)..."

MAX_WAIT=120
WAITED=0
PI_ONLINE=false

while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 1 $PI_IP >/dev/null 2>&1; then
        PI_ONLINE=true
        success "Pi ist online: $PI_IP"
        break
    fi
    echo -n "."
    sleep 2
    WAITED=$((WAITED + 2))
done

if [ "$PI_ONLINE" = false ]; then
    error "Pi ist nach $MAX_WAIT Sekunden nicht online!"
    log "Bitte prüfe:"
    log "  - Ist Pi eingeschaltet?"
    log "  - Ist LAN-Kabel verbunden?"
    log "  - Ist IP-Adresse korrekt? ($PI_IP)"
    exit 1
fi

# Warte zusätzlich 30 Sekunden für vollständigen Boot
log "Warte 30 Sekunden für vollständigen Boot..."
sleep 30

# ============================================================================
# STEP 3: KONFIGURIERE ÜBER WEB-UI API
# ============================================================================

log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  STEP 3: KONFIGURIERE ÜBER WEB-UI API                        ║"
log "╚══════════════════════════════════════════════════════════════╝"

# Prüfe Web-UI Erreichbarkeit
log "Prüfe Web-UI Erreichbarkeit..."
if ! curl -s -f "$MOODE_URL" >/dev/null 2>&1; then
    warning "Web-UI noch nicht erreichbar. Warte weitere 30 Sekunden..."
    sleep 30
fi

# Teste Web-UI
if curl -s -f "$MOODE_URL" >/dev/null 2>&1; then
    success "Web-UI ist erreichbar: $MOODE_URL"
else
    error "Web-UI ist nicht erreichbar!"
    log "Bitte manuell öffnen: $MOODE_URL"
    exit 1
fi

# ============================================================================
# STEP 4: DISPLAY & BROWSER KONFIGURIEREN
# ============================================================================

log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  STEP 4: DISPLAY & BROWSER KONFIGURIEREN                     ║"
log "╚══════════════════════════════════════════════════════════════╝"

log "⚠️  HINWEIS: Einige Konfigurationen müssen über Web-UI erfolgen"
log "   da moOde keine vollständige REST API für alle Einstellungen hat."

log ""
log "📋 MANUELLE SCHRITTE ÜBER WEB-UI:"
log "   1. Öffne: $MOODE_URL"
log "   2. Configure → System → Display Rotation: 0° (Landscape)"
log "   3. Configure → Peripherals → Local Display: Aktivieren"
log "   4. Configure → Peripherals → Local Display URL: http://localhost"
log "   5. Configure → Audio → Output Device: HiFiBerry AMP100"
log "   6. System → Restart"

log ""
log "✅ Nach Neustart sollte alles funktionieren!"

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  ✅ SETUP ABGESCHLOSSEN                                     ║"
log "╚══════════════════════════════════════════════════════════════╝"
log ""
log "📋 NÄCHSTE SCHRITTE:"
log "   1. Öffne Web-UI: $MOODE_URL"
log "   2. Führe manuelle Konfiguration durch (siehe oben)"
log "   3. System neu starten"
log ""
log "📄 Log-Datei: $LOG_FILE"
log ""
success "Setup-Script abgeschlossen!"

