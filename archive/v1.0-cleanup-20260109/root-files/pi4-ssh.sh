#!/bin/bash
# SSH helper for the active Pi (Pi 5 / moOde)
# Usage:
#   ./pi-ssh.sh "command"
#   ./pi-ssh.sh (interactive)

# Load IP from file if present; otherwise fall back to deterministic default.
# (Project default is 192.168.10.2 for the Pi)
if [ -f .pi_ip ]; then
    PI_IP=$(cat .pi_ip)
elif [ -f .pi4_ip ]; then
    # Legacy filename kept for backwards compatibility (Pi 5 is in use)
    PI_IP=$(cat .pi4_ip)
else
    PI_IP="192.168.10.2"
fi

if [ -z "${PI_IP:-}" ]; then
    echo "❌ Pi IP not found. Create a .pi_ip file or use the default 192.168.10.2."
    exit 1
fi

PI_USER="andre"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Funktion: SSH-Befehl ausführen
pi4_exec() {
    ssh $SSH_OPTS "$PI_USER@$PI_IP" "$@"
}

# Funktion: Datei kopieren (local -> remote)
pi4_copy() {
    local_file="$1"
    remote_file="$2"
    scp $SSH_OPTS "$local_file" "$PI_USER@$PI_IP:$remote_file"
}

# Funktion: Datei kopieren (remote -> local)
pi4_pull() {
    remote_file="$1"
    local_file="$2"
    scp $SSH_OPTS "$PI_USER@$PI_IP:$remote_file" "$local_file"
}

# Funktion: Interaktive Shell
pi4_shell() {
    ssh $SSH_OPTS "$PI_USER@$PI_IP"
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

