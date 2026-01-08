#!/bin/bash

################################################################################
# MOODE AUDIO - COMPREHENSIVE AUDIO/VIDEO TEST SUITE
# Mit grafischer Fortschrittsanzeige und Ergebnis-Visualisierung
################################################################################

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Test-Ergebnisse
declare -A TEST_RESULTS
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Log-Datei
LOG_FILE="/tmp/audio_video_test_$(date +%Y%m%d_%H%M%S).log"

################################################################################
# HILFSFUNKTIONEN
################################################################################

# Fortschrittsbalken zeichnen
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "]${NC} ${WHITE}%3d%%${NC} ${GRAY}(%d/%d)${NC}" $percentage $current $total
}

# Spinner während Test läuft
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Box für Header zeichnen
draw_box() {
    local text="$1"
    local width=${#text}
    local line=$(printf '═%.0s' $(seq 1 $((width + 4))))
    
    echo -e "${CYAN}╔${line}╗${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}${text}${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}╚${line}╝${NC}"
}

# Test-Ergebnis ausgeben
test_result() {
    local test_name="$1"
    local status="$2"  # PASS, FAIL, WARN
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    TEST_RESULTS["$test_name"]="$status|$message"
    
    case $status in
        PASS)
            echo -e "${GREEN}✓${NC} ${test_name}: ${GREEN}PASSED${NC} - $message" | tee -a "$LOG_FILE"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        FAIL)
            echo -e "${RED}✗${NC} ${test_name}: ${RED}FAILED${NC} - $message" | tee -a "$LOG_FILE"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            ;;
        WARN)
            echo -e "${YELLOW}⚠${NC} ${test_name}: ${YELLOW}WARNING${NC} - $message" | tee -a "$LOG_FILE"
            WARNING_TESTS=$((WARNING_TESTS + 1))
            ;;
    esac
}

# Separator
separator() {
    echo -e "${GRAY}$(printf '─%.0s' $(seq 1 80))${NC}"
}

################################################################################
# AUDIO TESTS
################################################################################

test_audio_devices() {
    echo -e "\n${BLUE}●${NC} Testing Audio Devices..."
    
    # Test 1: ALSA Devices
    if aplay -l > /dev/null 2>&1; then
        local device_count=$(aplay -l | grep -c "^card")
        test_result "ALSA Devices" "PASS" "$device_count audio device(s) detected"
        aplay -l | tee -a "$LOG_FILE"
    else
        test_result "ALSA Devices" "FAIL" "No ALSA devices found"
    fi
    
    # Test 2: HiFiBerry AMP100
    if aplay -l | grep -qi "hifiberry"; then
        test_result "HiFiBerry AMP100" "PASS" "HiFiBerry device detected"
    else
        test_result "HiFiBerry AMP100" "FAIL" "HiFiBerry device not found"
    fi
    
    # Test 3: PCM512x Codec
    if lsmod | grep -q "snd_soc_pcm512x"; then
        test_result "PCM512x Codec" "PASS" "PCM512x module loaded"
    else
        test_result "PCM512x Codec" "WARN" "PCM512x module not loaded"
    fi
}

test_audio_playback() {
    echo -e "\n${BLUE}●${NC} Testing Audio Playback..."
    
    # Test 1: Generate test tone (1 second, 440Hz)
    local test_wav="/tmp/test_tone_440hz.wav"
    
    echo -e "${GRAY}  Generating 440Hz test tone...${NC}"
    if command -v sox > /dev/null 2>&1; then
        sox -n -r 48000 -c 2 "$test_wav" synth 1 sine 440 > /dev/null 2>&1
        test_result "Test Tone Generation" "PASS" "440Hz tone generated"
    else
        # Fallback: ffmpeg
        if command -v ffmpeg > /dev/null 2>&1; then
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 48000 -ac 2 "$test_wav" -y > /dev/null 2>&1
            test_result "Test Tone Generation" "PASS" "440Hz tone generated (ffmpeg)"
        else
            test_result "Test Tone Generation" "WARN" "sox/ffmpeg not available, skipping playback test"
            return
        fi
    fi
    
    # Test 2: Play test tone
    echo -e "${GRAY}  Playing test tone...${NC}"
    if aplay -D default "$test_wav" > /dev/null 2>&1; then
        test_result "Audio Playback" "PASS" "Test tone played successfully"
    else
        test_result "Audio Playback" "FAIL" "Failed to play test tone"
    fi
    
    rm -f "$test_wav"
}

