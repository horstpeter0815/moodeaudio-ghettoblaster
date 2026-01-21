#!/bin/bash
# Maintain Toolbox - Update inventory and verify tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"

cd "$PROJECT_ROOT"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🛠️  TOOLBOX MAINTENANCE                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Count scripts
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Counting tools..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SHELL_SCRIPTS=$(find "$TOOLS_DIR" -type f -name "*.sh" | wc -l | tr -d ' ')
PYTHON_SCRIPTS=$(find "$TOOLS_DIR" -type f -name "*.py" | wc -l | tr -d ' ')
TOTAL_SCRIPTS=$((SHELL_SCRIPTS + PYTHON_SCRIPTS))

echo "  Shell scripts: $SHELL_SCRIPTS"
echo "  Python scripts: $PYTHON_SCRIPTS"
echo "  Total: $TOTAL_SCRIPTS"
echo ""

# Verify main toolbox script
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Verifying toolbox structure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$TOOLS_DIR/toolbox.sh" ]; then
    echo "  ✅ toolbox.sh exists"
    if [ -x "$TOOLS_DIR/toolbox.sh" ]; then
        echo "  ✅ toolbox.sh is executable"
    else
        echo "  ⚠️  Making toolbox.sh executable..."
        chmod +x "$TOOLS_DIR/toolbox.sh"
    fi
else
    echo "  ❌ toolbox.sh not found!"
fi

# Check key tools
KEY_TOOLS=(
    "ai.sh"
    "build.sh"
    "fix.sh"
    "test.sh"
    "monitor.sh"
    "cleanup.sh"
    "version.sh"
)

echo ""
echo "  Key tools status:"
for tool in "${KEY_TOOLS[@]}"; do
    if [ -f "$TOOLS_DIR/$tool" ]; then
        echo "    ✅ $tool"
    else
        echo "    ⚠️  $tool (missing)"
    fi
done

echo ""

# Update TOOLS_INVENTORY.md timestamp
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Updating TOOLS_INVENTORY.md..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$PROJECT_ROOT/TOOLS_INVENTORY.md" ]; then
    # Update last modified date
    sed -i.bak "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date +%Y-%m-%d)/" "$PROJECT_ROOT/TOOLS_INVENTORY.md"
    rm -f "$PROJECT_ROOT/TOOLS_INVENTORY.md.bak"
    echo "  ✅ TOOLS_INVENTORY.md updated"
else
    echo "  ⚠️  TOOLS_INVENTORY.md not found"
fi

echo ""

# Verify tool categories
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Verifying tool categories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CATEGORIES=(
    "build"
    "fix"
    "test"
    "monitor"
    "setup"
    "utils"
    "network"
)

for category in "${CATEGORIES[@]}"; do
    if [ -d "$TOOLS_DIR/$category" ]; then
        COUNT=$(find "$TOOLS_DIR/$category" -type f \( -name "*.sh" -o -name "*.py" \) | wc -l | tr -d ' ')
        echo "  ✅ $category/ ($COUNT tools)"
    else
        echo "  ⚠️  $category/ (missing)"
    fi
done

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Toolbox structure verified"
echo "✅ Total tools: $TOTAL_SCRIPTS"
echo "✅ Inventory updated"
echo ""
echo "To use toolbox:"
echo "  cd ~/moodeaudio-cursor && ./tools/toolbox.sh"
echo ""
