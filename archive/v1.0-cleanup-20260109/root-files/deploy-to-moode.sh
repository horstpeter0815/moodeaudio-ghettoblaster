#!/bin/bash
# Deploy Room Correction Wizard to moOde system
# Usage: ./deploy-to-moode.sh [moode-ip]

MOODE_IP="${1:-10.10.11.39}"
MOODE_USER="${2:-pi}"  # Use 'pi' as default (moOde standard user)
MOODE_WEB_ROOT="/var/www/html"
MOODE_COMMAND_DIR="/var/www/html/command"
MAX_RETRIES=3
RETRY_DELAY=2
SSH_KEY="${HOME}/.ssh/id_rsa_moode"

# Use SSH key if it exists, otherwise use password authentication
if [ -f "$SSH_KEY" ]; then
    SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"
else
    SSH_OPTS="-o StrictHostKeyChecking=no"
fi

echo "[DEPLOY] Deploying Room Correction Wizard to moOde system at $MOODE_IP"
echo ""

# Retry function for SSH/SCP commands
retry_command() {
    local cmd="$1"
    local description="$2"
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "  Attempt $attempt/$MAX_RETRIES: $description"
        if eval "$cmd"; then
            echo "  [OK] Success!"
            return 0
        else
            if [ $attempt -lt $MAX_RETRIES ]; then
                echo "  [WARN] Failed, retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
            else
                echo "  [ERROR] Failed after $MAX_RETRIES attempts"
                return 1
            fi
        fi
        attempt=$((attempt + 1))
    done
    return 1
}

# Check if SSH is available
if ! command -v ssh &> /dev/null; then
    echo "[ERROR] ssh command not found"
    exit 1
fi

# Check if files exist
if [ ! -f "test-wizard/index-simple.html" ]; then
    echo "[ERROR] test-wizard/index-simple.html not found"
    exit 1
fi

if [ ! -f "test-wizard/wizard-functions.js" ]; then
    echo "[ERROR] test-wizard/wizard-functions.js not found"
    exit 1
fi

if [ ! -f "test-wizard/snd-config.html" ]; then
    echo "[ERROR] test-wizard/snd-config.html not found"
    exit 1
fi

if [ ! -f "moode-source/www/command/room-correction-wizard.php" ]; then
    echo "[ERROR] moode-source/www/command/room-correction-wizard.php not found"
    exit 1
fi

echo "[OK] All required files found"
echo ""

# Test SSH connection first
echo "[TEST] Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $MOODE_USER@$MOODE_IP "echo 'SSH OK'" 2>/dev/null; then
    echo "[INFO] SSH password authentication required"
    echo "[INFO] You will be prompted for password multiple times during deployment"
    echo ""
fi

# Create deployment directory structure on remote
echo "[DIR] Creating directory structure on moOde system..."
if ! retry_command "ssh $SSH_OPTS $MOODE_USER@$MOODE_IP 'sudo mkdir -p $MOODE_WEB_ROOT/test-wizard && sudo mkdir -p $MOODE_COMMAND_DIR && sudo chown -R www-data:www-data $MOODE_WEB_ROOT/test-wizard $MOODE_COMMAND_DIR'" "Creating directories"; then
    echo "[ERROR] Failed to create directories"
    exit 1
fi

# Copy frontend files
echo "[COPY] Copying frontend files..."
if ! retry_command "scp $SSH_OPTS test-wizard/index-simple.html $MOODE_USER@$MOODE_IP:/tmp/index-simple.html" "Copying index-simple.html"; then
    echo "[ERROR] Failed to copy index-simple.html"
    exit 1
fi

if ! retry_command "scp $SSH_OPTS test-wizard/wizard-functions.js $MOODE_USER@$MOODE_IP:/tmp/wizard-functions.js" "Copying wizard-functions.js"; then
    echo "[ERROR] Failed to copy wizard-functions.js"
    exit 1
fi

if ! retry_command "scp $SSH_OPTS test-wizard/snd-config.html $MOODE_USER@$MOODE_IP:/tmp/snd-config.html" "Copying snd-config.html"; then
    echo "[ERROR] Failed to copy snd-config.html"
    exit 1
fi

# Copy backend file
echo "[COPY] Copying backend file..."
if ! retry_command "scp $SSH_OPTS moode-source/www/command/room-correction-wizard.php $MOODE_USER@$MOODE_IP:/tmp/room-correction-wizard.php" "Copying room-correction-wizard.php"; then
    echo "[ERROR] Failed to copy room-correction-wizard.php"
    exit 1
fi

# Move files to correct locations with sudo
echo "[INSTALL] Installing files..."
if ! retry_command "ssh $SSH_OPTS $MOODE_USER@$MOODE_IP 'sudo mv /tmp/index-simple.html $MOODE_WEB_ROOT/index-simple.html && sudo mv /tmp/wizard-functions.js $MOODE_WEB_ROOT/test-wizard/wizard-functions.js && sudo mv /tmp/snd-config.html $MOODE_WEB_ROOT/test-wizard/snd-config.html && sudo mv /tmp/room-correction-wizard.php $MOODE_COMMAND_DIR/room-correction-wizard.php'" "Moving files to final locations"; then
    echo "[ERROR] Failed to move files"
    exit 1
fi

# Set permissions
echo "[PERM] Setting permissions..."
if ! retry_command "ssh $SSH_OPTS $MOODE_USER@$MOODE_IP 'sudo chown www-data:www-data $MOODE_WEB_ROOT/index-simple.html $MOODE_WEB_ROOT/test-wizard/* $MOODE_COMMAND_DIR/room-correction-wizard.php && sudo chmod 644 $MOODE_WEB_ROOT/index-simple.html $MOODE_WEB_ROOT/test-wizard/* $MOODE_COMMAND_DIR/room-correction-wizard.php'" "Setting permissions"; then
    echo "[ERROR] Failed to set permissions"
    exit 1
fi

echo ""
echo "[OK] Deployment complete!"
echo ""
echo "Access the wizard at:"
echo "  https://$MOODE_IP:8443/index-simple.html"
echo ""
echo "Note: You may need to enter SSH password during deployment"

