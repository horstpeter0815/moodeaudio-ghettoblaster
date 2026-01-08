#!/bin/bash
# Monitor Pi Boot Status

echo "═══════════════════════════════════════════════════════════"
echo "🔍 MONITOR PI BOOT - VERSUCH #27"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⏱️  Prüfe alle 10 Sekunden..."
echo ""

ATTEMPTS=0
MAX_ATTEMPTS=60  # 10 Minuten

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    
    echo "[$(date +%H:%M:%S)] Versuch $ATTEMPTS/$MAX_ATTEMPTS..."
    
    # Test 1: Ping IP
    if ping -c 1 -W 1 192.168.178.143 >/dev/null 2>&1; then
        echo "✅ IP erreichbar: 192.168.178.143"
        
        # Test 2: SSH
        if timeout 2 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no andre@192.168.178.143 "echo 'SSH OK'" >/dev/null 2>&1; then
            echo "✅ SSH funktioniert!"
            echo ""
            echo "═══════════════════════════════════════════════════════════"
            echo "✅✅✅ PI IST ERREICHBAR!"
            echo "═══════════════════════════════════════════════════════════"
            echo ""
            echo "📋 Verbindung:"
            echo "   SSH: ssh andre@192.168.178.143"
            echo "   Password: 0815"
            echo "   Web-UI: http://192.168.178.143"
            echo ""
            exit 0
        else
            echo "⏳ SSH noch nicht bereit..."
        fi
        
        # Test 3: Web-UI
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://192.168.178.143 2>/dev/null)
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
            echo "✅ Web-UI erreichbar (HTTP $HTTP_CODE)"
        else
            echo "⏳ Web-UI noch nicht bereit..."
        fi
    else
        echo "⏳ IP noch nicht erreichbar..."
    fi
    
    echo ""
    sleep 10
done

echo "⚠️  Timeout nach $MAX_ATTEMPTS Versuchen"
echo "   Prüfe manuell:"
echo "   - ssh andre@192.168.178.143"
echo "   - http://192.168.178.143"
exit 1