test_audio_mixer() {
    echo -e "\n${BLUE}●${NC} Testing Audio Mixer..."
    
    # Test 1: ALSA Mixer
    if amixer > /dev/null 2>&1; then
        local mixer_count=$(amixer scontrols | wc -l)
        test_result "ALSA Mixer" "PASS" "$mixer_count mixer control(s) available"
        amixer scontrols | tee -a "$LOG_FILE"
    else
        test_result "ALSA Mixer" "FAIL" "ALSA mixer not accessible"
    fi
    
    # Test 2: Volume Control
    if amixer get Master > /dev/null 2>&1; then
        local volume=$(amixer get Master | grep -oP '\d+%' | head -1)
        test_result "Volume Control" "PASS" "Master volume: $volume"
    elif amixer get Digital > /dev/null 2>&1; then
        local volume=$(amixer get Digital | grep -oP '\d+%' | head -1)
        test_result "Volume Control" "PASS" "Digital volume: $volume"
    else
        test_result "Volume Control" "WARN" "No Master/Digital volume control found"
    fi
}

test_audio_mpd() {
    echo -e "\n${BLUE}●${NC} Testing MPD (Music Player Daemon)..."
    
    # Test 1: MPD Running
    if systemctl is-active --quiet mpd; then
        test_result "MPD Service" "PASS" "MPD is running"
    else
        test_result "MPD Service" "FAIL" "MPD is not running"
        return
    fi
    
    # Test 2: MPD Status
    if command -v mpc > /dev/null 2>&1; then
        local mpd_status=$(mpc status 2>&1)
        if [[ $? -eq 0 ]]; then
            test_result "MPD Connection" "PASS" "MPD is accessible"
            echo -e "${GRAY}$mpd_status${NC}" | tee -a "$LOG_FILE"
        else
            test_result "MPD Connection" "FAIL" "Cannot connect to MPD"
        fi
    else
        test_result "MPD Client" "WARN" "mpc not installed, skipping MPD tests"
    fi
    
    # Test 3: MPD Output
    if command -v mpc > /dev/null 2>&1; then
        local outputs=$(mpc outputs | grep -c "enabled")
        if [[ $outputs -gt 0 ]]; then
            test_result "MPD Outputs" "PASS" "$outputs output(s) enabled"
            mpc outputs | tee -a "$LOG_FILE"
        else
            test_result "MPD Outputs" "WARN" "No MPD outputs enabled"
        fi
    fi
}

################################################################################
# VIDEO TESTS
################################################################################

test_video_framebuffer() {
    echo -e "\n${BLUE}●${NC} Testing Framebuffer..."
    
    # Test 1: Framebuffer Device
    if [[ -e /dev/fb0 ]]; then
        test_result "Framebuffer Device" "PASS" "/dev/fb0 exists"
    else
        test_result "Framebuffer Device" "FAIL" "/dev/fb0 not found"
        return
    fi
    
    # Test 2: Framebuffer Resolution
    if [[ -f /sys/class/graphics/fb0/virtual_size ]]; then
        local fb_size=$(cat /sys/class/graphics/fb0/virtual_size)
        local fb_bits=$(cat /sys/class/graphics/fb0/bits_per_pixel)
        test_result "Framebuffer Resolution" "PASS" "${fb_size} @ ${fb_bits}bpp"
    else
        test_result "Framebuffer Resolution" "FAIL" "Cannot read framebuffer info"
    fi
    
    # Test 3: Framebuffer Test Pattern
    echo -e "${GRAY}  Drawing test pattern to framebuffer...${NC}"
    if command -v fbi > /dev/null 2>&1; then
        # Generate test pattern
        local test_img="/tmp/test_pattern.png"
        if command -v convert > /dev/null 2>&1; then
            convert -size 800x480 plasma:fractal "$test_img" 2>/dev/null
            fbi -T 1 -d /dev/fb0 -noverbose "$test_img" 2>/dev/null &
            local fbi_pid=$!
            sleep 2
            kill $fbi_pid 2>/dev/null
            test_result "Framebuffer Test Pattern" "PASS" "Test pattern displayed"
            rm -f "$test_img"
        else
            test_result "Framebuffer Test Pattern" "WARN" "ImageMagick not available"
        fi
    else
        test_result "Framebuffer Test Pattern" "WARN" "fbi not installed, skipping visual test"
    fi
}

