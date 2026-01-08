#!/bin/bash
# Fix and open web UIs on all three systems - continuous work until done

set -e

echo "=========================================="
echo "FIXING AND OPENING ALL SYSTEMS"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to fix and open system
fix_and_open_system() {
    local system_num=$1
    local ssh_cmd=$2
    local name=$3
    
    echo "=========================================="
    echo "SYSTEM $system_num: $name"
    echo "=========================================="
    
    # Check if online
    if ! $ssh_cmd "hostname" >/dev/null 2>&1; then
        echo -e "${RED}❌ System offline${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ System online${NC}"
    
    # Prevent sleep
    echo "Preventing sleep..."
    $ssh_cmd "sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null; sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null" || true
    
    # System-specific fixes
    if [ "$system_num" == "1" ]; then
        # HiFiBerryOS Pi 4
        echo "Starting display services..."
        $ssh_cmd "systemctl start weston 2>/dev/null; systemctl start cog 2>/dev/null; systemctl start audio-visualizer 2>/dev/null" || true
        sleep 2
        
        echo "Opening web UI..."
        $ssh_cmd "export DISPLAY=:0; pkill cog 2>/dev/null; sleep 1; nohup cog http://localhost:8080 >/dev/null 2>&1 & || nohup cog http://localhost >/dev/null 2>&1 &" || true
        sleep 2
        
        # Verify
        PROCESSES=$($ssh_cmd "ps aux | grep -E 'cog|weston' | grep -v grep | wc -l" 2>/dev/null || echo "0")
        if [ "$PROCESSES" -gt "0" ]; then
            echo -e "${GREEN}✅ Display processes running: $PROCESSES${NC}"
        else
            echo -e "${YELLOW}⚠️  Display processes: $PROCESSES${NC}"
        fi
        
    elif [ "$system_num" == "2" ]; then
        # moOde Pi 5
        echo "Ensuring services are active..."
        $ssh_cmd "sudo systemctl start mpd localdisplay 2>/dev/null" || true
        sleep 2
        
        echo "Checking display..."
        DISPLAY_STATUS=$($ssh_cmd "export DISPLAY=:0; xrandr --listmonitors 2>/dev/null | head -1" || echo "")
        if [ -n "$DISPLAY_STATUS" ]; then
            echo -e "${GREEN}✅ Display active${NC}"
        else
            echo -e "${YELLOW}⚠️  Display check failed${NC}"
        fi
        
        echo "Opening moOde web UI..."
        $ssh_cmd "export DISPLAY=:0; pkill chromium 2>/dev/null; sleep 2; nohup chromium-browser --kiosk --disable-infobars --disable-session-crashed-bubble --disable-restore-session-state --noerrdialogs http://localhost >/dev/null 2>&1 &" || true
        sleep 3
        
        # Verify
        CHROMIUM=$($ssh_cmd "ps aux | grep chromium | grep -v grep | wc -l" 2>/dev/null || echo "0")
        if [ "$CHROMIUM" -gt "0" ]; then
            echo -e "${GREEN}✅ Chromium running: $CHROMIUM processes${NC}"
        else
            echo -e "${YELLOW}⚠️  Chromium: $CHROMIUM processes${NC}"
            # Try again
            echo "Retrying Chromium..."
            $ssh_cmd "export DISPLAY=:0; chromium-browser --kiosk http://localhost >/dev/null 2>&1 &" || true
            sleep 2
        fi
        
    elif [ "$system_num" == "3" ]; then
        # moOde Pi 4
        echo "Starting localdisplay service..."
        $ssh_cmd "sudo systemctl start localdisplay 2>/dev/null" || true
        sleep 3
        
        # Check if X is running
        X_RUNNING=$($ssh_cmd "export DISPLAY=:0; xrandr --listmonitors 2>/dev/null | head -1" || echo "")
        if [ -z "$X_RUNNING" ]; then
            echo "X not running, waiting and retrying..."
            sleep 3
            $ssh_cmd "sudo systemctl restart localdisplay 2>/dev/null" || true
            sleep 5
        fi
        
        echo "Opening moOde web UI..."
        $ssh_cmd "export DISPLAY=:0; pkill chromium 2>/dev/null; sleep 2; nohup chromium-browser --kiosk --disable-infobars --disable-session-crashed-bubble --disable-restore-session-state --noerrdialogs http://localhost >/dev/null 2>&1 &" || true
        sleep 3
        
        # Verify
        CHROMIUM=$($ssh_cmd "ps aux | grep chromium | grep -v grep | wc -l" 2>/dev/null || echo "0")
        LOCALDISPLAY=$($ssh_cmd "systemctl is-active localdisplay 2>/dev/null || echo inactive")
        
        if [ "$CHROMIUM" -gt "0" ] && [ "$LOCALDISPLAY" == "active" ]; then
            echo -e "${GREEN}✅ Chromium running: $CHROMIUM processes${NC}"
            echo -e "${GREEN}✅ Localdisplay: $LOCALDISPLAY${NC}"
        else
            echo -e "${YELLOW}⚠️  Chromium: $CHROMIUM, Localdisplay: $LOCALDISPLAY${NC}"
            # Retry
            echo "Retrying..."
            $ssh_cmd "sudo systemctl restart localdisplay && sleep 4 && export DISPLAY=:0 && chromium-browser --kiosk http://localhost >/dev/null 2>&1 &" || true
            sleep 3
        fi
    fi
    
    echo ""
    return 0
}

