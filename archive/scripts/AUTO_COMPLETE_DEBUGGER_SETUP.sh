#!/bin/bash
# Automatically connect Serial Console, monitor boot, and setup debugger

SERIAL_PORT="/dev/cu.usbmodem214302"
BAUDRATE="115200"
PI_IP="192.168.178.143"
PI_USER="andre"
PI_PASSWORD=""
LOG_FILE="auto-debugger-$(date +%Y%m%d_%H%M%S).log"

echo "═══════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
echo "🤖 AUTO COMPLETE DEBUGGER SETUP" | tee -a "$LOG_FILE"
echo "═══════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📋 Konfiguration:" | tee -a "$LOG_FILE"
echo "   Serial-Port: $SERIAL_PORT" | tee -a "$LOG_FILE"
echo "   Pi IP: $PI_IP" | tee -a "$LOG_FILE"
echo "   User: $PI_USER" | tee -a "$LOG_FILE"
echo "   Log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check Serial Port
if [ ! -e "$SERIAL_PORT" ]; then
    echo "❌ Serial-Port nicht gefunden: $SERIAL_PORT" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Serial-Port gefunden: $SERIAL_PORT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Step 1: Monitor Serial Console in background
echo "1️⃣ Starte Serial-Konsole-Monitoring..." | tee -a "$LOG_FILE"
(
    timeout 60 cat "$SERIAL_PORT" 2>/dev/null | while IFS= read -r line; do
        echo "[SERIAL] $line" | tee -a "$LOG_FILE"
        # Check for boot completion
        if echo "$line" | grep -q "login\|GhettoBlaster\|moOde"; then
            echo "✅ Boot erkannt in Serial-Logs!" | tee -a "$LOG_FILE"
        fi
    done
) &
SERIAL_PID=$!

# Step 2: Wait for Pi to boot and SSH to be available
echo "2️⃣ Warte auf Pi-Boot und SSH..." | tee -a "$LOG_FILE"
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    # Check if Pi is reachable
    if ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
        echo "   ✅ Pi ist erreichbar ($PI_IP)" | tee -a "$LOG_FILE"
        
        # Check SSH
        if timeout 3 sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$PI_USER@$PI_IP" "echo 'SSH_OK'" >/dev/null 2>&1; then
            echo "   ✅ SSH funktioniert!" | tee -a "$LOG_FILE"
            break
        else
            echo "   ⏳ SSH noch nicht bereit (Versuch $ATTEMPT/$MAX_ATTEMPTS)..." | tee -a "$LOG_FILE"
        fi
    else
        echo "   ⏳ Pi noch nicht erreichbar (Versuch $ATTEMPT/$MAX_ATTEMPTS)..." | tee -a "$LOG_FILE"
    fi
    
    sleep 5
done

# Kill serial monitoring
kill $SERIAL_PID 2>/dev/null || true

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "❌ Timeout: Pi nicht erreichbar nach $MAX_ATTEMPTS Versuchen" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 3: Setup Debugger
echo "" | tee -a "$LOG_FILE"
echo "3️⃣ Setup Debugger auf Pi..." | tee -a "$LOG_FILE"

# Install debug tools
sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF' | tee -a "$LOG_FILE"
    echo "=== INSTALLIERE DEBUG-TOOLS ==="
    sudo apt-get update -qq
    sudo apt-get install -y -qq gdb strace valgrind perf htop >/dev/null 2>&1
    echo "✅ Debug-Tools installiert"
    
    # Create debug directory
    mkdir -p ~/debug
    echo "✅ Debug-Verzeichnis erstellt"
    
    # Create debug helper script
    cat > ~/debug/debug-services.sh << 'DEBUG_SCRIPT_EOF'
#!/bin/bash
# Debug Helper Script für Services

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

export -f debug-service
export -f trace-service
export -f monitor-service

echo "✅ Debug-Helper-Script erstellt"
DEBUG_SCRIPT_EOF
    
    chmod +x ~/debug/debug-services.sh
    echo "✅ Debug-Helper-Script ausführbar gemacht"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Debugger-Setup erfolgreich!" | tee -a "$LOG_FILE"
else
    echo "⚠️  Debugger-Setup mit Warnungen abgeschlossen" | tee -a "$LOG_FILE"
fi

# Step 4: Check services
echo "" | tee -a "$LOG_FILE"
echo "4️⃣ Prüfe Services..." | tee -a "$LOG_FILE"

sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF' | tee -a "$LOG_FILE"
    echo "=== SERVICE STATUS ==="
    systemctl status localdisplay.service --no-pager -l | head -10
    echo ""
    echo "=== CHROMIUM STATUS ==="
    pgrep chromium && echo "✅ Chromium läuft" || echo "❌ Chromium läuft nicht"
    echo ""
    echo "=== NETWORK STATUS ==="
    ip addr show | grep -E "inet.*192.168" | head -3
EOF

echo "" | tee -a "$LOG_FILE"
echo "═══════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
echo "✅✅✅ AUTO DEBUGGER SETUP ABGESCHLOSSEN!" | tee -a "$LOG_FILE"
echo "═══════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📋 Verbindung:" | tee -a "$LOG_FILE"
echo "   ssh $PI_USER@$PI_IP" | tee -a "$LOG_FILE"
echo "   Password: $PI_PASSWORD" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "🔧 Debug-Befehle:" | tee -a "$LOG_FILE"
echo "   source ~/debug/debug-services.sh" | tee -a "$LOG_FILE"
echo "   debug-service localdisplay.service" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📝 Log: $LOG_FILE" | tee -a "$LOG_FILE"


