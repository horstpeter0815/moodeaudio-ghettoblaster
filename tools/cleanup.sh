#!/bin/bash
################################################################################
#
# SYSTEM CLEANUP v1.0
# 
# Archives temporary fix scripts, status docs, and cleans up root directory
# Keeps only essential files for v1.0
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[CLEANUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

ARCHIVE_BASE="archive/v1.0-cleanup-$(date +%Y%m%d)"
ARCHIVE_SCRIPTS="$ARCHIVE_BASE/scripts"
ARCHIVE_DOCS="$ARCHIVE_BASE/docs"
ARCHIVE_ROOT="$ARCHIVE_BASE/root-files"
ARCHIVE_BUILDS="$ARCHIVE_BASE/builds"

log "=== SYSTEM CLEANUP v1.0 ==="
log "Archive location: $ARCHIVE_BASE"
echo ""

# Create archive structure
mkdir -p "$ARCHIVE_SCRIPTS"/{temporary-fixes,deployment-fixes}
mkdir -p "$ARCHIVE_DOCS"/{status,complete,final,next-steps}
mkdir -p "$ARCHIVE_ROOT"
mkdir -p "$ARCHIVE_BUILDS"

COUNT=0

# 1. Archive temporary fix scripts from root
log "Step 1: Archiving temporary fix scripts from root..."
for script in FIX_*.sh fix-*.sh; do
    if [ -f "$script" ]; then
        mv "$script" "$ARCHIVE_SCRIPTS/temporary-fixes/" && ((COUNT++))
    fi
done
log "Archived $COUNT root fix scripts"

# 2. Archive fix scripts from scripts/ directory
log "Step 2: Archiving fix scripts from scripts/..."
COUNT=0
find scripts/ -type f \( -name "FIX_*.sh" -o -name "fix-*.sh" \) ! -path "*/fix-audio-chain.sh" | while read script; do
    mv "$script" "$ARCHIVE_SCRIPTS/temporary-fixes/" && ((COUNT++))
done
log "Archived fix scripts from scripts/"

# 3. Archive scripts/fixes/ directory (all temporary fixes)
if [ -d "scripts/fixes" ]; then
    log "Step 3: Archiving scripts/fixes/ directory..."
    mv scripts/fixes "$ARCHIVE_SCRIPTS/temporary-fixes/scripts-fixes" && ((COUNT++))
    log "Archived scripts/fixes/ directory"
fi

# 4. Archive deployment fix scripts
log "Step 4: Archiving deployment fix scripts..."
COUNT=0
find scripts/deployment/ -type f -name "*FIX*.sh" -o -name "*fix*.sh" | while read script; do
    mv "$script" "$ARCHIVE_SCRIPTS/deployment-fixes/" && ((COUNT++))
done
log "Archived deployment fix scripts"

# 5. Archive status documentation
log "Step 5: Archiving status documentation..."
COUNT=0
for doc in *_STATUS.md *_COMPLETE.md *_FINAL.md *_NEXT_STEPS.md; do
    if [ -f "$doc" ]; then
        mv "$doc" "$ARCHIVE_DOCS/status/" && ((COUNT++))
    fi
done
log "Archived $COUNT status documents"

# 6. Archive root directory temporary files
log "Step 6: Archiving root directory temporary files..."
COUNT=0
for pattern in "*.txt" "*.php" "*.html" "*.service" "*.py"; do
    for file in $pattern; do
        if [ -f "$file" ] && [[ ! "$file" =~ ^(README|\.git) ]]; then
            # Skip essential files
            case "$file" in
                docker-compose*.yml|Dockerfile*|.gitignore|requirements.txt|package.json|*.md)
                    continue
                    ;;
            esac
            mv "$file" "$ARCHIVE_ROOT/" && ((COUNT++))
        fi
    done 2>/dev/null || true
done
log "Archived $COUNT root temporary files"

# 7. Archive old backups
log "Step 7: Archiving old backups..."
if [ -d "backups" ]; then
    mv backups "$ARCHIVE_BUILDS/backups" && log "Archived backups/"
fi
if [ -d "moode-working-backup" ]; then
    mv moode-working-backup "$ARCHIVE_BUILDS/moode-working-backup" && log "Archived moode-working-backup/"
fi

# 8. Archive test/debug directories
log "Step 8: Archiving test/debug directories..."
for dir in complete-sim-* test-* analyses; do
    if [ -d "$dir" ]; then
        mv "$dir" "$ARCHIVE_BUILDS/$dir" && log "Archived $dir/"
    fi
done

# Summary
log ""
log "=== CLEANUP COMPLETE ==="
log "Archived to: $ARCHIVE_BASE"
log ""
log "Summary:"
log "  - Temporary fix scripts: archived"
log "  - Status documentation: archived"
log "  - Root temporary files: archived"
log "  - Old backups: archived"
log "  - Test/debug directories: archived"
log ""
log "✅ System cleaned up for v1.0!"