# System 1: HiFiBerryOS Pi 4
echo "Working on System 1..."
if ping -c 1 -W 2000 192.168.178.199 >/dev/null 2>&1; then
    fix_and_open_system 1 "ssh pi1" "HiFiBerryOS Pi 4"
else
    echo -e "${RED}❌ System 1 offline (needs charging cable)${NC}"
    echo ""
fi

# System 2: moOde Pi 5
echo "Working on System 2..."
if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
    fix_and_open_system 2 "ssh pi2" "moOde Pi 5"
else
    echo -e "${RED}❌ System 2 offline${NC}"
    echo ""
fi

# System 3: moOde Pi 4
echo "Working on System 3..."
PI3_IP=$(ping -c 1 -W 2000 moodepi4.local 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$PI3_IP" ]; then
    fix_and_open_system 3 "ssh pi3" "moOde Pi 4"
else
    echo -e "${RED}❌ System 3 offline${NC}"
    echo ""
fi

# Final verification
echo "=========================================="
echo "FINAL VERIFICATION"
echo "=========================================="
echo ""

# System 1
if ping -c 1 -W 1000 192.168.178.199 >/dev/null 2>&1; then
    PROC1=$(ssh pi1 "ps aux | grep -E 'cog|weston' | grep -v grep | wc -l" 2>/dev/null || echo "0")
    echo "System 1: $([ "$PROC1" -gt "0" ] && echo -e "${GREEN}✅ Web UI running${NC}" || echo -e "${YELLOW}⚠️  Web UI: $PROC1 processes${NC}")"
else
    echo "System 1: ${RED}❌ Offline${NC}"
fi

# System 2
if ping -c 1 -W 1000 192.168.178.134 >/dev/null 2>&1; then
    PROC2=$(ssh pi2 "ps aux | grep chromium | grep -v grep | wc -l" 2>/dev/null || echo "0")
    echo "System 2: $([ "$PROC2" -gt "0" ] && echo -e "${GREEN}✅ Web UI running ($PROC2 processes)${NC}" || echo -e "${YELLOW}⚠️  Web UI: $PROC2 processes${NC}")"
else
    echo "System 2: ${RED}❌ Offline${NC}"
fi

# System 3
PI3_IP=$(ping -c 1 -W 1000 moodepi4.local 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$PI3_IP" ]; then
    PROC3=$(ssh pi3 "ps aux | grep chromium | grep -v grep | wc -l" 2>/dev/null || echo "0")
    DISP3=$(ssh pi3 "systemctl is-active localdisplay 2>/dev/null || echo inactive")
    echo "System 3: $([ "$PROC3" -gt "0" ] && [ "$DISP3" == "active" ] && echo -e "${GREEN}✅ Web UI running ($PROC3 processes, display: $DISP3)${NC}" || echo -e "${YELLOW}⚠️  Web UI: $PROC3 processes, display: $DISP3${NC}")"
else
    echo "System 3: ${RED}❌ Offline${NC}"
fi

echo ""
echo "=========================================="
echo "WORK COMPLETE"
echo "=========================================="
echo "Date: $(date)"
echo ""

