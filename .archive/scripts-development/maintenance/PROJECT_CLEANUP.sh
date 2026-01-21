#!/bin/bash
# Project Cleanup Script
# Removes temp files, organizes archives, consolidates documentation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧹 PROJECT CLEANUP                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLEANED=0
SKIPPED=0

clean_file() {
    local file=$1
    local reason=$2
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo -e "${YELLOW}Removing:${NC} $file ($reason)"
        rm -rf "$file"
        CLEANED=$((CLEANED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi
}

# 1. Clean temporary files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Cleaning temporary files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Temp files in root
find . -maxdepth 1 -type f \( -name "*.tmp" -o -name "*.log" -o -name "*.bak" -o -name "*.swp" -o -name "*~" \) -not -path "./.git/*" | while read file; do
    clean_file "$file" "temporary file"
done

# Test files that can be regenerated
clean_file "test-wizard-logic-check.js" "test file (can be regenerated)"
clean_file "test-wizard-structure-check.js" "test file (can be regenerated)"

echo ""

# 2. Organize old documentation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Organizing documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create archive directory if it doesn't exist
ARCHIVE_DIR="$PROJECT_ROOT/docs/archive/old-docs-$(date +%Y%m%d)"
if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir -p "$ARCHIVE_DIR"
fi

# Move old status/progress files to archive
OLD_DOCS=(
    "CLEANUP_PROGRESS.md"
    "CLEANUP_SUMMARY.md"
    "CLEANUP_COMPLETE_REPORT.md"
    "CLEANUP_BUILDS_QUICK.md"
    "PROBLEM_FOUND.md"
    "PI_NOT_FOUND_YET.md"
    "WHAT_TO_DO_NOW.md"
    "WHAT_WE_NEED.md"
    "RUN_THIS_NOW.md"
    "READY_TO_BOOT.md"
    "REBOOT_AND_TEST_AUDIO.md"
    "LAST_TWO_WEEKS_SUMMARY.md"
)

for doc in "${OLD_DOCS[@]}"; do
    if [ -f "$PROJECT_ROOT/$doc" ]; then
        echo -e "${YELLOW}Archiving:${NC} $doc"
        mv "$PROJECT_ROOT/$doc" "$ARCHIVE_DIR/"
        CLEANED=$((CLEANED + 1))
    fi
done

echo ""

# 3. Consolidate duplicate scripts (identify, don't delete yet)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Identifying duplicate scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DUPLICATES_FILE="$PROJECT_ROOT/docs/DUPLICATE_SCRIPTS.md"
cat > "$DUPLICATES_FILE" << 'EOF'
# Duplicate Scripts Analysis

This file identifies potential duplicate scripts that could be consolidated.

## Display Fix Scripts
Many display fix scripts exist with similar functionality:
- Multiple `fix-display-*.sh` variants
- Multiple `FIX_DISPLAY*.sh` variants
- Consider consolidating into one main script with options

## Build Scripts
- Multiple build monitoring scripts
- Consider using one script with parameters

## Test Scripts
- Multiple test variants
- Consider test suite approach

**Note:** Review before deletion - some may have specific use cases.
EOF

echo -e "${GREEN}Created:${NC} $DUPLICATES_FILE"
echo ""

# 4. Clean empty directories
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Cleaning empty directories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

find . -type d -empty -not -path "./.git/*" -not -path "./node_modules/*" | while read dir; do
    if [ "$dir" != "." ]; then
        echo -e "${YELLOW}Removing empty directory:${NC} $dir"
        rmdir "$dir" 2>/dev/null && CLEANED=$((CLEANED + 1)) || SKIPPED=$((SKIPPED + 1))
    fi
done

echo ""

# 5. Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 CLEANUP SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Cleaned:${NC} $CLEANED items"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED items"
echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "Archived files moved to: $ARCHIVE_DIR"
echo ""
