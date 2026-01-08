#!/bin/bash
# Effizientes SSH-Script für Pi 5
# Verwendung: ./pi5-ssh.sh "command"
# Oder: ./pi5-ssh.sh (interaktiv)

PI5_IP="192.168.178.143"
PI5_USER="andre"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Funktion: SSH-Befehl ausführen
pi5_exec() {
    ssh pi2 "$@"
}

# Funktion: Datei kopieren (local -> remote)
pi5_copy() {
    local_file="$1"
    remote_file="$2"
    scp $SSH_OPTS "$local_file" "$PI5_USER@$PI5_IP:$remote_file"
}

# Funktion: Datei kopieren (remote -> local)
pi5_pull() {
    remote_file="$1"
    local_file="$2"
    scp $SSH_OPTS "$PI5_USER@$PI5_IP:$remote_file" "$local_file"
}

# Funktion: Interaktive Shell
pi5_shell() {
    ssh pi2
}

# Hauptlogik
if [ $# -eq 0 ]; then
    # Keine Argumente: Interaktive Shell
    pi5_shell
elif [ "$1" == "copy" ] && [ $# -eq 3 ]; then
    # copy local_file remote_file
    pi5_copy "$2" "$3"
elif [ "$1" == "pull" ] && [ $# -eq 3 ]; then
    # pull remote_file local_file
    pi5_pull "$2" "$3"
elif [ "$1" == "shell" ]; then
    # Explizit Shell starten
    pi5_shell
else
    # Befehl ausführen
    pi5_exec "$@"
fi