test_video_drm() {
    echo -e "\n${BLUE}●${NC} Testing DRM/KMS..."
    
    # Test 1: DRM Devices
    if ls /dev/dri/card* > /dev/null 2>&1; then
        local card_count=$(ls /dev/dri/card* | wc -l)
        test_result "DRM Devices" "PASS" "$card_count DRM card(s) found"
    else
        test_result "DRM Devices" "FAIL" "No DRM devices found"
        return
    fi
    
    # Test 2: VC4 Driver
    if lsmod | grep -q "^vc4"; then
        test_result "VC4 Driver" "PASS" "VC4 DRM driver loaded"
    else
        test_result "VC4 Driver" "FAIL" "VC4 driver not loaded"
    fi
    
    # Test 3: DRM Connectors
    local connectors=""
    for card in /sys/class/drm/card*; do
        if [[ -d "$card" ]]; then
            for connector in "$card"/card*-*; do
                if [[ -f "$connector/status" ]]; then
                    local conn_name=$(basename "$connector")
                    local conn_status=$(cat "$connector/status")
                    connectors="${connectors}\n    ${conn_name}: ${conn_status}"
                fi
            done
        fi
    done
    
    if [[ -n "$connectors" ]]; then
        test_result "DRM Connectors" "PASS" "DRM connectors detected"
        echo -e "${GRAY}${connectors}${NC}" | tee -a "$LOG_FILE"
    else
        test_result "DRM Connectors" "WARN" "No DRM connectors found"
    fi
}

test_video_dsi() {
    echo -e "\n${BLUE}●${NC} Testing DSI Display..."
    
    # Test 1: DSI-1 Device
    if [[ -d /sys/class/drm/card1-DSI-1 ]] || [[ -d /sys/class/drm/card0-DSI-1 ]]; then
        test_result "DSI-1 Device" "PASS" "DSI-1 device exists"
        
        # Test Status
        for dsi in /sys/class/drm/card*-DSI-1; do
            if [[ -f "$dsi/status" ]]; then
                local status=$(cat "$dsi/status")
                local enabled=$(cat "$dsi/enabled" 2>/dev/null || echo "unknown")
                test_result "DSI-1 Status" "PASS" "Status: $status, Enabled: $enabled"
            fi
        done
        
        # Test Modes
        for dsi in /sys/class/drm/card*-DSI-1; do
            if [[ -f "$dsi/modes" ]]; then
                local modes=$(cat "$dsi/modes")
                if [[ -n "$modes" ]]; then
                    test_result "DSI-1 Modes" "PASS" "Modes: $modes"
                else
                    test_result "DSI-1 Modes" "WARN" "No modes available"
                fi
            fi
        done
    else
        test_result "DSI-1 Device" "FAIL" "DSI-1 device not found"
    fi
    
    # Test 2: Waveshare Panel Driver
    if lsmod | grep -q "panel_waveshare"; then
        test_result "Waveshare Panel Driver" "PASS" "panel_waveshare_dsi module loaded"
    else
        test_result "Waveshare Panel Driver" "WARN" "panel_waveshare_dsi module not loaded"
    fi
    
    # Test 3: I2C Panel Communication
    if command -v i2cdetect > /dev/null 2>&1; then
        local i2c_result=$(i2cdetect -y 10 2>/dev/null | grep "45: ")
        if [[ $i2c_result =~ "45" ]] || [[ $i2c_result =~ "UU" ]]; then
            test_result "DSI I2C Communication" "PASS" "Panel detected on I2C Bus 10 @ 0x45"
        else
            test_result "DSI I2C Communication" "FAIL" "No panel detected on I2C Bus 10"
        fi
    else
        test_result "DSI I2C Communication" "WARN" "i2c-tools not installed"
    fi
}

