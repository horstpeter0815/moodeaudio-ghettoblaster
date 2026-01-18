#!/bin/bash
################################################################################
#
# GHETTO CREW COMPONENTS MANAGER
# 
# Verwaltet und dokumentiert alle Ghetto Crew System Komponenten für GitHub
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
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[GHETTO CREW]${NC} $1"
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
# COMPONENT DEFINITIONS
################################################################################

# Ghetto Crew Components (format: name|role|hardware|software|features|extra)
GHETTO_CREW_COMPONENTS=(
    "ghetto-blaster|Master|Raspberry Pi 5|moOde Audio|1280x400 Display|HiFiBerry AMP100"
    "ghetto-scratch|Slave|Raspberry Pi Zero 2W|HiFiBerry ADC Pro|Vinyl Player|Web Stream"
    "ghetto-boom|Slave|Bose 901L|HiFiBerry BeoCreate|3-Way System|Left Speaker"
    "ghetto-mob|Slave|Bose 901R|Custom Board|3-Way System|Right Speaker"
)

# Custom Components (format: name|description|path)
CUSTOM_COMPONENTS=(
    "services|Systemd Services|custom-components/services/"
    "scripts|Shell/Python Scripts|custom-components/scripts/"
    "overlays|Device Tree Overlays|custom-components/overlays/"
    "presets|Audio Presets|custom-components/presets/"
    "configs|Config Templates|custom-components/configs/"
)

################################################################################
# LIST FUNCTIONS
################################################################################

list_crew_components() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}🎵 GHETTO CREW SYSTEM COMPONENTS${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    for component_line in "${GHETTO_CREW_COMPONENTS[@]}"; do
        IFS='|' read -r name role hardware software features extra <<< "$component_line"
        echo -e "${GREEN}📦 $name${NC}"
        echo "   Rolle: $role"
        echo "   Hardware: $hardware"
        echo "   Software: $software"
        echo "   Features: $features"
        [ -n "$extra" ] && echo "   Extra: $extra"
        echo ""
    done
}

list_custom_components() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}🔧 CUSTOM COMPONENTS (Ghetto Blaster)${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    for component_line in "${CUSTOM_COMPONENTS[@]}"; do
        IFS='|' read -r name description path <<< "$component_line"
        local full_path="$PROJECT_ROOT/$path"
        
        echo -e "${GREEN}📁 $name${NC}"
        echo "   Beschreibung: $description"
        echo "   Pfad: $path"
        
        if [ -d "$full_path" ]; then
            local count=$(find "$full_path" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "   Dateien: $count"
            
            # Liste wichtige Dateien
            case "$name" in
                services)
                    echo "   Wichtig:"
                    find "$full_path" -name "*.service" -type f 2>/dev/null | head -5 | while read file; do
                        echo "     - $(basename "$file")"
                    done
                    ;;
                scripts)
                    echo "   Wichtig:"
                    find "$full_path" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | head -5 | while read file; do
                        echo "     - $(basename "$file")"
                    done
                    ;;
                overlays)
                    echo "   Wichtig:"
                    find "$full_path" -name "*.dts" -type f 2>/dev/null | while read file; do
                        echo "     - $(basename "$file")"
                    done
                    ;;
            esac
        else
            warn "   Verzeichnis nicht gefunden: $full_path"
        fi
        echo ""
    done
}

################################################################################
# GITHUB FUNCTIONS
################################################################################

generate_component_list() {
    local output_file="${1:-GHETTO_CREW_COMPONENTS.md}"
    
    log "Generiere Komponenten-Liste: $output_file"
    
    cat > "$output_file" << 'EOF'
# GHETTO CREW SYSTEM - COMPONENTS

**Datum:** $(date +"%Y-%m-%d %H:%M:%S")  
**System:** Ghetto Crew  
**Status:** ✅ Komponenten dokumentiert

---

## 🎵 GHETTO CREW SYSTEM

### **1. Ghetto Blaster** 🎵 (Master)
- **Rolle:** Zentrale / Leader
- **Hardware:** Raspberry Pi 5
- **Software:** moOde Audio (Ghetto OS)
- **Display:** 1280x400 + Touchscreen
- **Audio:** HiFiBerry AMP100

### **2. Ghetto Scratch** 🎧 (Slave)
- **Rolle:** Vinyl Player
- **Hardware:** Raspberry Pi Zero 2W
- **Audio:** HiFiBerry ADC Pro
- **Funktion:** Web-Stream zu Ghetto Blaster

### **3. Ghetto Boom** 🔊 (Slave)
- **Rolle:** Linker Lautsprecher
- **Hardware:** Bose 901L + HiFiBerry BeoCreate
- **Audio:** 3-Wege System (Bass, Mitten, Hochton)

### **4. Ghetto Mob** 🔊 (Slave)
- **Rolle:** Rechter Lautsprecher
- **Hardware:** Bose 901R + Custom Board
- **Audio:** 3-Wege System (Bass, Mitten, Hochton)

---

## 🔧 CUSTOM COMPONENTS (Ghetto Blaster)

EOF

    # Services
    if [ -d "custom-components/services" ]; then
        echo "### **Services** (Systemd)" >> "$output_file"
        find custom-components/services -name "*.service" -type f 2>/dev/null | sort | while read file; do
            echo "- \`$(basename "$file")\`" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
    
    # Scripts
    if [ -d "custom-components/scripts" ]; then
        echo "### **Scripts**" >> "$output_file"
        find custom-components/scripts -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort | while read file; do
            echo "- \`$(basename "$file")\`" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
    
    # Overlays
    if [ -d "custom-components/overlays" ]; then
        echo "### **Device Tree Overlays**" >> "$output_file"
        find custom-components/overlays -name "*.dts" -type f 2>/dev/null | sort | while read file; do
            echo "- \`$(basename "$file")\`" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
    
    # Presets
    if [ -d "custom-components/presets" ]; then
        echo "### **Audio Presets**" >> "$output_file"
        find custom-components/presets -name "*.json" -type f 2>/dev/null | sort | while read file; do
            echo "- \`$(basename "$file")\`" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
    
    log "✅ Komponenten-Liste generiert: $output_file"
}

