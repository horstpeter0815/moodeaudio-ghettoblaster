#!/bin/bash
################################################################################
#
# CREATE USER ANDRE ON PI
#
# Erstellt Benutzer 'andre' mit UID 1000 und sudo-Rechten
#
################################################################################

PI_IP=""
PI_USER="pi"
PI_PASS="moodeaudio"

# Finde Pi
for ip in "192.168.10.2" "192.168.1.100" "moodepi5.local" "GhettoBlaster.local"; do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        PI_IP="$ip"
        break
    fi
done

if [ -z "$PI_IP" ]; then
    echo "❌ Pi nicht gefunden"
    exit 1
fi

echo "✅ Pi gefunden: $PI_IP"
echo ""

# Prüfe SSH-Verbindung
if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    echo "❌ SSH-Verbindung fehlgeschlagen"
    echo "   Versuche andere Passwörter..."
    for pass in "raspberry" "moode" ""; do
        if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
            PI_PASS="$pass"
            break
        fi
    done
    if [ -z "$PI_PASS" ] || ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
        echo "❌ SSH-Verbindung nicht möglich"
        exit 1
    fi
fi

echo "✅ SSH-Verbindung funktioniert"
echo ""

# Erstelle Benutzer 'andre'
echo "🔧 Erstelle Benutzer 'andre'..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF'
# Prüfe ob Benutzer bereits existiert
if id -u andre >/dev/null 2>&1; then
    echo "⚠️  Benutzer 'andre' existiert bereits"
    # Setze Passwort neu
    echo "andre:0815" | sudo chpasswd
    echo "✅ Passwort für 'andre' gesetzt: 0815"
else
    # Erstelle Benutzer mit UID 1000
    sudo useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        # Falls Gruppe 1000 nicht existiert
        sudo groupadd -g 1000 andre 2>/dev/null || true
        sudo useradd -m -s /bin/bash -u 1000 -g 1000 andre
    }
    
    # Setze Passwort
    echo "andre:0815" | sudo chpasswd
    
    # Füge zu sudo hinzu
    echo "andre ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/andre > /dev/null
    sudo chmod 0440 /etc/sudoers.d/andre
    
    # Füge zu Gruppen hinzu
    sudo usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || \
    sudo usermod -aG audio,video,sudo andre 2>/dev/null || true
    
    echo "✅ Benutzer 'andre' erstellt"
    echo "   UID: 1000"
    echo "   Password: 0815"
    echo "   Sudo: aktiviert (ohne Passwort)"
fi

# Prüfe UID
ANDRE_UID=$(id -u andre 2>/dev/null || echo "0")
if [ "$ANDRE_UID" = "1000" ]; then
    echo "✅ UID korrekt: 1000"
else
    echo "⚠️  UID ist $ANDRE_UID (sollte 1000 sein)"
fi

echo ""
echo "📋 Benutzer-Info:"
id andre
echo ""
echo "✅ Fertig!"
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Benutzer 'andre' erstellt!"
    echo ""
    echo "📋 Verbindung:"
    echo "   ssh andre@$PI_IP"
    echo "   Password: 0815"
    echo ""
    echo "✅ Sudo ohne Passwort aktiviert"
else
    echo ""
    echo "❌ Fehler beim Erstellen des Benutzers"
    exit 1
fi

