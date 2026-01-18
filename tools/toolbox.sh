#!/bin/bash
################################################################################
#
# TOOLBOX LAUNCHER
# 
# Interactive menu launcher for all unified tools
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

clear_screen() {
    clear
}

show_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}🛠️  MOODE AUDIO CUSTOM BUILD - TOOLBOX${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}Main Menu:${NC}"
    echo ""
    echo "  1) 🔨 Build Tools"
    echo "  2) 🔧 Fix Tools"
    echo "  3) 🧪 Test Tools"
    echo "  4) 📡 Monitor Tools"
    echo "  5) 📦 Version Management"
    echo "  6) 📊 System Status"
    echo "  7) 🧹 Cleanup Tools"
    echo "  8) 📚 Documentation"
    echo "  9) 🤖 AI / RAG Tools"
    echo "  0) Exit"
    echo ""
    read -p "Select option: " choice
}

show_ai_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}AI / RAG Tools (GhettoAI):${NC}"
    echo ""
    echo "  1) Check KB status (needs refresh?)"
    echo "  2) Upload files to KB (requires token)"
    echo "  3) Generate RAG manifest"
    echo "  4) Verify AI setup (Ollama + Open WebUI)"
    echo "  5) Check Open WebUI availability"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice

    case $choice in
        1) "$SCRIPT_DIR/ai.sh" --status ;;
        2) 
            echo ""
            echo "Enter Open WebUI token (from browser console: localStorage.token):"
            read -r token
            if [ -n "$token" ]; then
                OPENWEBUI_TOKEN="$token" "$SCRIPT_DIR/ai.sh" --upload
            else
                echo -e "${RED}Token required${NC}"
            fi
            ;;
        3) "$SCRIPT_DIR/ai.sh" --manifest ;;
        4) "$SCRIPT_DIR/ai.sh" --verify ;;
        5) "$SCRIPT_DIR/ai.sh" --openwebui ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_build_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}Build Tools:${NC}"
    echo ""
    echo "  1) Build new image"
    echo "  2) Monitor build progress"
    echo "  3) Validate build image"
    echo "  4) Deploy image to SD card"
    echo "  5) Cleanup old images"
    echo "  6) Show build status"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/build.sh" --build ;;
        2) "$SCRIPT_DIR/build.sh" --monitor ;;
        3) "$SCRIPT_DIR/build.sh" --validate ;;
        4) "$SCRIPT_DIR/build.sh" --deploy ;;
        5) "$SCRIPT_DIR/build.sh" --cleanup ;;
        6) "$SCRIPT_DIR/build.sh" --status ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_fix_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}Fix Tools (GitHub-First Approach):${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ALWAYS check GitHub for working configs before fixing!${NC}"
    echo ""
    echo "  1) 🔍 Check GitHub for working configs"
    echo "  2) 📥 Restore from GitHub (v1.0 working config)"
    echo "  3) 🏷️  Tag current system as working"
    echo ""
    echo "  --- Fix Options (check GitHub first!) ---"
    echo "  4) Fix display issues"
    echo "  5) Fix touchscreen"
    echo "  6) Fix audio hardware"
    echo "  7) Fix network configuration"
    echo "  8) Fix SSH configuration"
    echo "  9) Fix AMP100 hardware"
    echo "  a) Fix all systems"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) 
            echo ""
            echo "Checking GitHub for working configurations..."
            git log --all --grep="working\|v1.0\|tested\|complete" --oneline | head -10
            echo ""
            echo "Working configs found in:"
            git log --all --grep="working\|v1.0" --format="%h %s" | head -5
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            echo "Restoring v1.0 working configuration from GitHub..."
            if [ -f "$PROJECT_ROOT/restore-v1.0-from-github.sh" ]; then
                bash "$PROJECT_ROOT/restore-v1.0-from-github.sh"
            else
                echo "Restore script not found. Checking GitHub commit 84aa8c2..."
                git show 84aa8c2 --stat | head -20
            fi
            read -p "Press Enter to continue..."
            ;;
        3)
            read -p "Tag name (e.g., v1.0-working): " tag_name
            if [ -n "$tag_name" ]; then
                git tag "$tag_name"
                echo "✅ Tagged as: $tag_name"
                read -p "Push to GitHub? (y/n): " push
                if [ "$push" = "y" ]; then
                    git push origin "$tag_name"
                    echo "✅ Pushed to GitHub"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        4) "$SCRIPT_DIR/fix.sh" --display ;;
        5) "$SCRIPT_DIR/fix.sh" --touchscreen ;;
        6) "$SCRIPT_DIR/fix.sh" --audio ;;
        7) "$SCRIPT_DIR/fix.sh" --network ;;
        8) "$SCRIPT_DIR/fix.sh" --ssh ;;
        9) "$SCRIPT_DIR/fix.sh" --amp100 ;;
        a) "$SCRIPT_DIR/fix.sh" --all ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_test_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}Test Tools:${NC}"
    echo ""
    echo "  1) Test display"
    echo "  2) Test touchscreen"
    echo "  3) Test audio system"
    echo "  4) Test PeppyMeter"
    echo "  5) Run complete test suite"
    echo "  6) Verify all systems"
    echo "  7) Docker system simulation"
    echo "  8) Test image in Docker"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/test.sh" --display ;;
        2) "$SCRIPT_DIR/test.sh" --touchscreen ;;
        3) "$SCRIPT_DIR/test.sh" --audio ;;
        4) "$SCRIPT_DIR/test.sh" --peppy ;;
        5) "$SCRIPT_DIR/test.sh" --all ;;
        6) "$SCRIPT_DIR/test.sh" --verify ;;
        7) "$SCRIPT_DIR/test.sh" --docker ;;
        8) "$SCRIPT_DIR/test.sh" --image ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_monitor_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}Monitor Tools:${NC}"
    echo ""
    echo "  1) Monitor build progress"
    echo "  2) Monitor Pi systems"
    echo "  3) Monitor serial console"
    echo "  4) Monitor all systems"
    echo "  5) Check system status"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/monitor.sh" --build ;;
        2) "$SCRIPT_DIR/monitor.sh" --pi ;;
        3) "$SCRIPT_DIR/monitor.sh" --serial ;;
        4) "$SCRIPT_DIR/monitor.sh" --all ;;
        5) "$SCRIPT_DIR/monitor.sh" --status ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_status() {
    clear_screen
    show_header
    echo -e "${GREEN}System Status:${NC}"
    echo ""
    
    # Build status
    echo -e "${BLUE}Build Status:${NC}"
    if [ -f "$PROJECT_ROOT/BUILD_COUNTER.txt" ]; then
        BUILD_NUM=$(cat "$PROJECT_ROOT/BUILD_COUNTER.txt")
        echo "  Build Number: $BUILD_NUM"
    fi
    
    LATEST_IMAGE=$(ls -t "$PROJECT_ROOT/imgbuild/deploy"/*.img 2>/dev/null | head -1)
    if [ -n "$LATEST_IMAGE" ]; then
        SIZE=$(du -h "$LATEST_IMAGE" | cut -f1)
        DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LATEST_IMAGE" 2>/dev/null || stat -c "%y" "$LATEST_IMAGE" 2>/dev/null | cut -d' ' -f1-2)
        echo "  Latest Image: $(basename "$LATEST_IMAGE")"
        echo "  Size: $SIZE"
        echo "  Date: $DATE"
    else
        echo "  No images found"
    fi
    
    echo ""
    echo -e "${BLUE}Docker Status:${NC}"
    if docker info >/dev/null 2>&1; then
        echo "  ✅ Running"
    else
        echo "  ❌ Not running"
    fi
    
    echo ""
    echo -e "${BLUE}Storage:${NC}"
    DEPLOY_SIZE=$(du -sh "$PROJECT_ROOT/imgbuild/deploy" 2>/dev/null | cut -f1)
    echo "  Deploy directory: $DEPLOY_SIZE"
    
    echo ""
    read -p "Press Enter to continue..."
}

show_cleanup_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}Cleanup Tools:${NC}"
    echo ""
    echo "  1) Cleanup old images"
    echo "  2) Cleanup intermediate files"
    echo "  3) Archive old documentation"
    echo "  4) Full storage cleanup"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/build.sh" --cleanup ;;
        2) 
            log "Cleaning up intermediate files..."
            find "$PROJECT_ROOT/imgbuild/deploy" -type f \( -name "*.info" -o -name "*.log" -o -name "*.zip" \) -mtime +7 -delete 2>/dev/null
            echo "✅ Cleaned up old intermediate files"
            read -p "Press Enter to continue..."
            ;;
        3)
            log "Archiving old documentation..."
            mkdir -p "$PROJECT_ROOT/archive/docs"
            find "$PROJECT_ROOT" -maxdepth 1 -name "BUILD_*.md" -type f -mtime +14 -exec mv {} "$PROJECT_ROOT/archive/docs/" \; 2>/dev/null
            echo "✅ Archived old documentation"
            read -p "Press Enter to continue..."
            ;;
        4)
            if [ -f "$PROJECT_ROOT/STORAGE_CLEANUP_SYSTEM.sh" ]; then
                bash "$PROJECT_ROOT/STORAGE_CLEANUP_SYSTEM.sh"
            else
                echo "Storage cleanup script not found"
            fi
            read -p "Press Enter to continue..."
            ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_version_menu() {
    clear_screen
    show_header
    echo -e "${GREEN}Version Management:${NC}"
    echo ""
    echo "  1) Build-Nummer erhöhen"
    echo "  2) Git Tag erstellen"
    echo "  3) Tags auflisten"
    echo "  4) Tag-Info anzeigen"
    echo "  5) Device-Branch wechseln"
    echo "  6) Geräte auflisten"
    echo "  7) GitHub Release erstellen"
    echo "  0) Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/version.sh" increment ;;
        2) 
            read -p "Gerät (pi4/pi5) [pi5]: " device
            read -p "Nachricht (optional): " message
            "$SCRIPT_DIR/version.sh" tag "${device:-pi5}" "$message"
            read -p "Press Enter to continue..."
            ;;
        3)
            read -p "Gerät filtern (optional): " device
            "$SCRIPT_DIR/version.sh" tags "$device"
            read -p "Press Enter to continue..."
            ;;
        4)
            read -p "Tag-Name: " tag
            "$SCRIPT_DIR/version.sh" info "$tag"
            read -p "Press Enter to continue..."
            ;;
        5)
            read -p "Gerät (pi4/pi5): " device
            "$SCRIPT_DIR/version.sh" device "$device"
            read -p "Press Enter to continue..."
            ;;
        6) 
            "$SCRIPT_DIR/version.sh" devices
            read -p "Press Enter to continue..."
            ;;
        7)
            read -p "Gerät (pi4/pi5) [pi5]: " device
            "$SCRIPT_DIR/version.sh" release "${device:-pi5}"
            read -p "Press Enter to continue..."
            ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

show_docs() {
    clear_screen
    show_header
    echo -e "${GREEN}Documentation:${NC}"
    echo ""
    echo "Available documentation:"
    echo ""
    
    if [ -f "$PROJECT_ROOT/tools/README.md" ]; then
        echo "  📚 tools/README.md - Toolbox documentation"
    fi
    
    if [ -f "$PROJECT_ROOT/COMPLETE_BOOT_PROCESS_ANALYSIS.md" ]; then
        echo "  📚 COMPLETE_BOOT_PROCESS_ANALYSIS.md - Boot process analysis"
    fi
    
    if [ -f "$PROJECT_ROOT/CUSTOM_BUILD_NEXT_STEPS.md" ]; then
        echo "  📚 CUSTOM_BUILD_NEXT_STEPS.md - Build next steps"
    fi
    
    if [ -f "$PROJECT_ROOT/TOOLS_INVENTORY.md" ]; then
        echo "  📚 TOOLS_INVENTORY.md - Complete tools inventory"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

main() {
    while true; do
        clear_screen
        show_header
        show_menu
        
        case $choice in
            1) show_build_menu ;;
            2) show_fix_menu ;;
            3) show_test_menu ;;
            4) show_monitor_menu ;;
            5) show_version_menu ;;
            6) show_status ;;
            7) show_cleanup_menu ;;
            8) show_docs ;;
            9) show_ai_menu ;;
            0) 
                echo ""
                echo "Goodbye!"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

main "$@"