test_video_hdmi() {
    echo -e "\n${BLUE}●${NC} Testing HDMI Output..."
    
    # Test HDMI Connectors
    local hdmi_found=false
    for hdmi in /sys/class/drm/card*-HDMI-*; do
        if [[ -f "$hdmi/status" ]]; then
            hdmi_found=true
            local hdmi_name=$(basename "$hdmi")
            local status=$(cat "$hdmi/status")
            
            if [[ "$status" == "connected" ]]; then
                test_result "HDMI $hdmi_name" "PASS" "Connected"
                
                # Get EDID info
                if [[ -f "$hdmi/edid" ]]; then
                    test_result "HDMI EDID" "PASS" "EDID data available"
                fi
                
                # Get modes
                if [[ -f "$hdmi/modes" ]]; then
                    local mode=$(cat "$hdmi/modes" | head -1)
                    test_result "HDMI Mode" "PASS" "Mode: $mode"
                fi
            else
                test_result "HDMI $hdmi_name" "WARN" "Not connected"
            fi
        fi
    done
    
    if [[ "$hdmi_found" == false ]]; then
        test_result "HDMI" "WARN" "No HDMI connectors found"
    fi
}

################################################################################
# SYSTEM TESTS
################################################################################

test_system_info() {
    echo -e "\n${BLUE}●${NC} System Information..."
    
    # OS Info
    if [[ -f /etc/os-release ]]; then
        local os_name=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
        test_result "Operating System" "PASS" "$os_name"
    fi
    
    # Kernel
    local kernel=$(uname -r)
    test_result "Kernel Version" "PASS" "$kernel"
    
    # Hardware
    local hardware=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
    test_result "Hardware" "PASS" "$hardware"
    
    # CPU Temperature
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        if [[ $temp -lt 70 ]]; then
            test_result "CPU Temperature" "PASS" "${temp}°C"
        elif [[ $temp -lt 80 ]]; then
            test_result "CPU Temperature" "WARN" "${temp}°C (warm)"
        else
            test_result "CPU Temperature" "FAIL" "${temp}°C (too hot!)"
        fi
    fi
    
    # Memory
    local mem_total=$(free -h | grep "^Mem:" | awk '{print $2}')
    local mem_used=$(free -h | grep "^Mem:" | awk '{print $3}')
    test_result "Memory" "PASS" "$mem_used / $mem_total used"
}

################################################################################
# ERGEBNIS-VISUALISIERUNG
################################################################################

visualize_results() {
    clear
    echo ""
    draw_box "TEST RESULTS SUMMARY"
    echo ""
    
    # Gesamt-Statistik
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    
    echo -e "${WHITE}Total Tests:${NC}     $TOTAL_TESTS"
    echo -e "${GREEN}Passed:${NC}          $PASSED_TESTS"
    echo -e "${RED}Failed:${NC}          $FAILED_TESTS"
    echo -e "${YELLOW}Warnings:${NC}        $WARNING_TESTS"
    echo -e "${WHITE}Success Rate:${NC}    ${success_rate}%"
    echo ""
    
    # Balkendiagramm
    local bar_width=50
    local passed_bar=$((bar_width * PASSED_TESTS / TOTAL_TESTS))
    local failed_bar=$((bar_width * FAILED_TESTS / TOTAL_TESTS))
    local warn_bar=$((bar_width * WARNING_TESTS / TOTAL_TESTS))
    
    echo -e "${WHITE}Distribution:${NC}"
    printf "${GREEN}█%.0s${NC}" $(seq 1 $passed_bar)
    printf "${RED}█%.0s${NC}" $(seq 1 $failed_bar)
    printf "${YELLOW}█%.0s${NC}" $(seq 1 $warn_bar)
    echo ""
    echo ""
    
    # ASCII Art basierend auf Ergebnis
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}"
        cat << "EOF"
    ██████╗  █████╗ ███████╗███████╗
    ██╔══██╗██╔══██╗██╔════╝██╔════╝
    ██████╔╝███████║███████╗███████╗
    ██╔═══╝ ██╔══██║╚════██║╚════██║
    ██║     ██║  ██║███████║███████║
    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
EOF
        echo -e "${NC}"
    elif [[ $success_rate -ge 70 ]]; then
        echo -e "${YELLOW}"
        cat << "EOF"
    ██████╗  █████╗ ██████╗ ████████╗██╗ █████╗ ██╗     
    ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗██║     
    ██████╔╝███████║██████╔╝   ██║   ██║███████║██║     
    ██╔═══╝ ██╔══██║██╔══██╗   ██║   ██║██╔══██║██║     
    ██║     ██║  ██║██║  ██║   ██║   ██║██║  ██║███████╗
    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝
