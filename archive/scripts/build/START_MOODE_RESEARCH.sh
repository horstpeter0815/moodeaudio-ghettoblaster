#!/bin/bash
# moOde Audio Research Script
# Clones and analyzes moOde repositories

echo "=== MOODE AUDIO RESEARCH ==="
echo ""

RESEARCH_DIR="$HOME/moode-research"
mkdir -p "$RESEARCH_DIR"
cd "$RESEARCH_DIR"

echo "1. Cloning moOde repositories..."
echo ""

# Main repository
if [ ! -d "moode" ]; then
    echo "   Cloning moode (main)..."
    git clone https://github.com/moode-player/moode.git 2>/dev/null || echo "   ⚠️ Clone failed or already exists"
else
    echo "   ✅ moode already cloned"
fi

# Image builder
if [ ! -d "imgbuild" ]; then
    echo "   Cloning imgbuild..."
    git clone https://github.com/moode-player/imgbuild.git 2>/dev/null || echo "   ⚠️ Clone failed or already exists"
else
    echo "   ✅ imgbuild already cloned"
fi

# Package builder
if [ ! -d "pkgbuild" ]; then
    echo "   Cloning pkgbuild..."
    git clone https://github.com/moode-player/pkgbuild.git 2>/dev/null || echo "   ⚠️ Clone failed or already exists"
else
    echo "   ✅ pkgbuild already cloned"
fi

echo ""
echo "2. Analyzing repository structure..."
echo ""

if [ -d "moode" ]; then
    echo "   moode repository structure:"
    cd moode
    find . -maxdepth 2 -type d | head -20
    echo ""
    echo "   Key files:"
    find . -maxdepth 1 -type f | head -10
    cd ..
fi

echo ""
echo "3. Research directory: $RESEARCH_DIR"
echo "   Ready for analysis!"

