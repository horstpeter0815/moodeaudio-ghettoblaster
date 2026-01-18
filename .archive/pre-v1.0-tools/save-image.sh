#!/bin/bash
################################################################################
#
# SAVE IMAGE FROM RASPBERRY PI IMAGER
# 
# Findet und speichert das Image im Projekt
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_DIR="$PROJECT_ROOT/imgbuild/deploy"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[SAVE IMAGE]${NC} $1"
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
# SEARCH FUNCTIONS
################################################################################

search_image_files() {
    local search_dirs=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Documents"
        "/tmp"
    )
    
    info "Suche nach Image-Dateien..."
    echo ""
    
    local found_images=()
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            info "Durchsuche: $dir"
            while IFS= read -r -d '' file; do
                if [ -f "$file" ]; then
                    local size=$(du -h "$file" | cut -f1)
                    echo "  ✅ Gefunden: $(basename "$file") ($size)"
                    found_images+=("$file")
                fi
            done < <(find "$dir" -maxdepth 2 -type f \( -name "*.img" -o -name "*.zip" \) -print0 2>/dev/null)
        fi
    done
    
    # Raspberry Pi Imager Cache (macOS)
    local imager_cache="$HOME/Library/Caches/org.raspberrypi.Imager"
    if [ -d "$imager_cache" ]; then
        info "Durchsuche Raspberry Pi Imager Cache..."
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                local size=$(du -h "$file" | cut -f1)
                echo "  ✅ Gefunden: $(basename "$file") ($size)"
                found_images+=("$file")
            fi
        done < <(find "$imager_cache" -type f \( -name "*.img" -o -name "*.zip" \) -print0 2>/dev/null)
    fi
    
    echo ""
    
    if [ ${#found_images[@]} -eq 0 ]; then
        warn "Keine Image-Dateien gefunden"
        return 1
    fi
    
    # Return array (via global or echo)
    printf '%s\n' "${found_images[@]}"
}

find_latest_image() {
    local search_dirs=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Documents"
    )
    
    local latest_file=""
    local latest_time=0
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r file; do
                if [ -f "$file" ]; then
                    local file_time=$(stat -f "%m" "$file" 2>/dev/null || echo "0")
                    if [ "$file_time" -gt "$latest_time" ]; then
                        latest_time=$file_time
                        latest_file="$file"
                    fi
                fi
            done < <(find "$dir" -maxdepth 2 -type f \( -name "*.img" -o -name "*.zip" \) 2>/dev/null)
        fi
    done
    
    if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
        echo "$latest_file"
        return 0
    fi
    
    return 1
}

################################################################################
# SAVE FUNCTIONS
################################################################################

save_image() {
    local source_file="$1"
    local target_name="${2:-}"
    
    if [ ! -f "$source_file" ]; then
        error "Datei nicht gefunden: $source_file"
        return 1
    fi
    
    # Create deploy directory
    mkdir -p "$DEPLOY_DIR"
    
    # Determine target name
    if [ -z "$target_name" ]; then
        local basename_file=$(basename "$source_file")
        local extension="${basename_file##*.}"
        
        if [ "$extension" = "zip" ]; then
            # Extract zip first
            info "Entpacke ZIP-Archiv..."
            local temp_dir=$(mktemp -d)
            unzip -q "$source_file" -d "$temp_dir"
            
            # Find .img file in extracted content
            local img_file=$(find "$temp_dir" -name "*.img" -type f | head -1)
            if [ -n "$img_file" ] && [ -f "$img_file" ]; then
                basename_file=$(basename "$img_file")
                source_file="$img_file"
                info "Image gefunden in ZIP: $basename_file"
            else
                error "Kein .img in ZIP gefunden"
                rm -rf "$temp_dir"
                return 1
            fi
        fi
        
        # Generate name with timestamp
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local name_without_ext="${basename_file%.*}"
        target_name="${name_without_ext}-saved-${timestamp}.img"
    fi
    
    local target_file="$DEPLOY_DIR/$target_name"
    
    info "Kopiere Image..."
    info "  Von: $source_file"
    info "  Nach: $target_file"
    
    # Get size
    local source_size=$(du -h "$source_file" | cut -f1)
    info "  Größe: $source_size"
    
    # Copy with progress (if pv available) or regular cp
    if command -v pv >/dev/null 2>&1; then
        pv "$source_file" > "$target_file"
    else
        info "Kopiere (kann etwas dauern)..."
        cp "$source_file" "$target_file"
    fi
    
    if [ $? -eq 0 ] && [ -f "$target_file" ]; then
        local target_size=$(du -h "$target_file" | cut -f1)
        log "✅ Image gespeichert: $target_name ($target_size)"
        
        # Cleanup temp dir if used
        [ -n "$temp_dir" ] && rm -rf "$temp_dir" 2>/dev/null || true
        
        echo "$target_file"
        return 0
    else
        error "Kopieren fehlgeschlagen"
        [ -n "$temp_dir" ] && rm -rf "$temp_dir" 2>/dev/null || true
        return 1
    fi
}

