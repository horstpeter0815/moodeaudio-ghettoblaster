#!/bin/bash
# Deploy Room Correction Wizard to Running Pi
# Date: 2026-01-18
# Target: Pi 5 Ghettoblaster (192.168.2.1)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Room Correction Wizard - Deploy to Pi"
echo "========================================"
echo ""

# Configuration
PI_IP="192.168.2.3"
PI_USER="andre"
PI_PASSWORD="0815"  # You'll enter this when prompted

# Workspace paths (where we are now)
WORKSPACE_ROOT="/Users/andrevollmer/moodeaudio-cursor"
MOODE_SOURCE="${WORKSPACE_ROOT}/moode-source"
CUSTOM_COMPONENTS="${WORKSPACE_ROOT}/custom-components"

# Target paths on Pi
PI_WEB_ROOT="/var/www/html"
PI_BIN="/usr/local/bin"
PI_CAMILLA_LIB="/var/lib/camilladsp"

# Verify workspace files exist
echo "=== Checking workspace files ==="

FILES_TO_DEPLOY=(
    "${MOODE_SOURCE}/www/command/room-correction-wizard.php"
    "${CUSTOM_COMPONENTS}/templates/room-correction-wizard-modal.html"
    "${MOODE_SOURCE}/usr/local/bin/generate-camilladsp-eq.py"
    "${MOODE_SOURCE}/usr/local/bin/analyze-measurement.py"
)

MISSING_FILES=0
for file in "${FILES_TO_DEPLOY[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Found: $(basename $file)"
    else
        echo "❌ Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ ERROR: $MISSING_FILES files missing!${NC}"
    exit 1
fi

echo ""
echo "=== Deployment Plan ==="
echo "Target: ${PI_USER}@${PI_IP}"
echo ""
echo "Files to copy:"
echo "1. room-correction-wizard.php     → ${PI_WEB_ROOT}/command/"
echo "2. room-correction-wizard-modal.html → ${PI_WEB_ROOT}/templates/"
echo "3. generate-camilladsp-eq.py      → ${PI_BIN}/"
echo "4. analyze-measurement.py         → ${PI_BIN}/"
echo ""
echo "Directories to create (if missing):"
echo "- ${PI_CAMILLA_LIB}/measurements"
echo "- ${PI_CAMILLA_LIB}/convolution"
echo "- ${PI_CAMILLA_LIB}/configs"
echo ""

# Ask for confirmation
read -p "Continue with deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "=== Starting Deployment ==="
echo ""