create_github_release_notes() {
    local device="${1:-ghetto-blaster}"
    local version="${2:-}"
    local output_file="${3:-GHETTO_CREW_RELEASE_NOTES.md}"
    
    if [ -z "$version" ]; then
        if [ -f "tools/version.sh" ]; then
            version=$(./tools/version.sh get_version_string "$device" 2>/dev/null || echo "v1.0.0")
        else
            version="v1.0.0"
        fi
    fi
    
    log "Generiere GitHub Release Notes: $output_file"
    
    cat > "$output_file" << EOF
# GHETTO CREW SYSTEM - Release Notes

**Version:** $version  
**Device:** $device  
**Datum:** $(date +"%Y-%m-%d %H:%M:%S")

---

## 🎵 Ghetto Crew System

Dieses Release enthält alle Komponenten für das **Ghetto Crew** HiFi-System.

### **System-Komponenten:**
- ✅ **Ghetto Blaster** (Master) - Raspberry Pi 5 mit moOde Audio
- ✅ **Ghetto Scratch** (Slave) - Vinyl Player
- ✅ **Ghetto Boom** (Slave) - Linker Lautsprecher
- ✅ **Ghetto Mob** (Slave) - Rechter Lautsprecher

---

## 🔧 Custom Components

### **Services** ($(find custom-components/services -name "*.service" 2>/dev/null | wc -l | tr -d ' ') Services)
$(find custom-components/services -name "*.service" 2>/dev/null | sort | while read file; do echo "- \`$(basename "$file")\`"; done)

### **Scripts** ($(find custom-components/scripts -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | wc -l | tr -d ' ') Scripts)
$(find custom-components/scripts -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort | while read file; do echo "- \`$(basename "$file")\`"; done)

### **Device Tree Overlays** ($(find custom-components/overlays -name "*.dts" 2>/dev/null | wc -l | tr -d ' ') Overlays)
$(find custom-components/overlays -name "*.dts" 2>/dev/null | sort | while read file; do echo "- \`$(basename "$file")\`"; done)

### **Audio Presets** ($(find custom-components/presets -name "*.json" 2>/dev/null | wc -l | tr -d ' ') Presets)
$(find custom-components/presets -name "*.json" 2>/dev/null | sort | while read file; do echo "- \`$(basename "$file")\`"; done)

---

## 📦 Installation

Siehe \`INTEGRATE_CUSTOM_COMPONENTS.sh\` für die Integration aller Komponenten.

---

**Ghetto Crew - Das komplette HiFi-System!** 🎵
EOF

    log "✅ Release Notes generiert: $output_file"
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}🎵 GHETTO CREW COMPONENTS MANAGER${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "1) Crew-Komponenten auflisten"
    echo "2) Custom-Komponenten auflisten"
    echo "3) Komponenten-Liste generieren (Markdown)"
    echo "4) GitHub Release Notes generieren"
    echo "5) Alles anzeigen"
    echo "0) Exit"
    echo ""
    read -p "Select option: " choice
}

main() {
    case "${1:-}" in
        crew|list-crew)
            list_crew_components
            ;;
        custom|list-custom)
            list_custom_components
            ;;
        generate|gen)
            generate_component_list "${2:-GHETTO_CREW_COMPONENTS.md}"
            ;;
        release-notes|notes)
            create_github_release_notes "${2:-ghetto-blaster}" "${3:-}" "${4:-GHETTO_CREW_RELEASE_NOTES.md}"
            ;;
        all|show-all)
            list_crew_components
            list_custom_components
            ;;
        *)
            # Interactive mode
            while true; do
                show_menu
                case $choice in
                    1) list_crew_components ;;
                    2) list_custom_components ;;
                    3) 
                        read -p "Output-Datei [GHETTO_CREW_COMPONENTS.md]: " output
                        generate_component_list "${output:-GHETTO_CREW_COMPONENTS.md}"
                        ;;
                    4)
                        read -p "Device [ghetto-blaster]: " device
                        read -p "Version (optional): " version
                        read -p "Output-Datei [GHETTO_CREW_RELEASE_NOTES.md]: " output
                        create_github_release_notes "${device:-ghetto-blaster}" "$version" "${output:-GHETTO_CREW_RELEASE_NOTES.md}"
                        ;;
                    5) 
                        list_crew_components
                        list_custom_components
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

