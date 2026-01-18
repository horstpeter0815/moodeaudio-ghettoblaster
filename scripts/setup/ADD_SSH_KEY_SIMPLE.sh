#!/bin/bash
# Simple one-liner: Add SSH key to user andre
# Usage: Just paste the SSH public key when prompted

read -p "Paste SSH public key: " SSH_KEY

if [ -z "$SSH_KEY" ]; then
    echo "No key provided"
    exit 1
fi

sudo -u andre mkdir -p /home/andre/.ssh
echo "$SSH_KEY" | sudo -u andre tee -a /home/andre/.ssh/authorized_keys > /dev/null
sudo chmod 700 /home/andre/.ssh
sudo chmod 600 /home/andre/.ssh/authorized_keys
sudo chown -R andre:andre /home/andre/.ssh

echo "$SSH_KEY" | sudo tee /etc/sudoers.d/andre > /dev/null
sudo chmod 0440 /etc/sudoers.d/andre

echo "✅ Done! SSH key added to andre"
