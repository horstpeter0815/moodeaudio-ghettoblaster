#!/bin/bash
################################################################################
#
# DEPLOY DISPLAY FIXES TO MOODE SYSTEM
#
# Deploys all display-related fix scripts to the running moOde system
#
# Usage: ./deploy-display-fixes.sh [moode-hostname-or-ip]
#
################################################################################

set -e

MOODE_HOST="${1:-moode}"

# Find project directory (moodeaudio-cursor) - works from home directory or anywhere
if [ -d "$HOME/moodeaudio-cursor" ]; then
    PROJECT_DIR="$HOME/moodeaudio-cursor"
elif [ -d "moodeaudio-cursor" ]; then
    PROJECT_DIR="$(cd moodeaudio-cursor && pwd)"
elif [ -d ".git" ] || [ -f "README.md" ] || [ -d "custom-components" ]; then
    PROJECT_DIR="$(pwd)"
else
    echo "❌ ERROR: Cannot find moodeaudio-cursor project directory"
    echo "   Please run from home directory or project root"
    exit 1
fi

echo "🚀 DEPLOYING DISPLAY FIXES TO $MOODE_HOST"
echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Check if scripts exist
SCRIPTS=(
    "custom-components/scripts/fix-display-toggle.sh"
    "custom-components/scripts/fix-display-black.sh"
    "custom-components/scripts/diagnose-display-black.sh"
    "custom-components/scripts/force-restart-chromium.sh"
    "custom-components/scripts/fix-xinitrc-syntax.sh"
)

echo "📋 Checking scripts..."
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$PROJECT_DIR/$script" ]; then
        echo "❌ ERROR: Script not found: $PROJECT_DIR/$script"
        exit 1
    fi
    echo "   ✅ $script"
done
echo ""

# Deploy scripts
echo "📦 Deploying scripts to $MOODE_HOST..."
for script in "${SCRIPTS[@]}"; do
    script_name=$(basename "$script")
    echo "   Deploying $script_name..."
    scp "$PROJECT_DIR/$script" "$MOODE_HOST:/tmp/" || {
        echo "❌ ERROR: Failed to copy $script_name"
        exit 1
    }
    ssh "$MOODE_HOST" "sudo mv /tmp/$script_name /usr/local/bin/ && sudo chmod +x /usr/local/bin/$script_name" || {
        echo "❌ ERROR: Failed to install $script_name"
        exit 1
    }
    echo "   ✅ $script_name installed"
done
echo ""

# Run diagnosis first
echo "🔍 Running diagnosis..."
ssh "$MOODE_HOST" "sudo /usr/local/bin/diagnose-display-black.sh" || echo "⚠️  Diagnosis completed with warnings"
echo ""

# Show diagnosis results
echo "📊 Diagnosis results:"
ssh "$MOODE_HOST" "sudo tail -30 /var/log/diagnose-display-black.log" || echo "⚠️  Could not read diagnosis log"
echo ""

# Fix .xinitrc syntax error first
echo "🔧 Fixing .xinitrc syntax error..."
ssh "$MOODE_HOST" "sudo /usr/local/bin/fix-xinitrc-syntax.sh" || {
    echo "⚠️  .xinitrc fix completed with warnings"
}
echo ""

# Run the fix automatically (non-interactive)
echo "🔧 Running fix-display-black.sh..."
ssh "$MOODE_HOST" "sudo /usr/local/bin/fix-display-black.sh" || {
    echo "⚠️  Fix completed with warnings, check logs"
}
echo ""
echo "📊 Fix results:"
ssh "$MOODE_HOST" "sudo tail -30 /var/log/fix-display-black.log" 2>/dev/null || echo "⚠️  Could not read fix log"
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "   - Check display on Bose radio"
echo "   - View full logs: ssh $MOODE_HOST 'sudo cat /var/log/fix-display-black.log'"
echo "   - Check service: ssh $MOODE_HOST 'systemctl status localdisplay.service'"
echo "   - If still black, try: ssh $MOODE_HOST 'sudo /usr/local/bin/force-restart-chromium.sh'"

echo ""
echo "✅ Scripts deployed successfully!"

