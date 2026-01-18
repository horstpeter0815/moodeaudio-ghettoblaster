#!/bin/bash
# Cleanup v1.0 Development Data
# Removes all development/test/experimental data now that v1.0 is complete
# KEEPS: Production configs, documentation, source code, tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧹 V1.0 DEVELOPMENT DATA CLEANUP                             ║"
echo "║  Removing all development/test/experimental data             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: This will remove development data!"
echo "✅ KEEPS: Production configs, docs, source, tools"
echo ""

read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

CLEANED=0
SKIPPED=0

clean_item() {
    local item=$1
    local reason=$2
    if [ -e "$item" ]; then
        echo -e "${YELLOW}Removing:${NC} $item ($reason)"
        rm -rf "$item"
        CLEANED=$((CLEANED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi
}

# 1. Simulation/Test Directories
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Removing simulation/test directories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SIM_DIRS=(
    "complete-sim-boot"
    "complete-sim-logs"
    "complete-sim-moode"
    "complete-sim-test"
    "system-sim-boot"
    "system-sim-logs"
    "system-sim-moode"
    "system-sim-test"
    "pi-sim-test"
    "network-test"
    "network-test-boot"
    "network-test-logs"
    "forum-solution-sim"
)

for dir in "${SIM_DIRS[@]}"; do
    clean_item "$dir" "simulation/test directory"
done

echo ""

# 2. Archive/Temp Directories (old development data)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Removing old archive/temp directories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ARCHIVE_DIRS=(
    "temp-archive-20251207"
    "parallel-work-logs"
    "serial-logs"
)

for dir in "${ARCHIVE_DIRS[@]}"; do
    clean_item "$dir" "old archive/temp directory"
done

echo ""

# 3. Old Documentation (development notes)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Removing old development documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OLD_DOCS=(
    "IMPORTANT_INSIGHTS_RECOVERY.md"
    "ROOT_CAUSE_FIXES.md"
    "ALL_OVERWRITE_MECHANISMS_FOUND.md"
    "PI_GEN_OVERRIDE_MECHANISMS.md"
    "EXTFS_USER_CREATION.md"
    "EXTFS_WRITE_ACCESS_NEEDED.md"
    "EXTFS_WRITE_INSTRUCTIONS.md"
    "USERID_PROBLEM_EXPLAINED.md"
    "COMMANDS_FROM_HOME.md"
    "SCRIPT_INVENTORY.md"
    "ALL_SHELL_SCRIPTS_LIST.md"
    "SHELL_SCRIPT_SEARCH_RESULTS.md"
)

for doc in "${OLD_DOCS[@]}"; do
    clean_item "$doc" "old development documentation"
done

echo ""

# 4. Old Fix Scripts (development attempts)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Removing old fix attempt scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OLD_FIX_SCRIPTS=(
    "FIX_MAC_NETWORK_FOR_PI.sh"
    "FIX_MOODE_10.0.3_DOWNLOADED.sh"
    "FIX_NETWORK_AND_USB.sh"
    "FIX_PI_ONLINE.sh"
    "FIX_RUNNING_PI_INSTRUCTIONS.md"
    "FIX_RUNNING_PI_NOW.sh"
    "FIX_SD_CARD_COMMANDS.txt"
    "FIX_SD_CARD_ON_MAC.sh"
    "FIX_WEBUI_LOADING.sh"
    "pi5-ssh.sh.backup"
    "INTEGRATE_CUSTOM_COMPONENTS.sh.bak2"
)

for script in "${OLD_FIX_SCRIPTS[@]}"; do
    clean_item "$script" "old fix attempt script"
done

echo ""

# 5. Test/Validation Files (can be regenerated)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Removing test/validation files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TEST_FILES=(
    "complete_test_suite.sh"
    "fix-database-orientation.sql"
    "Test_Playlist.m3u"
    "browser-deploy.js"
    "deploy-auto.exp"
)

for file in "${TEST_FILES[@]}"; do
    clean_item "$file" "test/validation file"
done

echo ""

# 6. Old Status/Progress Files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Removing old status/progress files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS_FILES=(
    "QUICK_COMMAND.md"
    "QUICK_REFERENCE.md"
    "README_FROM_HOME.md"
    "HOW_TO_SHARE_DOCUMENTATION.md"
    "IPHONE_MICROPHONE_PERMISSIONS.md"
)

for file in "${STATUS_FILES[@]}"; do
    clean_item "$file" "old status file"
done

echo ""

# 7. Wizard Backup (now integrated)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Removing wizard backup (now in main code)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "wizard-backup" ]; then
    clean_item "wizard-backup" "backup directory (now integrated)"
fi

echo ""

# 8. Docker Test Containers (if not needed)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Checking Docker test files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Keep docker-compose files but note they're for testing
echo "  ℹ️  Docker compose files kept (may be needed for future testing)"
echo ""

# 9. Old Build Artifacts (keep recent, remove very old)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9. Checking for old build artifacts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Keep imgbuild directory (needed for building)
# But remove any very old build logs in root
find . -maxdepth 1 -type f -name "*.dmg" -mtime +30 2>/dev/null | while read file; do
    clean_item "$file" "old build artifact"
done

echo ""

# 10. Clean up empty directories created during development
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "10. Cleaning up empty development directories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

find . -type d -empty -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./moode-source/*" -not -path "./imgbuild/*" 2>/dev/null | while read dir; do
    if [ "$dir" != "." ] && [[ ! "$dir" =~ ^\./docs ]] && [[ ! "$dir" =~ ^\./scripts ]] && [[ ! "$dir" =~ ^\./tools ]]; then
        rmdir "$dir" 2>/dev/null && CLEANED=$((CLEANED + 1)) || true
    fi
done

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 CLEANUP SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Cleaned:${NC} $CLEANED items"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED items"
echo ""

# What was kept
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PRESERVED (Important):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ moode-source/ (production source code)"
echo "  ✅ imgbuild/ (build system)"
echo "  ✅ tools/ (toolbox)"
echo "  ✅ scripts/ (production scripts)"
echo "  ✅ docs/ (documentation)"
echo "  ✅ custom-components/ (custom components)"
echo "  ✅ rag-upload-files/ (AI training data)"
echo "  ✅ docker-compose.*.yml (may be needed)"
echo "  ✅ All configuration files"
echo ""

echo -e "${GREEN}✅ V1.0 Development Data Cleanup Complete!${NC}"
echo ""
echo "The project now contains only production-ready code and documentation."
echo ""