# Function to copy file to Pi with sudo
copy_to_pi() {
    local LOCAL_FILE="$1"
    local REMOTE_PATH="$2"
    local FILENAME=$(basename "$LOCAL_FILE")
    
    echo -n "Copying ${FILENAME}... "
    
    # Copy to tmp first, then move with sudo
    scp -q "$LOCAL_FILE" "${PI_USER}@${PI_IP}:/tmp/${FILENAME}" || {
        echo -e "${RED}FAILED${NC}"
        return 1
    }
    
    ssh "${PI_USER}@${PI_IP}" "sudo mv /tmp/${FILENAME} ${REMOTE_PATH}/ && sudo chown www-data:www-data ${REMOTE_PATH}/${FILENAME}" || {
        echo -e "${RED}FAILED${NC}"
        return 1
    }
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

# Function to run command on Pi
run_on_pi() {
    local CMD="$1"
    ssh "${PI_USER}@${PI_IP}" "$CMD"
}

# Create directories on Pi
echo "=== Creating directories on Pi ==="
run_on_pi "sudo mkdir -p ${PI_CAMILLA_LIB}/measurements ${PI_CAMILLA_LIB}/convolution ${PI_CAMILLA_LIB}/configs"
run_on_pi "sudo chown -R www-data:www-data ${PI_CAMILLA_LIB}"
run_on_pi "sudo mkdir -p ${PI_WEB_ROOT}/command ${PI_WEB_ROOT}/templates"
echo -e "${GREEN}✅ Directories created${NC}"
echo ""

# Deploy PHP backend
echo "=== Deploying PHP backend ==="
copy_to_pi "${MOODE_SOURCE}/www/command/room-correction-wizard.php" "${PI_WEB_ROOT}/command"
run_on_pi "sudo chmod 644 ${PI_WEB_ROOT}/command/room-correction-wizard.php"
echo ""

# Deploy HTML template
echo "=== Deploying HTML template ==="
copy_to_pi "${CUSTOM_COMPONENTS}/templates/room-correction-wizard-modal.html" "${PI_WEB_ROOT}/templates"
run_on_pi "sudo chmod 644 ${PI_WEB_ROOT}/templates/room-correction-wizard-modal.html"
echo ""

# Deploy Python scripts
echo "=== Deploying Python scripts ==="
copy_to_pi "${MOODE_SOURCE}/usr/local/bin/generate-camilladsp-eq.py" "${PI_BIN}"
run_on_pi "sudo chmod +x ${PI_BIN}/generate-camilladsp-eq.py"

copy_to_pi "${MOODE_SOURCE}/usr/local/bin/analyze-measurement.py" "${PI_BIN}"
run_on_pi "sudo chmod +x ${PI_BIN}/analyze-measurement.py"
echo ""

# Verify Python dependencies
echo "=== Verifying Python dependencies ==="
REQUIRED_PACKAGES="scipy numpy soundfile"
MISSING_PACKAGES=""

for pkg in $REQUIRED_PACKAGES; do
    echo -n "Checking python3-${pkg}... "
    if run_on_pi "python3 -c 'import ${pkg}' 2>/dev/null"; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}MISSING${NC}"
        MISSING_PACKAGES="${MISSING_PACKAGES} python3-${pkg}"
    fi
done

if [ -n "$MISSING_PACKAGES" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Missing Python packages:${MISSING_PACKAGES}${NC}"
    echo ""
    read -p "Install missing packages now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing packages..."
        run_on_pi "sudo apt-get update && sudo apt-get install -y ${MISSING_PACKAGES}"
        echo -e "${GREEN}✅ Packages installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Wizard may not work without these packages!${NC}"
    fi
fi
echo ""

# Verify deployment
echo "=== Verifying deployment ==="
echo ""
echo "Checking files on Pi:"

FILES_CHECK=(
    "${PI_WEB_ROOT}/command/room-correction-wizard.php"
    "${PI_WEB_ROOT}/templates/room-correction-wizard-modal.html"
    "${PI_BIN}/generate-camilladsp-eq.py"
    "${PI_BIN}/analyze-measurement.py"
    "${PI_CAMILLA_LIB}/measurements"
)

VERIFY_FAILED=0
for file in "${FILES_CHECK[@]}"; do
    echo -n "Checking $(basename $file)... "
    if run_on_pi "[ -e $file ]"; then
        echo -e "${GREEN}EXISTS${NC}"
    else
        echo -e "${RED}MISSING${NC}"
        VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
done

echo ""
if [ $VERIFY_FAILED -gt 0 ]; then
    echo -e "${RED}❌ Verification failed! $VERIFY_FAILED files missing.${NC}"
    exit 1
fi

# Success!
echo ""
echo "========================================"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Open moOde web interface:"
echo "   http://${PI_IP}/"
echo ""
echo "2. Navigate to: Audio → Sound Config"
echo "   Look for 'Room Correction' button"
echo ""
echo "3. Click 'Run Wizard' to start"
echo ""
echo "4. To manually test the wizard backend:"
echo "   curl http://${PI_IP}/command/room-correction-wizard.php -d 'cmd=start_wizard'"
echo ""
echo "Wizard files deployed:"
echo "  - PHP backend:    ${PI_WEB_ROOT}/command/room-correction-wizard.php"
echo "  - HTML template:  ${PI_WEB_ROOT}/templates/room-correction-wizard-modal.html"
echo "  - Python scripts: ${PI_BIN}/generate-camilladsp-eq.py"
echo "  - Python scripts: ${PI_BIN}/analyze-measurement.py"
echo "  - Data directory: ${PI_CAMILLA_LIB}/measurements/"
echo ""
echo "Done! 🎉"
