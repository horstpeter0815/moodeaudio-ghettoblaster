#!/bin/bash
# Quick SSH test script
# Usage: ./test-ssh.sh [password]

IP="10.10.11.39"
USER="andre"

# Read password from file if it exists, otherwise use default
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWORD_FILE="$SCRIPT_DIR/test-password.txt"
if [ -f "$PASSWORD_FILE" ]; then
    PASSWORD=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
else
    PASSWORD="${1:-4512}"
fi

echo "Testing SSH connection to $USER@$IP..."
echo "Using password: $PASSWORD"
echo ""

# Try SSH with password
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER@$IP "echo 'SSH connection successful!'" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSH connection works!"
    echo "Password is correct: $PASSWORD"
else
    echo ""
    echo "❌ SSH connection failed"
    echo "Possible reasons:"
    echo "  - Wrong password"
    echo "  - User doesn't exist"
    echo "  - SSH service not running"
    echo "  - Network issue"
    echo ""
    echo "Try manually:"
    echo "  ssh $USER@$IP"
fi

