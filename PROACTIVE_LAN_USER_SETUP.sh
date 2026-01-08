#!/bin/bash
################################################################################
#
# PROACTIVE LAN USER SETUP
#
# Konfiguriert Mac Ethernet und erstellt Benutzer sofort wenn Pi online ist
#
################################################################################

# Konfiguriere Mac Ethernet
ETHERNET_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Ethernet Adapter" | grep "Hardware Port" | head -1 | awk -F': ' '{print $2}')

echo "🔧 Konfiguriere Mac Ethernet: $ETHERNET_INTERFACE"
sudo networksetup -setmanual "$ETHERNET_INTERFACE" 192.168.10.1 255.255.255.0 192.168.10.1

echo "✅ Mac Ethernet: 192.168.10.1"
echo ""

# Warte kurz
sleep 3

# Prüfe kontinuierlich und handle sofort
echo "🔍 Prüfe Pi über LAN-Kabel..."
ATTEMPTS=0
MAX_ATTEMPTS=120  # 10 Minuten

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    
    if ping -c 1 -W 1 192.168.10.2 >/dev/null 2>&1; then
        echo "✅ Pi ist online: 192.168.10.2"
        echo ""
        
        # Prüfe SSH
        for user in "pi" "andre"; do
            for pass in "moodeaudio" "raspberry" "0815" ""; do
                if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$user@192.168.10.2" "echo 'SSH OK'" >/dev/null 2>&1; then
                    echo "✅ SSH funktioniert: $user@192.168.10.2"
                    echo ""
                    echo "🔧 Erstelle Benutzer 'andre'..."
                    
                    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@192.168.10.2" << 'EOF'
if ! id -u andre >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        sudo groupadd -g 1000 andre 2>/dev/null || true
        sudo useradd -m -s /bin/bash -u 1000 -g 1000 andre
    }
    echo "andre:0815" | sudo chpasswd
    echo "andre ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/andre > /dev/null
    sudo chmod 0440 /etc/sudoers.d/andre
    sudo usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || sudo usermod -aG audio,video,sudo andre 2>/dev/null || true
    echo "✅ Benutzer 'andre' erstellt"
else
    echo "andre:0815" | sudo chpasswd
    echo "✅ Passwort für 'andre' gesetzt"
fi
id andre
EOF
                    
                    echo ""
                    echo "✅ FERTIG!"
                    echo "📋 Verbindung: ssh andre@192.168.10.2"
                    echo "   Password: 0815"
                    exit 0
                fi
            done
        done
        
        echo "⏳ SSH noch nicht bereit, warte..."
    fi
    
    sleep 5
done

echo "⏳ Timeout: Pi nicht online nach $MAX_ATTEMPTS Versuchen"

