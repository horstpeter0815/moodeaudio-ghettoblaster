#!/bin/bash
################################################################################
#
# WISSENSBASIS HELPER
# 
# Automatische Updates und Zugriff auf die Wissensbasis
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WISSENSBASIS_DIR="$PROJECT_ROOT/WISSENSBASIS"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[WISSENSBASIS]${NC} $1"
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
# WISSENSBASIS PATHS
################################################################################

get_probleme_loesungen() {
    echo "$WISSENSBASIS_DIR/03_PROBLEME_LOESUNGEN.md"
}

get_tests_ergebnisse() {
    echo "$WISSENSBASIS_DIR/04_TESTS_ERGEBNISSE.md"
}

get_hardware() {
    echo "$WISSENSBASIS_DIR/02_HARDWARE.md"
}

get_best_practices() {
    echo "$WISSENSBASIS_DIR/06_BEST_PRACTICES.md"
}

get_troubleshooting() {
    echo "$WISSENSBASIS_DIR/08_TROUBLESHOOTING.md"
}

################################################################################
# SEARCH FUNCTIONS
################################################################################

search_problem() {
    local keyword="$1"
    local file=$(get_probleme_loesungen)
    
    if [ -f "$file" ]; then
        grep -i "$keyword" "$file" | head -10
    else
        error "WISSENSBASIS file not found: $file"
        return 1
    fi
}

search_solution() {
    local keyword="$1"
    local file=$(get_probleme_loesungen)
    
    if [ -f "$file" ]; then
        grep -A 20 -i "$keyword" "$file" | head -30
    else
        error "WISSENSBASIS file not found: $file"
        return 1
    fi
}

search_test() {
    local keyword="$1"
    local file=$(get_tests_ergebnisse)
    
    if [ -f "$file" ]; then
        grep -A 10 -i "$keyword" "$file" | head -20
    else
        error "WISSENSBASIS file not found: $file"
        return 1
    fi
}

################################################################################
# UPDATE FUNCTIONS
################################################################################

add_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    local file=$(get_tests_ergebnisse)
    
    if [ ! -f "$file" ]; then
        error "WISSENSBASIS file not found: $file"
        return 1
    fi
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local entry="
### **TEST: $test_name**

#### **Datum:** $timestamp
#### **Ergebnis:** $result
#### **Details:**
\`\`\`
$details
\`\`\`

---
"
    
    # Append to file
    echo "$entry" >> "$file"
    log "Test result added to WISSENSBASIS"
}

add_problem_solution() {
    local problem="$1"
    local solution="$2"
    local status="$3"
    local file=$(get_probleme_loesungen)
    
    if [ ! -f "$file" ]; then
        error "WISSENSBASIS file not found: $file"
        return 1
    fi
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local entry="
## PROBLEM: $problem

### **Datum:** $timestamp
### **Status:** $status

### **Lösung:**
$solution

---
"
    
    # Append to file
    echo "$entry" >> "$file"
    log "Problem/Solution added to WISSENSBASIS"
}

show_relevant_solutions() {
    local problem_type="$1"
    
    info "Relevante Lösungen für: $problem_type"
    echo ""
    
    case "$problem_type" in
        display|screen|rotation)
            search_solution "DISPLAY\|ROTATION\|SCREEN"
            ;;
        touchscreen|touch)
            search_solution "TOUCHSCREEN\|TOUCH\|FT6236\|WAVESHARE"
            ;;
        audio|sound|amp100)
            search_solution "AUDIO\|SOUND\|AMP100\|PCM5122"
            ;;
        network|ethernet|ssh)
            search_solution "NETWORK\|ETHERNET\|SSH"
            ;;
        boot|startup)
            search_solution "BOOT\|STARTUP\|REBOOT"
            ;;
        *)
            search_solution "$problem_type"
            ;;
    esac
}

################################################################################
# MAIN
################################################################################

case "${1:-}" in
    search)
        shift
        if [ -z "$1" ]; then
            error "Usage: $0 search <keyword>"
            exit 1
        fi
        search_problem "$1"
        ;;
    solution)
        shift
        if [ -z "$1" ]; then
            error "Usage: $0 solution <keyword>"
            exit 1
        fi
        show_relevant_solutions "$1"
        ;;
    add-test)
        shift
        if [ -z "$1" ] || [ -z "$2" ]; then
            error "Usage: $0 add-test <test_name> <result> [details]"
            exit 1
        fi
        add_test_result "$1" "$2" "${3:-}"
        ;;
    add-problem)
        shift
        if [ -z "$1" ] || [ -z "$2" ]; then
            error "Usage: $0 add-problem <problem> <solution> [status]"
            exit 1
        fi
        add_problem_solution "$1" "$2" "${3:-In Arbeit}"
        ;;
    *)
        echo "WISSENSBASIS Helper"
        echo ""
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  search <keyword>        - Search for problems/solutions"
        echo "  solution <type>         - Show relevant solutions (display|touchscreen|audio|network|boot)"
        echo "  add-test <name> <result> [details] - Add test result"
        echo "  add-problem <problem> <solution> [status] - Add problem/solution"
        echo ""
        echo "Files:"
        echo "  Probleme: $(get_probleme_loesungen)"
        echo "  Tests: $(get_tests_ergebnisse)"
        echo "  Hardware: $(get_hardware)"
        ;;
esac

