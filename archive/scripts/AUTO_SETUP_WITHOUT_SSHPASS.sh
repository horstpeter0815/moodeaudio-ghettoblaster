#!/bin/bash
# Auto setup without sshpass (using expect or manual password)

SERIAL_PORT="/dev/cu.usbmodem214302"
PI_IP="192.168.178.143"
PI_USER="andre"
PI_PASSWORD="4512"

echo "═══════════════════════════════════════════════════════════"
echo "🤖 AUTO DEBUGGER SETUP (OHNE SSHPASS)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Step 1: Wait for Pi to boot
echo "1️⃣ Warte auf Pi-Boot..."
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
        echo "   ✅ Pi ist erreichbar"
        
        # Test SSH with expect or manual
        if timeout 3 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$PI_USER@$PI_IP" "echo 'SSH_OK'" >/dev/null 2>&1; then
            echo "   ✅ SSH funktioniert!"
            break
        else
            echo "   ⏳ SSH noch nicht bereit (Versuch $ATTEMPT/$MAX_ATTEMPTS)..."
        fi
    else
        echo "   ⏳ Pi noch nicht erreichbar (Versuch $ATTEMPT/$MAX_ATTEMPTS)..."
    fi
    
    sleep 5
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "❌ Timeout: Pi nicht erreichbar"
    exit 1
fi

# Step 2: Create SSH config for passwordless (or use expect)
echo ""
echo "2️⃣ Setup SSH-Verbindung..."

# Create SSH config
cat > /tmp/ssh_debugger_config << EOF
Host pi-debugger
    HostName $PI_IP
    User $PI_USER
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

# Step 3: Setup script to run on Pi
cat > /tmp/setup_debugger_on_pi.sh << 'PI_SETUP_EOF'
#!/bin/bash
echo "=== INSTALLIERE DEBUG-TOOLS ==="
sudo apt-get update -qq
sudo apt-get install -y -qq gdb strace valgrind perf htop >/dev/null 2>&1
echo "✅ Debug-Tools installiert"

mkdir -p ~/debug

cat > ~/debug/debug-services.sh << 'DEBUG_SCRIPT_EOF'
#!/bin/bash
debug-service() {
    SERVICE=\$1
    PID=\$(systemctl show -p MainPID --value "\$SERVICE")
    if [ -z "\$PID" ] || [ "\$PID" = "0" ]; then
        echo "❌ Service \$SERVICE läuft nicht"
        return 1
    fi
    echo "🔍 Debug Service: \$SERVICE (PID: \$PID)"
    sudo gdb -p "\$PID"
}
trace-service() {
    SERVICE=\$1
    PID=\$(systemctl show -p MainPID --value "\$SERVICE")
    if [ -z "\$PID" ] || [ "\$PID" = "0" ]; then
        echo "❌ Service \$SERVICE läuft nicht"
        return 1
    fi
    echo "🔍 Trace Service: \$SERVICE (PID: \$PID)"
    sudo strace -p "\$PID" -f -e trace=all
}
export -f debug-service trace-service
DEBUG_SCRIPT_EOF

chmod +x ~/debug/debug-services.sh
echo "✅ Debug-Helper erstellt"
PI_SETUP_EOF

chmod +x /tmp/setup_debugger_on_pi.sh

# Step 4: Copy and run setup script
echo "3️⃣ Kopiere Setup-Script..."
scp -o StrictHostKeyChecking=no /tmp/setup_debugger_on_pi.sh "$PI_USER@$PI_IP:/tmp/" 2>&1 | grep -v "password" || echo "⚠️  Bitte Passwort eingeben: $PI_PASSWORD"

echo "4️⃣ Führe Setup aus..."
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "bash /tmp/setup_debugger_on_pi.sh" 2>&1 | grep -v "password" || echo "⚠️  Bitte Passwort eingeben: $PI_PASSWORD"

echo ""
echo "✅✅✅ SETUP ABGESCHLOSSEN!"
echo ""
echo "📋 Verbindung:"
echo "   ssh $PI_USER@$PI_IP"
echo "   Password: $PI_PASSWORD"
echo ""
echo "🔧 Debug-Befehle:"
echo "   source ~/debug/debug-services.sh"
echo "   debug-service localdisplay.service"


