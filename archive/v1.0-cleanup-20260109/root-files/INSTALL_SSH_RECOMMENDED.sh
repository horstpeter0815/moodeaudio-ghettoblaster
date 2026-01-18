#!/bin/bash
################################################################################
# INSTALL SSH - RECOMMENDED METHOD
# 
# This is a wrapper script that calls the recommended SSH installation script.
# Based on analysis, install-independent-ssh-sd-card.sh provides the best
# balance of features, error handling, and reliability.
#
# Usage: ./INSTALL_SSH_RECOMMENDED.sh
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECOMMENDED_SCRIPT="$SCRIPT_DIR/install-independent-ssh-sd-card.sh"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 INSTALL SSH - RECOMMENDED METHOD                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will run the recommended SSH installation:"
echo "  → install-independent-ssh-sd-card.sh"
echo ""
echo "Why this script?"
echo "  ✅ Best error handling"
echo "  ✅ Comprehensive verification"
echo "  ✅ Multiple redundancy layers"
echo "  ✅ Works on both Pi 4 and Pi 5"
echo ""
echo "For other options, see:"
echo "  - SSH_STANDARD_MOODE_COMPLETE_GUIDE.md"
echo "  - SSH_SCRIPTS_COMPARISON.md"
echo ""

if [ ! -f "$RECOMMENDED_SCRIPT" ]; then
    echo "❌ Error: Recommended script not found: $RECOMMENDED_SCRIPT"
    exit 1
fi

# Make sure script is executable
chmod +x "$RECOMMENDED_SCRIPT" 2>/dev/null || true

# Run the recommended script
exec "$RECOMMENDED_SCRIPT" "$@"

