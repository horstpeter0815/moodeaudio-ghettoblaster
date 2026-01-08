#!/bin/bash

# CONNECT TO PI - ghettopi4.local, user: andre, password: 0815

HOSTNAME="ghettopi4.local"
USER="andre"
PASSWORD="0815"

echo "Connecting to $USER@$HOSTNAME..."

# Try with sshpass if available, otherwise regular ssh
if command -v sshpass &> /dev/null; then
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$HOSTNAME"
else
    # Try regular SSH (might prompt for password)
    ssh -o StrictHostKeyChecking=no "$USER@$HOSTNAME"
fi