read_from_sd_card() {
    local device="${1:-}"
    
    if [ -z "$device" ]; then
        warn "SD-Karten-Device nicht angegeben"
        info "Verfügbare Disks:"
        diskutil list | grep -E "^/dev/disk" | head -10
        echo ""
        read -p "SD-Karten-Device (z.B. /dev/disk2): " device
    fi
    
    if [ -z "$device" ] || [ ! -b "$device" ]; then
        error "Ungültiges Device: $device"
        return 1
    fi
    
    warn "⚠️  WICHTIG: Stelle sicher, dass $device die SD-Karte ist!"
    read -p "Fortfahren? (y/N): " confirm
    
    if [ "$confirm" != "y" ]; then
        info "Abgebrochen"
        return 1
    fi
    
    # Get disk size
    local disk_size=$(diskutil info "$device" | grep "Disk Size" | awk '{print $3, $4}')
    info "SD-Karte Größe: $disk_size"
    
    # Generate output name
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local output_file="$DEPLOY_DIR/sd-card-backup-${timestamp}.img"
    
    mkdir -p "$DEPLOY_DIR"
    
    info "Lese SD-Karte (kann sehr lange dauern)..."
    warn "⚠️  Bitte nicht unterbrechen!"
    
    # Use dd with progress if available
    if command -v pv >/dev/null 2>&1; then
        sudo dd if="$device" bs=1m 2>/dev/null | pv | dd of="$output_file" bs=1m 2>/dev/null
    else
        info "Lese (ohne Fortschrittsanzeige)..."
        sudo dd if="$device" of="$output_file" bs=1m status=progress 2>&1
    fi
    
    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        local file_size=$(du -h "$output_file" | cut -f1)
        log "✅ SD-Karte gelesen: $(basename "$output_file") ($file_size)"
        echo "$output_file"
        return 0
    else
        error "Lesen fehlgeschlagen"
        return 1
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  💾 SAVE IMAGE FROM RASPBERRY PI IMAGER                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    case "${1:-}" in
        search|find)
            search_image_files
            ;;
        latest)
            local latest=$(find_latest_image)
            if [ -n "$latest" ]; then
                log "Neuestes Image: $latest"
                echo "$latest"
            else
                error "Kein Image gefunden"
                return 1
            fi
            ;;
        save)
            shift
            local source="${1:-}"
            local target="${2:-}"
            
            if [ -z "$source" ]; then
                # Try to find latest
                source=$(find_latest_image)
                if [ -z "$source" ]; then
                    error "Kein Image gefunden. Bitte Pfad angeben."
                    echo "Usage: $0 save <source_file> [target_name]"
                    return 1
                fi
                info "Verwende neuestes Image: $source"
            fi
            
            save_image "$source" "$target"
            ;;
        from-sd|read-sd)
            read_from_sd_card "${2:-}"
            ;;
        *)
            echo "Save Image Tool"
            echo ""
            echo "Usage: $0 <command> [args...]"
            echo ""
            echo "Commands:"
            echo "  search       - Suche nach Image-Dateien"
            echo "  latest       - Finde neuestes Image"
            echo "  save [file]  - Speichere Image im Projekt"
            echo "  from-sd [device] - Lese Image von SD-Karte"
            echo ""
            echo "Examples:"
            echo "  $0 search                    # Suche nach Images"
            echo "  $0 latest                    # Finde neuestes"
            echo "  $0 save                      # Speichere neuestes"
            echo "  $0 save ~/Downloads/image.img  # Speichere bestimmtes"
            echo "  $0 from-sd /dev/disk2        # Lese von SD-Karte"
            echo ""
            echo "Quick save (neuestes Image):"
            local latest=$(find_latest_image 2>/dev/null)
            if [ -n "$latest" ]; then
                info "Neuestes Image gefunden: $latest"
                read -p "Speichern? (y/N): " confirm
                if [ "$confirm" = "y" ]; then
                    save_image "$latest"
                fi
            else
                warn "Kein Image gefunden. Suche..."
                search_image_files
            fi
            ;;
    esac
}

main "$@"