EOF
        echo -e "${NC}"
    else
        echo -e "${RED}"
        cat << "EOF"
    ███████╗ █████╗ ██╗██╗     
    ██╔════╝██╔══██╗██║██║     
    █████╗  ███████║██║██║     
    ██╔══╝  ██╔══██║██║██║     
    ██║     ██║  ██║██║███████╗
    ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝
EOF
        echo -e "${NC}"
    fi
    
    echo ""
    separator
    echo ""
    
    # Detaillierte Kategorie-Übersicht
    echo -e "${WHITE}Results by Category:${NC}"
    echo ""
    
    print_category_results "Audio" "ALSA|HiFiBerry|PCM512x|Playback|Mixer|Volume|MPD"
    print_category_results "Video" "Framebuffer|DRM|VC4|Connector|DSI|HDMI|Panel"
    print_category_results "System" "Operating|Kernel|Hardware|Temperature|Memory"
    
    echo ""
    separator
    echo ""
    echo -e "${GRAY}Full log saved to: ${LOG_FILE}${NC}"
    echo ""
}

print_category_results() {
    local category="$1"
    local filter="$2"
    local cat_pass=0
    local cat_fail=0
    local cat_warn=0
    
    for test_name in "${!TEST_RESULTS[@]}"; do
        if echo "$test_name" | grep -qE "$filter"; then
            local result="${TEST_RESULTS[$test_name]}"
            local status="${result%%|*}"
            case $status in
                PASS) cat_pass=$((cat_pass + 1)) ;;
                FAIL) cat_fail=$((cat_fail + 1)) ;;
                WARN) cat_warn=$((cat_warn + 1)) ;;
            esac
        fi
    done
    
    local total=$((cat_pass + cat_fail + cat_warn))
    if [[ $total -gt 0 ]]; then
        echo -e "${CYAN}${category}:${NC}"
        echo -e "  ${GREEN}✓ $cat_pass${NC}  ${RED}✗ $cat_fail${NC}  ${YELLOW}⚠ $cat_warn${NC}"
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    clear
    
    # Header
    draw_box "MOODE AUDIO - AUDIO/VIDEO TEST SUITE"
    echo ""
    echo -e "${GRAY}Raspberry Pi 4 - Comprehensive System Test${NC}"
    echo -e "${GRAY}Started: $(date)${NC}"
    echo ""
    separator
    
    # Test-Kategorien
    local categories=(
        "System Information"
        "Audio Devices"
        "Audio Playback"
        "Audio Mixer"
        "MPD"
        "Framebuffer"
        "DRM/KMS"
        "DSI Display"
        "HDMI Output"
    )
    
    local total_categories=${#categories[@]}
    local current=0
    
    # Fortschrittsanzeige
    echo ""
    echo -e "${WHITE}Running Tests...${NC}"
    echo ""
    
    # Tests ausführen mit Fortschrittsbalken
    for category in "${categories[@]}"; do
        current=$((current + 1))
        progress_bar $current $total_categories
        
        case $category in
            "System Information")
                test_system_info >> "$LOG_FILE" 2>&1
                ;;
            "Audio Devices")
                test_audio_devices >> "$LOG_FILE" 2>&1
                ;;
            "Audio Playback")
                test_audio_playback >> "$LOG_FILE" 2>&1
                ;;
            "Audio Mixer")
                test_audio_mixer >> "$LOG_FILE" 2>&1
                ;;
            "MPD")
                test_audio_mpd >> "$LOG_FILE" 2>&1
                ;;
            "Framebuffer")
                test_video_framebuffer >> "$LOG_FILE" 2>&1
                ;;
            "DRM/KMS")
                test_video_drm >> "$LOG_FILE" 2>&1
                ;;
            "DSI Display")
                test_video_dsi >> "$LOG_FILE" 2>&1
                ;;
            "HDMI Output")
                test_video_hdmi >> "$LOG_FILE" 2>&1
                ;;
        esac
        
        sleep 0.5  # Kurze Pause für visuelle Wirkung
    done
    
    echo ""
    echo ""
    
    # Detaillierte Ergebnisse
    echo ""
    separator
    echo -e "${WHITE}Detailed Test Results:${NC}"
    separator
    
    test_system_info
    test_audio_devices
    test_audio_playback
    test_audio_mixer
    test_audio_mpd
    test_video_framebuffer
    test_video_drm
    test_video_dsi
    test_video_hdmi
    
    # Ergebnis-Visualisierung
    sleep 2
    visualize_results
}

# Script ausführen
main "$@"

