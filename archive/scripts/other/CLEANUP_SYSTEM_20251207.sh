#!/bin/bash
################################################################################
#
# CLEANUP SYSTEM - SAUBERE STRUKTUR
#
# Kategorisiert und archiviert Dokumentation nach neuen Standards
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TEMP_DIR="temp-archive-20251207"
DOC_DIR="documentation"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧹 SYSTEM CLEANUP - SAUBERE STRUKTUR                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Erstelle Verzeichnisse
mkdir -p "$TEMP_DIR"
mkdir -p "$DOC_DIR"/{master,active,knowledge,fixes,archive}

echo "📋 SCHRITT 1: Master-Dokumente identifizieren..."
MASTER_FILES=(
    "CORE_KNOWLEDGE_MASTER.md"
    "MEMORY_TRAINING_PLAN_20251207.md"
    "DOCUMENTATION_MASTER_PLAN_20251207.md"
    "NAMING_CONVENTION.md"
    "SYSTEM_ORGANIZATION.md"
    "REPOSITORY_KNOWLEDGE_BASE.md"
    "DRIVERS_KNOWLEDGE_BASE.md"
    "MOODE_FORUM_KNOWLEDGE_BASE.md"
)

for file in "${MASTER_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file → documentation/master/"
        mv "$file" "$DOC_DIR/master/" 2>/dev/null || true
    fi
done

echo ""
echo "📋 SCHRITT 2: Aktive Dokumentation identifizieren..."
ACTIVE_PATTERNS=(
    "*_FIX_*.md"
    "*_SOLUTION_*.md"
    "*_CONFIG_*.md"
    "*_TEST_*.md"
    "*_BUILD_*.md"
    "*_ANALYSIS_*.md"
)

# Finde aktuelle Dateien (letzte 30 Tage)
find . -maxdepth 1 -name "*.md" -type f -mtime -30 | while read file; do
    filename=$(basename "$file")
    # Überspringe Master-Dateien
    skip=false
    for master in "${MASTER_FILES[@]}"; do
        if [ "$filename" = "$master" ]; then
            skip=true
            break
        fi
    done
    if [ "$skip" = false ]; then
        # Prüfe ob es zu aktiven Patterns passt
        for pattern in "${ACTIVE_PATTERNS[@]}"; do
            if [[ "$filename" == $pattern ]]; then
                echo "  ✅ $filename → documentation/active/"
                mv "$file" "$DOC_DIR/active/" 2>/dev/null || true
                break
            fi
        done
    fi
done

echo ""
echo "📋 SCHRITT 3: Wissensbasen identifizieren..."
KNOWLEDGE_PATTERNS=(
    "*KNOWLEDGE*.md"
    "*LEARNING*.md"
    "*TRAINING*.md"
    "*FORUM*.md"
)

find . -maxdepth 1 -name "*.md" -type f | while read file; do
    filename=$(basename "$file")
    for pattern in "${KNOWLEDGE_PATTERNS[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            echo "  ✅ $filename → documentation/knowledge/"
            mv "$file" "$DOC_DIR/knowledge/" 2>/dev/null || true
            break
        fi
    done
done

echo ""
echo "📋 SCHRITT 4: Marketing-Namen archivieren..."
MARKETING_PATTERNS=(
    "*FINAL*.md"
    "*COMPLETE*.md"
    "*ULTIMATE*.md"
    "*GUARANTEED*.md"
    "*NOW*.md"
    "*QUICK*.md"
    "*EASY*.md"
)

find . -maxdepth 1 -name "*.md" -type f | while read file; do
    filename=$(basename "$file")
    # Überspringe bereits verschobene Dateien
    if [ ! -f "$file" ]; then
        continue
    fi
    for pattern in "${MARKETING_PATTERNS[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            echo "  📦 $filename → temp-archive-20251207/"
            mv "$file" "$TEMP_DIR/" 2>/dev/null || true
            break
        fi
    done
done

echo ""
echo "📋 SCHRITT 5: Status/Summary Dateien archivieren..."
STATUS_PATTERNS=(
    "*STATUS*.md"
    "*SUMMARY*.md"
    "*REPORT*.md"
)

find . -maxdepth 1 -name "*.md" -type f | while read file; do
    filename=$(basename "$file")
    if [ ! -f "$file" ]; then
        continue
    fi
    for pattern in "${STATUS_PATTERNS[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            echo "  📦 $filename → temp-archive-20251207/"
            mv "$file" "$TEMP_DIR/" 2>/dev/null || true
            break
        fi
    done
done

echo ""
echo "📋 SCHRITT 6: Verbleibende Dateien prüfen..."
REMAINING=$(find . -maxdepth 1 -name "*.md" -type f | wc -l | tr -d ' ')
if [ "$REMAINING" -gt 0 ]; then
    echo "  ⚠️  $REMAINING Dateien verbleiben im Root"
    echo "  📋 Prüfe manuell:"
    find . -maxdepth 1 -name "*.md" -type f | head -10
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ CLEANUP ABGESCHLOSSEN                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 NEUE STRUKTUR:"
echo "  - documentation/master/     - Master-Dokumente"
echo "  - documentation/active/     - Aktive Dokumentation"
echo "  - documentation/knowledge/    - Wissensbasen"
echo "  - documentation/fixes/        - Fixes"
echo "  - temp-archive-20251207/    - Archiv (wird nach 2 Wochen gelöscht)"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "  1. Dokumentation-Index erstellen"
echo "  2. Neue Struktur dokumentieren"
echo "  3. Temp-Ordner nach 2 Wochen löschen"
echo ""

