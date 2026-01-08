#!/bin/bash
# PERMANENT SSH SETUP FOR ALL THREE SYSTEMS
# Sets up SSH keys so connections work without password every time

echo "=========================================="
echo "PERMANENT SSH SETUP - ALL SYSTEMS"
echo "=========================================="
echo ""

# System definitions
SYSTEM1_IP="192.168.178.199"
SYSTEM1_USER="root"
SYSTEM1_PASS="hifiberry"
SYSTEM1_NAME="HiFiBerryOS Pi 4"

SYSTEM2_IP="192.168.178.134"
SYSTEM2_USER="andre"
SYSTEM2_PASS="0815"
SYSTEM2_NAME="moOde Pi 5"

SYSTEM3_HOSTNAME="moodepi4.local"
SYSTEM3_USER="andre"
SYSTEM3_PASS="0815"
SYSTEM3_NAME="moOde Pi 4"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure SSH directory exists
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_rsa"

if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Create SSH key if it doesn't exist
if [ ! -f "$SSH_KEY" ]; then
    echo "Creating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -q
    echo -e "${GREEN}✅ SSH key created${NC}"
else
    echo -e "${GREEN}✅ SSH key already exists${NC}"
fi
echo ""

# Function to setup SSH for a system
setup_ssh() {
    local system_num=$1
    local ip=$2
    local user=$3
    local pass=$4
    local name=$5
    
    echo "=========================================="
    echo "System $system_num: $name"
    echo "=========================================="
    
    # Check if system is online
    if ! ping -c 1 -W 2000 "$ip" >/dev/null 2>&1; then
        echo -e "${RED}❌ System offline - skipping${NC}"
        echo ""
        return 1
    fi
    
    echo "IP: $ip"
    echo "User: $user"
    echo ""
    
    # Copy SSH key
    echo "Copying SSH key..."
    if sshpass -p "$pass" ssh-copy-id -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$user@$ip" 2>&1 | grep -v "Warning: Permanently added"; then
        echo -e "${GREEN}✅ SSH key copied${NC}"
    else
        # Key might already be there, test connection
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$user@$ip" "hostname" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ SSH key already installed${NC}"
        else
            echo -e "${YELLOW}⚠️  Key copy failed, but testing connection...${NC}"
        fi
    fi
    
    # Test connection
    echo "Testing SSH connection..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$user@$ip" "hostname" >/dev/null 2>&1; then
        HOSTNAME=$(ssh -o StrictHostKeyChecking=no "$user@$ip" "hostname" 2>/dev/null)
        echo -e "${GREEN}✅ SSH works! Hostname: $HOSTNAME${NC}"
        
        # Add to SSH config for easy access
        SSH_CONFIG="$SSH_DIR/config"
        if [ ! -f "$SSH_CONFIG" ]; then
            touch "$SSH_CONFIG"
            chmod 600 "$SSH_CONFIG"
        fi
        
        # Remove old entry if exists
        sed -i.bak "/^Host pi${system_num}/,/^Host /d" "$SSH_CONFIG" 2>/dev/null
        sed -i.bak "/^Host pi${system_num}$/d" "$SSH_CONFIG" 2>/dev/null
        
        # Add new entry
        cat >> "$SSH_CONFIG" << EOF

Host pi${system_num}
    HostName $ip
    User $user
    StrictHostKeyChecking no
    ConnectTimeout 5
    IdentityFile ~/.ssh/id_rsa

EOF
        echo -e "${GREEN}✅ Added to SSH config (use: ssh pi${system_num})${NC}"
    else
        echo -e "${RED}❌ SSH connection failed${NC}"
        echo ""
        return 1
    fi
    
    echo ""
    return 0
}

# Setup System 1: HiFiBerryOS Pi 4
setup_ssh 1 "$SYSTEM1_IP" "$SYSTEM1_USER" "$SYSTEM1_PASS" "$SYSTEM1_NAME"

# Setup System 2: moOde Pi 5
setup_ssh 2 "$SYSTEM2_IP" "$SYSTEM2_USER" "$SYSTEM2_PASS" "$SYSTEM2_NAME"

# Setup System 3: moOde Pi 4
SYSTEM3_IP=$(ping -c 1 -W 2000 "$SYSTEM3_HOSTNAME" 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)
if [ -n "$SYSTEM3_IP" ]; then
    setup_ssh 3 "$SYSTEM3_IP" "$SYSTEM3_USER" "$SYSTEM3_PASS" "$SYSTEM3_NAME"
    # Save IP for pi4-ssh.sh
    echo "$SYSTEM3_IP" > .pi4_ip
    echo -e "${GREEN}✅ Saved Pi 4 IP: $SYSTEM3_IP${NC}"
else
    echo "=========================================="
    echo "System 3: $SYSTEM3_NAME"
    echo "=========================================="
    echo -e "${RED}❌ Cannot resolve $SYSTEM3_HOSTNAME${NC}"
    echo "Trying direct IP (192.168.178.122)..."
    if ping -c 1 -W 2000 192.168.178.122 >/dev/null 2>&1; then
        setup_ssh 3 "192.168.178.122" "$SYSTEM3_USER" "$SYSTEM3_PASS" "$SYSTEM3_NAME"
        echo "192.168.178.122" > .pi4_ip
    else
        echo -e "${RED}❌ System 3 offline${NC}"
    fi
    echo ""
fi

# Update helper scripts to use SSH config
echo "=========================================="
echo "Updating helper scripts..."
echo "=========================================="

# Update pi5-ssh.sh to use SSH config
if [ -f "./pi5-ssh.sh" ]; then
    # Backup
    cp pi5-ssh.sh pi5-ssh.sh.backup
    
    # Check if already using config
    if ! grep -q "pi2" pi5-ssh.sh; then
        # Update to use SSH config
        sed -i.bak 's|ssh $SSH_OPTS "$PI5_USER@$PI5_IP"|ssh pi2|g' pi5-ssh.sh 2>/dev/null || true
        echo -e "${GREEN}✅ Updated pi5-ssh.sh${NC}"
    else
        echo -e "${GREEN}✅ pi5-ssh.sh already configured${NC}"
    fi
fi

# Update pi4-ssh.sh to use SSH config
if [ -f "./pi4-ssh.sh" ]; then
    # Backup
    cp pi4-ssh.sh pi4-ssh.sh.backup
    
    # Check if already using config
    if ! grep -q "pi3" pi4-ssh.sh; then
        # Update to use SSH config
        sed -i.bak 's|ssh $SSH_OPTS "$PI4_USER@$PI4_IP"|ssh pi3|g' pi4-ssh.sh 2>/dev/null || true
        echo -e "${GREEN}✅ Updated pi4-ssh.sh${NC}"
    else
        echo -e "${GREEN}✅ pi4-ssh.sh already configured${NC}"
    fi
fi

echo ""
echo "=========================================="
echo "SETUP COMPLETE"
echo "=========================================="
echo ""
echo "You can now use:"
echo "  ssh pi1  # HiFiBerryOS Pi 4"
echo "  ssh pi2  # moOde Pi 5"
echo "  ssh pi3  # moOde Pi 4"
echo ""
echo "Or use helper scripts:"
echo "  ./pi5-ssh.sh 'command'"
echo "  ./pi4-ssh.sh 'command'"
echo ""
echo -e "${GREEN}✅ SSH setup is now permanent!${NC}"
echo ""

