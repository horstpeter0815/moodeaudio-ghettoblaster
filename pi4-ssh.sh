#!/bin/bash
# Effizientes SSH-Script für Pi 4 (moodepi4)
# Verwendung: ./pi4-ssh.sh "command"
# Oder: ./pi4-ssh.sh (interaktiv)

# Lade IP aus Datei oder verwende mDNS
if [ -f .pi4_ip ]; then
    PI4_IP=$(cat .pi4_ip)
else
    PI4_IP=$(ping -c 1 -W 1000 "moodepi4.local" 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
fi

if [ -z "$PI4_IP" ]; then
    echo "❌ Pi 4 IP nicht gefunden. Bitte setup-pi4-ssh.sh ausführen oder IP manuell setzen."
    exit 1
fi

PI4_USER="andre"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Funktion: SSH-Befehl ausführen
pi4_exec() {
    ssh pi3 "$@"
}

# Funktion: Datei kopieren (local -> remote)
pi4_copy() {
    local_file="$1"
    remote_file="$2"
    scp $SSH_OPTS "$local_file" "$PI4_USER@$PI4_IP:$remote_file"
}

# Funktion: Datei kopieren (remote -> local)
pi4_pull() {
    remote_file="$1"
    local_file="$2"
    scp $SSH_OPTS "$PI4_USER@$PI4_IP:$remote_file" "$local_file"
}

# Funktion: Interaktive Shell
pi4_shell() {
    ssh pi3
}

# Hauptlogik
if [ $# -eq 0 ]; then
    # Keine Argumente: Interaktive Shell
    pi4_shell
elif [ "$1" == "copy" ] && [ $# -eq 3 ]; then
    # copy local_file remote_file
    pi4_copy "$2" "$3"
elif [ "$1" == "pull" ] && [ $# -eq 3 ]; then
    # pull remote_file local_file
    pi4_pull "$2" "$3"
elif [ "$1" == "shell" ]; then
    # Explizit Shell starten
    pi4_shell
else
    # Befehl ausführen
    pi4_exec "$@"
fi

