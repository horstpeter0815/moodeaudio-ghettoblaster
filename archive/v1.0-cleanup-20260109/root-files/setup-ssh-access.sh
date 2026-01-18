#!/bin/bash
# Setup SSH key access to moOde system

PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
HOST="moode.local"
USER="andre"

echo "Setting up SSH key access to $USER@$HOST"
echo ""
echo "Your public key:"
echo "$PUBLIC_KEY"
echo ""

# Method 1: Try sshpass if password is provided
if [ -n "$SSH_PASSWORD" ]; then
    echo "Using sshpass with provided password..."
    sshpass -p "$SSH_PASSWORD" ssh-copy-id -i ~/.ssh/id_rsa.pub "$USER@$HOST"
    if [ $? -eq 0 ]; then
        echo "✓ SSH key copied successfully"
        echo "Testing connection..."
        ssh -o ConnectTimeout=5 moode "echo 'SSH access working!' && whoami && hostname"
        exit 0
    fi
fi

# Method 2: Use expect script
echo "Creating expect script for password entry..."
cat > /tmp/ssh-copy-id-expect.exp << 'EXPECTSCRIPT'
#!/usr/bin/expect -f
set timeout 30
set host [lindex $argv 0]
set user [lindex $argv 1]
set pubkey_file [lindex $argv 2]

spawn ssh-copy-id -i $pubkey_file $user@$host
expect {
    "password:" {
        send_user "Password required - please enter it manually\n"
        interact
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    eof
}
EXPECTSCRIPT

chmod +x /tmp/ssh-copy-id-expect.exp
echo "Run this command and enter password when prompted:"
echo "  /tmp/ssh-copy-id-expect.exp $HOST $USER ~/.ssh/id_rsa.pub"
echo ""
echo "Or manually copy the key:"
echo "  ssh $USER@$HOST 'mkdir -p ~/.ssh && echo \"$PUBLIC_KEY\" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'"

