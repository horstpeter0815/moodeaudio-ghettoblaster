#!/bin/bash
################################################################################
#
# GITHUB HELPER
# 
# Nutzt GitHub Token aus .env für API-Zugriffe
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# Load GitHub Token from .env
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | grep GITHUB_TOKEN | xargs)
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[GITHUB]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

################################################################################
# GITHUB API FUNCTIONS
################################################################################

check_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        error "GITHUB_TOKEN nicht gefunden!"
        error "Bitte .env Datei mit GITHUB_TOKEN erstellen"
        return 1
    fi
    
    # Test token
    local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)
    if echo "$response" | grep -q '"login"'; then
        local username=$(echo "$response" | grep '"login"' | head -1 | cut -d'"' -f4)
        log "✅ GitHub Token gültig (User: $username)"
        return 0
    else
        error "❌ GitHub Token ungültig oder abgelaufen"
        return 1
    fi
}

download_release() {
    local repo="$1"
    local asset_pattern="$2"
    local output_dir="${3:-$PROJECT_ROOT/downloads}"
    
    if [ -z "$GITHUB_TOKEN" ]; then
        error "GITHUB_TOKEN nicht gesetzt"
        return 1
    fi
    
    if [ -z "$repo" ]; then
        error "Usage: download_release <owner/repo> [asset_pattern] [output_dir]"
        return 1
    fi
    
    info "Lade neueste Release von $repo..."
    
    # Get latest release
    local release_url="https://api.github.com/repos/$repo/releases/latest"
    local release_data=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$release_url")
    
    if echo "$release_data" | grep -q '"message"'; then
        error "Release nicht gefunden: $repo"
        return 1
    fi
    
    # Get asset URL
    local asset_url=$(echo "$release_data" | grep '"browser_download_url"' | grep -i "${asset_pattern:-}" | head -1 | cut -d'"' -f4)
    
    if [ -z "$asset_url" ]; then
        error "Asset nicht gefunden (Pattern: ${asset_pattern:-any})"
        return 1
    fi
    
    local filename=$(basename "$asset_url")
    mkdir -p "$output_dir"
    
    info "Lade: $filename"
    curl -L -H "Authorization: token $GITHUB_TOKEN" -o "$output_dir/$filename" "$asset_url"
    
    if [ $? -eq 0 ]; then
        log "✅ Download erfolgreich: $output_dir/$filename"
        echo "$output_dir/$filename"
    else
        error "Download fehlgeschlagen"
        return 1
    fi
}

################################################################################
# MAIN
################################################################################

case "${1:-}" in
    check|test)
        check_token
        ;;
    download)
        shift
        download_release "$@"
        ;;
    *)
        echo "GitHub Helper"
        echo ""
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  check          - Prüfe GitHub Token"
        echo "  download <repo> [asset_pattern] [output_dir] - Lade Release"
        echo ""
        echo "Examples:"
        echo "  $0 check"
        echo "  $0 download moodeaudio/moode r900 .img.zip"
        ;;
esac

