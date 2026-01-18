#!/bin/bash
# Preview what will be deleted in v1.0 cleanup
# Shows what will be removed without actually deleting

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  👀 V1.0 CLEANUP PREVIEW                                     ║"
echo "║  Shows what will be deleted (no changes made)               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_SIZE=0
TOTAL_ITEMS=0

check_item() {
    local item=$1
    local reason=$2
    if [ -e "$item" ]; then
        if [ -d "$item" ]; then
            SIZE=$(du -sh "$item" 2>/dev/null | awk '{print $1}')
            COUNT=$(find "$item" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo -e "${YELLOW}📁 $item${NC}"
            echo "     Size: $SIZE | Files: $COUNT | Reason: $reason"
            TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
        else
            SIZE=$(ls -lh "$item" 2>/dev/null | awk '{print $5}')
            echo -e "${YELLOW}📄 $item${NC}"
            echo "     Size: $SIZE | Reason: $reason"
            TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
        fi
    fi
}

# 1. Simulation/Test Directories
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Simulation/Test Directories"
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
    check_item "$dir" "simulation/test directory"
done

echo ""

# 2. Archive/Temp Directories
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Archive/Temp Directories"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ARCHIVE_DIRS=(
    "temp-archive-20251207"
    "parallel-work-logs"
    "serial-logs"
    "temp"
)

for dir in "${ARCHIVE_DIRS[@]}"; do
    check_item "$dir" "old archive/temp directory"
done

echo ""

# 3. Old Documentation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Old Development Documentation"
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
    check_item "$doc" "old development documentation"
done

echo ""

# 4. Old Fix Scripts
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Old Fix Attempt Scripts"
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
    check_item "$script" "old fix attempt script"
done

echo ""

# 5. Test/Validation Files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Test/Validation Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TEST_FILES=(
    "complete_test_suite.sh"
    "fix-database-orientation.sql"
    "Test_Playlist.m3u"
    "browser-deploy.js"
    "deploy-auto.exp"
    "serial-monitor-20251210_011222.log.serial"
)

for file in "${TEST_FILES[@]}"; do
    check_item "$file" "test/validation file"
done

echo ""

# 6. Old Status Files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Old Status/Progress Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS_FILES=(
    "QUICK_COMMAND.md"
    "QUICK_REFERENCE.md"
    "README_FROM_HOME.md"
    "HOW_TO_SHARE_DOCUMENTATION.md"
    "IPHONE_MICROPHONE_PERMISSIONS.md"
)

for file in "${STATUS_FILES[@]}"; do
    check_item "$file" "old status file"
done

echo ""

# 7. Wizard Backup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Wizard Backup (now integrated)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_item "wizard-backup" "backup directory (now integrated)"

echo ""

# 8. Old Build Artifacts
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Old Build Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OLD_BUILDS=(
    "901HBOS.dmg"
    "hifiberryos pi4 wave.dmg"
)

for build in "${OLD_BUILDS[@]}"; do
    check_item "$build" "old build artifact"
done

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 PREVIEW SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Total items to delete:${NC} $TOTAL_ITEMS"
echo ""
echo -e "${GREEN}✅ WILL BE PRESERVED:${NC}"
echo "  ✅ moode-source/ (production source)"
echo "  ✅ imgbuild/ (build system)"
echo "  ✅ tools/ (toolbox)"
echo "  ✅ scripts/ (production scripts)"
echo "  ✅ docs/ (documentation)"
echo "  ✅ custom-components/ (custom components)"
echo "  ✅ rag-upload-files/ (AI training)"
echo "  ✅ All configuration files"
echo "  ✅ All working documentation"
echo ""
echo "To execute cleanup, run:"
echo "  ./scripts/maintenance/CLEANUP_V1.0_DEVELOPMENT_DATA.sh"
echo ""
