#!/bin/bash
# Check Debugger Setup Status

echo "═══════════════════════════════════════════════════════════"
echo "📊 DEBUGGER STATUS PRÜFEN"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check Serial Port
if [ -e "/dev/cu.usbmodem214302" ]; then
    echo "✅ Serial-Port: /dev/cu.usbmodem214302"
else
    echo "❌ Serial-Port nicht gefunden"
fi

# Check Pi connectivity
PI_IP="192.168.178.143"
if ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
    echo "✅ Pi erreichbar: $PI_IP"
    
    # Check SSH
    if timeout 3 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 andre@$PI_IP "echo 'SSH_OK'" >/dev/null 2>&1; then
        echo "✅ SSH funktioniert"
        
        # Check debug tools
        ssh -o StrictHostKeyChecking=no andre@$PI_IP << 'EOF'
            echo ""
            echo "📋 Debug-Tools auf Pi:"
            which gdb && echo "   ✅ gdb installiert" || echo "   ❌ gdb nicht installiert"
            which strace && echo "   ✅ strace installiert" || echo "   ❌ strace nicht installiert"
            which perf && echo "   ✅ perf installiert" || echo "   ❌ perf nicht installiert"
            
            echo ""
            echo "📋 Debug-Helper:"
            if [ -f ~/debug/debug-services.sh ]; then
                echo "   ✅ debug-services.sh vorhanden"
            else
                echo "   ❌ debug-services.sh nicht vorhanden"
            fi
            
            echo ""
            echo "📋 Services:"
            systemctl is-active localdisplay.service >/dev/null 2>&1 && echo "   ✅ localdisplay.service aktiv" || echo "   ❌ localdisplay.service nicht aktiv"
            pgrep chromium >/dev/null && echo "   ✅ Chromium läuft" || echo "   ❌ Chromium läuft nicht"
EOF
    else
        echo "⏳ SSH noch nicht bereit"
    fi
else
    echo "⏳ Pi noch nicht erreichbar"
fi

# Check log files
echo ""
echo "📋 Log-Dateien:"
LATEST_LOG=$(ls -t auto-debugger-*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
    echo "   ✅ Neueste Log: $LATEST_LOG"
    echo "   Letzte Zeilen:"
    tail -5 "$LATEST_LOG" | sed 's/^/      /'
else
    echo "   ⏳ Noch keine Log-Dateien"
fi

echo ""
echo "✅ Status-Prüfung abgeschlossen"


