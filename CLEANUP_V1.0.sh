#!/bin/bash
echo "=== CLEANING UP DEBUGGING FILES FOR V1.0 ==="
echo ""

# Move debugging docs to archive
echo "1. Archiving old debugging docs..."
mkdir -p .archive/pre-v1.0-debugging
mv DEVICE_TREE_FIX_PLAN.md .archive/pre-v1.0-debugging/ 2>/dev/null
mv PROPER_FIX_COMPLETE.md .archive/pre-v1.0-debugging/ 2>/dev/null
mv LESSONS_LEARNED.md .archive/pre-v1.0-debugging/ 2>/dev/null

# Delete temporary config files in root
echo "2. Removing temporary config files..."
rm -f mpd-service-fix.conf
rm -f 99-dsi.conf

# Clean up tools directory (keep only essential)
echo "3. Cleaning tools directory..."
mkdir -p .archive/pre-v1.0-tools
mv tools/*.sh .archive/pre-v1.0-tools/ 2>/dev/null
echo "  Moved $(ls .archive/pre-v1.0-tools/*.sh 2>/dev/null | wc -l) debug scripts to archive"

# Keep only essential scripts in tools
mkdir -p tools
# (No essential scripts needed anymore - everything in WISSENSBASIS)

# Clean up old backups (keep only latest and v1.0)
echo "4. Cleaning old backups..."
ls backups/ | grep -v "v1.0" | grep -v "$(ls -t backups/ | head -1)" | while read dir; do
  echo "  Archiving backups/$dir"
  mv "backups/$dir" .archive/pre-v1.0-backups/ 2>/dev/null
done

echo ""
echo "=== CLEANUP SUMMARY ==="
echo "✓ Archived debugging docs to .archive/pre-v1.0-debugging/"
echo "✓ Archived old tools to .archive/pre-v1.0-tools/"
echo "✓ Removed temporary config files"
echo "✓ Kept: v1.0-working-config/, WISSENSBASIS/, documentation/"
echo ""
echo "Current structure:"
ls -d */ 2>/dev/null | grep -E "v1.0|WISSENSBASIS|documentation|rag-upload"
