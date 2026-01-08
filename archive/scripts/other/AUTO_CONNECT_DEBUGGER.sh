#!/bin/bash
# Automatically wait for Pi to boot and connect debugger

echo "═══════════════════════════════════════════════════════════"
echo "🔌 AUTO-CONNECT DEBUGGER - VERSUCH #27"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⏱️  Warte auf Pi-Boot und verbinde dann automatisch..."
echo ""

PI_IP="192.168.178.143"
PI_USER="andre"
PI_PASSWORD="0815"
MAX_ATTEMPTS=60  # 10 Minuten (10 Sekunden pro Versuch)
ATTEMPT=0

# Function to check if Pi is reachable
check_pi_reachable() {
    ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1
}

# Function to check if SSH works
check_ssh() {
    timeout 3 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o PasswordAuthentication=yes "$PI_USER@$PI_IP" "echo 'SSH_OK'" >/dev/null 2>&1
}

# Wait for Pi to boot
echo "1️⃣ Warte auf Pi-Boot..."
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if check_pi_reachable; then
        echo "   ✅ Pi ist erreichbar ($PI_IP)"
        
        if check_ssh; then
            echo "   ✅ SSH funktioniert!"
            echo ""
            break
        else
            echo "   ⏳ SSH noch nicht bereit (Versuch $ATTEMPT/$MAX_ATTEMPTS)..."
        fi
    else
        echo "   ⏳ Pi noch nicht erreichbar (Versuch $ATTEMPT/$MAX_ATTEMPTS)..."
    fi
    
    sleep 10
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo ""
    echo "❌ Timeout: Pi nicht erreichbar nach $MAX_ATTEMPTS Versuchen"
    echo "   Prüfe manuell:"
    echo "   - ping $PI_IP"
    echo "   - ssh $PI_USER@$PI_IP"
    exit 1
fi

echo ""
echo "2️⃣ Setup Debugger..."
echo "═══════════════════════════════════════════════════════════"

# Check if SETUP_PI_DEBUGGER.sh exists
if [ -f "./SETUP_PI_DEBUGGER.sh" ]; then
    echo "   ✅ SETUP_PI_DEBUGGER.sh gefunden"
    echo "   🔧 Führe Setup aus..."
    
    # Run setup script
    ./SETUP_PI_DEBUGGER.sh "$PI_IP" "$PI_USER" || {
        echo "   ⚠️  Setup-Script fehlgeschlagen, versuche manuell..."
    }
else
    echo "   ⚠️  SETUP_PI_DEBUGGER.sh nicht gefunden"
    echo "   🔧 Installiere Debug-Tools manuell..."
    
    # Manual installation via SSH
    ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF'
        echo "Installing debug tools..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq gdb strace valgrind perf htop >/dev/null 2>&1
        echo "✅ Debug tools installed"
EOF
fi

echo ""
echo "3️⃣ Verbinde Debugger..."
echo "═══════════════════════════════════════════════════════════"

# Create debug connection script
cat > /tmp/debug_connect.sh << 'DEBUGEOF'
#!/bin/bash
echo "🔌 DEBUGGER VERBUNDEN!"
echo ""
echo "📋 Verfügbare Debug-Befehle:"
echo ""
echo "1️⃣ Service debuggen:"
echo "   debug-service localdisplay.service"
echo ""
echo "2️⃣ Chromium debuggen:"
echo "   PID=\$(pgrep chromium)"
echo "   sudo gdb -p \$PID"
echo ""
echo "3️⃣ System-Calls verfolgen:"
echo "   trace-service localdisplay.service"
echo ""
echo "4️⃣ Logs ansehen:"
echo "   journalctl -u localdisplay.service -f"
echo ""
echo "5️⃣ Prozess überwachen:"
echo "   htop"
echo ""
echo "✅ Debugger bereit!"
DEBUGEOF

chmod +x /tmp/debug_connect.sh

# Copy debug helper if it exists
if [ -f "./custom-components/scripts/debug-services.sh" ]; then
    echo "   📋 Kopiere Debug-Helper..."
    scp -o StrictHostKeyChecking=no "./custom-components/scripts/debug-services.sh" "$PI_USER@$PI_IP:~/debug/" 2>/dev/null || true
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅✅✅ DEBUGGER VERBUNDEN!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 SSH-Verbindung:"
echo "   ssh $PI_USER@$PI_IP"
echo "   Password: $PI_PASSWORD"
echo ""
echo "🔧 Debug-Befehle:"
echo "   # Debug-Helper laden (falls vorhanden):"
echo "   source ~/debug/debug-services.sh"
echo ""
echo "   # Service debuggen:"
echo "   debug-service localdisplay.service"
echo ""
echo "   # Chromium debuggen:"
echo "   PID=\$(pgrep chromium)"
echo "   sudo gdb -p \$PID"
echo ""
echo "   # Logs ansehen:"
echo "   journalctl -u localdisplay.service -f"
echo ""
echo "🎯 Verbinde jetzt mit SSH und starte Debugging!"
echo ""

# Optionally open SSH connection
read -p "SSH-Verbindung jetzt öffnen? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[JjYy]$ ]]; then
    echo "🔌 Öffne SSH-Verbindung..."
    ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP"
fi


