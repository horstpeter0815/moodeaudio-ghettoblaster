#!/bin/bash
# Phase 2: More aggressive cleanup - archive remaining temporary files

ARCHIVE_BASE="archive/v1.0-cleanup-$(date +%Y%m%d)"
ARCHIVE_DOCS="$ARCHIVE_BASE/docs"
ARCHIVE_ROOT="$ARCHIVE_BASE/root-files"

mkdir -p "$ARCHIVE_DOCS"/{old,duplicate,research}
mkdir -p "$ARCHIVE_ROOT"

# Archive more markdown files (keep only essential)
for doc in *.md; do
    case "$doc" in
        README.md|DISPLAY_CONFIG_WORKING.md|ROOT_CAUSE_FIXES.md|CLEANUP*.md|CLEANUP_PLAN*.md)
            continue
            ;;
        *)
            # Archive research, analysis, old status files
            if [[ "$doc" =~ (RESEARCH|ANALYSIS|ANALYZE|DEBUG|FINDING|LESSON|GUIDE|PLAN|SOLUTION|CONNECTION|DEPLOYMENT|SETUP|STATUS|COMPLETE|FINAL|NEXT|CURRENT|BUILD|TEST|WIZARD|AGENT|CURSOR|NETWORK|ETHERNET|WIFI|DISPLAY|AUDIO|CAMILLA|AMP100|BOSE|RADIO|TOUCH|SSH|USB|HOTSPOT|INTERNET|SHARING|CONSOLE|SERIAL|HOTEL|WORKING|BACKUP|RESTORE|COPY|CREATE|EXECUTE|ENABLE|CONFIGURE|FIX|DO_THIS|ACTION|TRACKER|ACTIVATE|ADD|ANALYZE|CHECK|COLLECT|COMPLETE|CONNECT|CONVERT|COPY|CREATE|DEBUG|DEPLOY|DIAGNOSE|DOWNLOAD|ENABLE|EXECUTE|FIND|FIX|CHECK) ]]; then
                mv "$doc" "$ARCHIVE_DOCS/old/" 2>/dev/null || true
            fi
            ;;
    esac
done

# Archive remaining root scripts (except toolbox)
for script in *.sh; do
    case "$script" in
        complete_test_suite.sh)
            continue
            ;;
        *)
            mv "$script" "$ARCHIVE_ROOT/" 2>/dev/null || true
            ;;
    esac
done

echo "Phase 2 cleanup complete"
