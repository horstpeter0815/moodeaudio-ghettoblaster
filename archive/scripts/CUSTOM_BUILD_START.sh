#!/bin/bash
# Ghettoblaster - Custom Build Start
# Bereitet Custom Build vor und startet Analyse

LOG_FILE="custom-build-start-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== GHETTOBLASTER CUSTOM BUILD - START ===" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 1: BUILD-UMGEBUNG PRÜFEN ==="

# Prüfe ob imgbuild Repository vorhanden
if [ -d "imgbuild" ]; then
    log "✅ imgbuild Repository gefunden"
    cd imgbuild
    log "Aktuelles Verzeichnis: $(pwd)"
else
    log "⚠️  imgbuild Repository nicht gefunden"
    log "   Klone moOde imgbuild Repository..."
    
    # Prüfe ob Git verfügbar
    if ! command -v git &> /dev/null; then
        log "❌ Git nicht installiert"
        exit 1
    fi
    
    log "Klone https://github.com/moode-player/imgbuild.git..."
    git clone https://github.com/moode-player/imgbuild.git
    if [ $? -eq 0 ]; then
        log "✅ imgbuild Repository geklont"
        cd imgbuild
    else
        log "❌ Fehler beim Klonen"
        exit 1
    fi
fi

log ""
log "=== SCHRITT 2: REPOSITORY-STRUKTUR ANALYSIEREN ==="

log "Verzeichnis-Struktur:"
ls -la | head -20 | tee -a "$LOG_FILE"

log ""
log "README prüfen:"
if [ -f "README.md" ]; then
    head -50 README.md | tee -a "$LOG_FILE"
else
    log "⚠️  README.md nicht gefunden"
fi

log ""
log "=== SCHRITT 3: BUILD-ABHÄNGIGKEITEN PRÜFEN ==="

# Prüfe Docker (für Pi-gen)
if command -v docker &> /dev/null; then
    log "✅ Docker gefunden: $(docker --version)"
else
    log "⚠️  Docker nicht gefunden - möglicherweise native Build nötig"
fi

# Prüfe Python
if command -v python3 &> /dev/null; then
    log "✅ Python3 gefunden: $(python3 --version)"
else
    log "⚠️  Python3 nicht gefunden"
fi

log ""
log "=== SCHRITT 4: MOODE SOURCE ANALYSIEREN ==="

if [ -d "../moode-source" ]; then
    log "✅ moode-source Verzeichnis gefunden"
    
    log "Wichtige Verzeichnisse:"
    ls -d ../moode-source/{boot,etc,lib,usr,var} 2>/dev/null | tee -a "$LOG_FILE"
    
    log ""
    log "Systemd Services in moode-source:"
    find ../moode-source -name "*.service" -type f | head -10 | tee -a "$LOG_FILE"
else
    log "⚠️  moode-source Verzeichnis nicht gefunden"
fi

log ""
log "=== SCHRITT 5: CUSTOM KOMPONENTEN VORBEREITEN ==="

# Erstelle Verzeichnis für Custom Komponenten
mkdir -p custom-components/{overlays,services,configs,scripts}

log "✅ Custom Components Verzeichnis erstellt:"
ls -la custom-components/ | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Build-Umgebung geprüft"
log "✅ Repository-Struktur analysiert"
log "✅ Custom Components Verzeichnis erstellt"
log ""
log "Nächste Schritte:"
log "  1. moOde Source analysieren"
log "  2. Custom Overlays erstellen"
log "  3. Custom Services erstellen"
log "  4. Config-Templates erstellen"
log "  5. Build-Konfiguration anpassen"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ CUSTOM BUILD VORBEREITUNG ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

