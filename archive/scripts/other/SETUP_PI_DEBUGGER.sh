#!/bin/bash
################################################################################
#
# SETUP DEBUGGER DIRECTLY ON PI
#
# Installiert Debug-Tools direkt auf dem Raspberry Pi
# Ermöglicht direktes Debugging ohne Mac-Verbindung
#
################################################################################

PI_HOST="${1:-GhettoBlaster.local}"
PI_USER="${2:-andre}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 DEBUGGER AUF PI EINRICHTEN                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Verbinde zu Pi: $PI_USER@$PI_HOST"
echo ""

# Test SSH-Verbindung
if ! ssh -o ConnectTimeout=5 "$PI_USER@$PI_HOST" "echo 'SSH OK'" 2>/dev/null; then
    echo "❌ ERROR: Kann nicht zu Pi verbinden: $PI_USER@$PI_HOST"
    echo ""
    echo "📋 Mögliche Lösungen:"
    echo "  1. Prüfe ob Pi läuft"
    echo "  2. Prüfe IP-Adresse: ping GhettoBlaster.local"
    echo "  3. Prüfe SSH: ssh $PI_USER@$PI_HOST"
    exit 1
fi

echo "✅ SSH-Verbindung OK"
echo ""

echo "🔧 Installiere Debug-Tools auf Pi..."
ssh "$PI_USER@$PI_HOST" << 'PI_DEBUG_EOF'
    echo "=== INSTALLIERE DEBUG-TOOLS ==="
    
    # Update package list
    sudo apt-get update
    
    # Install debug tools
    sudo apt-get install -y \
        gdb \
        gdb-multiarch \
        strace \
        ltrace \
        valgrind \
        gdbserver \
        python3-dbg \
        python3-gdb \
        systemd-coredump \
        coredumpctl \
        tcpdump \
        wireshark-common \
        wireshark-cli \
        htop \
        iotop \
        perf \
        bpftrace
    
    echo "✅ Debug-Tools installiert"
    
    # Create debug directory
    mkdir -p ~/debug
    echo "✅ Debug-Verzeichnis erstellt: ~/debug"
    
    # Create debug helper script
    cat > ~/debug/debug-services.sh << 'DEBUG_SCRIPT_EOF'
#!/bin/bash
# Debug Helper Script für Services

echo "=== SERVICE DEBUG HELPER ==="
echo ""
echo "Verfügbare Befehle:"
echo "  debug-service <service>  - Debug Service mit gdb"
echo "  trace-service <service>   - Trace Service mit strace"
echo "  monitor-service <service> - Monitor Service mit htop"
echo ""

debug-service() {
    SERVICE=$1
    if [ -z "$SERVICE" ]; then
        echo "❌ Bitte Service-Name angeben"
        return 1
    fi
    
    PID=$(systemctl show -p MainPID --value "$SERVICE")
    if [ -z "$PID" ] || [ "$PID" = "0" ]; then
        echo "❌ Service $SERVICE läuft nicht"
        return 1
    fi
    
    echo "🔍 Debug Service: $SERVICE (PID: $PID)"
    sudo gdb -p "$PID"
}

trace-service() {
    SERVICE=$1
    if [ -z "$SERVICE" ]; then
        echo "❌ Bitte Service-Name angeben"
        return 1
    fi
    
    PID=$(systemctl show -p MainPID --value "$SERVICE")
    if [ -z "$PID" ] || [ "$PID" = "0" ]; then
        echo "❌ Service $SERVICE läuft nicht"
        return 1
    fi
    
    echo "🔍 Trace Service: $SERVICE (PID: $PID)"
    sudo strace -p "$PID" -f -e trace=all
}

monitor-service() {
    SERVICE=$1
    if [ -z "$SERVICE" ]; then
        echo "❌ Bitte Service-Name angeben"
        return 1
    fi
    
    PID=$(systemctl show -p MainPID --value "$SERVICE")
    if [ -z "$PID" ] || [ "$PID" = "0" ]; then
        echo "❌ Service $SERVICE läuft nicht"
        return 1
    fi
    
    echo "🔍 Monitor Service: $SERVICE (PID: $PID)"
    htop -p "$PID"
}

# Export functions
export -f debug-service
export -f trace-service
export -f monitor-service

echo "✅ Debug-Helper-Script erstellt"
DEBUG_SCRIPT_EOF
    
    chmod +x ~/debug/debug-services.sh
    echo "✅ Debug-Helper-Script ausführbar gemacht"
    
    # Add to .bashrc
    if ! grep -q "debug/debug-services.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Load debug helper" >> ~/.bashrc
        echo "source ~/debug/debug-services.sh" >> ~/.bashrc
        echo "✅ Debug-Helper zu .bashrc hinzugefügt"
    fi
    
    echo ""
    echo "✅ DEBUG-TOOLS INSTALLIERT"
    echo ""
    echo "📋 Verfügbare Tools:"
    echo "  - gdb (GNU Debugger)"
    echo "  - strace (System Call Tracer)"
    echo "  - valgrind (Memory Debugger)"
    echo "  - perf (Performance Profiler)"
    echo "  - htop (Process Monitor)"
    echo ""
    echo "📋 Debug-Helper:"
    echo "  - ~/debug/debug-services.sh"
    echo "  - debug-service <service>"
    echo "  - trace-service <service>"
    echo "  - monitor-service <service>"
PI_DEBUG_EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ DEBUGGER AUF PI EINGERICHTET                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 NÄCHSTE SCHRITTE:"
    echo "  1. SSH zum Pi: ssh $PI_USER@$PI_HOST"
    echo "  2. Debug-Helper laden: source ~/debug/debug-services.sh"
    echo "  3. Service debuggen: debug-service <service-name>"
    echo ""
    echo "📋 BEISPIELE:"
    echo "  - debug-service localdisplay.service"
    echo "  - trace-service localdisplay.service"
    echo "  - monitor-service localdisplay.service"
    echo ""
else
    echo ""
    echo "❌ ERROR: Installation fehlgeschlagen"
    exit 1
fi

