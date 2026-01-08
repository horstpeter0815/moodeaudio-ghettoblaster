#!/bin/bash
################################################################################
#
# VERSION MANAGEMENT TOOL
# 
# Verwaltet Versionen, Tags und Device-spezifische Konfigurationen
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[VERSION]${NC} $1"
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
# VERSION FUNCTIONS
################################################################################

get_build_number() {
    if [ -f "BUILD_COUNTER.txt" ]; then
        cat BUILD_COUNTER.txt | head -1
    else
        echo "0"
    fi
}

increment_build() {
    local current=$(get_build_number)
    local next=$((current + 1))
    echo "$next" > BUILD_COUNTER.txt
    log "Build-Nummer erhöht: $current → $next"
    echo "$next"
}

get_version_string() {
    local device="${1:-pi5}"
    local build=$(get_build_number)
    local date=$(date +"%Y%m%d")
    local time=$(date +"%H%M%S")
    echo "v${build}-${device}-${date}-${time}"
}

################################################################################
# GIT FUNCTIONS
################################################################################

create_tag() {
    local device="${1:-pi5}"
    local message="${2:-}"
    local build=$(get_build_number)
    local version=$(get_version_string "$device")
    
    if [ -z "$message" ]; then
        message="Build #${build} for ${device}"
    fi
    
    log "Erstelle Git Tag: $version"
    
    if git tag -a "$version" -m "$message" 2>/dev/null; then
        log "✅ Tag erstellt: $version"
        echo "$version"
    else
        error "Tag konnte nicht erstellt werden"
        return 1
    fi
}

list_tags() {
    local device="${1:-}"
    
    if [ -n "$device" ]; then
        git tag -l "*-${device}-*" | sort -V
    else
        git tag -l | sort -V
    fi
}

show_tag_info() {
    local tag="$1"
    
    if git rev-parse "$tag" >/dev/null 2>&1; then
        info "Tag: $tag"
        git show "$tag" --no-patch --format="  Commit: %H%n  Datum: %ai%n  Autor: %an%n  Nachricht: %s" 2>/dev/null || true
    else
        error "Tag nicht gefunden: $tag"
        return 1
    fi
}

################################################################################
# DEVICE MANAGEMENT
################################################################################

get_device_config() {
    local device="$1"
    
    case "$device" in
        pi4|pi-4|raspberry-pi-4)
            echo "PI4_MOODE_CONFIG.txt"
            ;;
        pi5|pi-5|raspberry-pi-5)
            echo "PI5_WORKING_CONFIG.txt"
            ;;
        *)
            error "Unbekanntes Gerät: $device"
            return 1
            ;;
    esac
}

switch_device_branch() {
    local device="$1"
    local branch="device/${device}"
    
    log "Wechsle zu Device-Branch: $branch"
    
    # Prüfe ob Branch existiert
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git checkout "$branch"
        log "✅ Zu Branch gewechselt: $branch"
    else
        warn "Branch existiert nicht, erstelle: $branch"
        git checkout -b "$branch"
        log "✅ Branch erstellt und gewechselt: $branch"
    fi
}

list_devices() {
    info "Verfügbare Geräte:"
    echo "  - pi4  (Raspberry Pi 4)"
    echo "  - pi5  (Raspberry Pi 5)"
    echo ""
    
    info "Device-Branches:"
    git branch -a | grep "device/" | sed 's/^/  - /' || echo "  (keine)"
}

################################################################################
# GITHUB RELEASE
################################################################################

create_github_release() {
    local device="${1:-pi5}"
    local version=$(get_version_string "$device")
    local build=$(get_build_number)
    
    # Prüfe GitHub Token
    if [ -z "$GITHUB_TOKEN" ]; then
        if [ -f ".env" ]; then
            export $(grep -v '^#' .env | grep GITHUB_TOKEN | xargs)
        fi
    fi
    
    if [ -z "$GITHUB_TOKEN" ]; then
        error "GITHUB_TOKEN nicht gefunden"
        return 1
    fi
    
    # Prüfe ob Tag existiert
    if ! git rev-parse "$version" >/dev/null 2>&1; then
        warn "Tag $version existiert nicht, erstelle ihn zuerst"
        create_tag "$device" "Build #${build} for ${device}"
    fi
    
    info "Erstelle GitHub Release für: $version"
    
    # Get repo info
    local repo_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's/.*github\.com[:/]//')
    
    if [ -z "$repo_url" ]; then
        error "GitHub Remote nicht gefunden"
        return 1
    fi
    
    # Create release via API
    local release_data=$(cat <<EOF
{
  "tag_name": "$version",
  "name": "Build #${build} - ${device}",
  "body": "Build #${build} für ${device}\n\nDatum: $(date +"%Y-%m-%d %H:%M:%S")\nGerät: ${device}",
  "draft": false,
  "prerelease": false
}
EOF
)
    
    local response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$repo_url/releases" \
        -d "$release_data")
    
    if echo "$response" | grep -q '"id"'; then
        local release_url=$(echo "$response" | grep '"html_url"' | head -1 | cut -d'"' -f4)
        log "✅ GitHub Release erstellt: $release_url"
        echo "$release_url"
    else
        error "Release konnte nicht erstellt werden"
        echo "$response" | head -20
        return 1
    fi
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  📦 VERSION MANAGEMENT                                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Aktuelle Build-Nummer: $(get_build_number)"
    echo ""
    echo "1) Build-Nummer erhöhen"
    echo "2) Git Tag erstellen"
    echo "3) Tags auflisten"
    echo "4) Tag-Info anzeigen"
    echo "5) Device-Branch wechseln"
    echo "6) Geräte auflisten"
    echo "7) GitHub Release erstellen"
    echo "0) Exit"
    echo ""
    read -p "Select option: " choice
}

main() {
    case "${1:-}" in
        increment|inc)
            increment_build
            ;;
        tag)
            shift
            create_tag "${1:-pi5}" "${2:-}"
            ;;
        tags|list-tags)
            list_tags "${2:-}"
            ;;
        info)
            show_tag_info "${2:-}"
            ;;
        device|switch)
            switch_device_branch "${2:-pi5}"
            ;;
        devices|list-devices)
            list_devices
            ;;
        release)
            create_github_release "${2:-pi5}"
            ;;
        *)
            # Interactive mode
            while true; do
                show_menu
                case $choice in
                    1) increment_build ;;
                    2) 
                        read -p "Gerät (pi4/pi5) [pi5]: " device
                        read -p "Nachricht (optional): " message
                        create_tag "${device:-pi5}" "$message"
                        ;;
                    3)
                        read -p "Gerät filtern (optional): " device
                        list_tags "$device"
                        ;;
                    4)
                        read -p "Tag-Name: " tag
                        show_tag_info "$tag"
                        ;;
                    5)
                        read -p "Gerät (pi4/pi5): " device
                        switch_device_branch "$device"
                        ;;
                    6) list_devices ;;
                    7)
                        read -p "Gerät (pi4/pi5) [pi5]: " device
                        create_github_release "${device:-pi5}"
                        ;;
                    0) exit 0 ;;
                    *) error "Invalid option" ;;
                esac
                echo ""
                read -p "Press Enter to continue..."
            done
            ;;
    esac
}

main "$@"

