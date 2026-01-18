#!/bin/bash
################################################################################
# PREPARE MOODE FILES FOR RAG UPLOAD
# Organizes moOde project files for easy upload to Open WebUI RAG
################################################################################

set -e

PROJECT_ROOT="$HOME/moodeaudio-cursor"
OUTPUT_DIR="$PROJECT_ROOT/rag-upload-files"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📚 PREPARING MOODE FILES FOR RAG                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create organized directory structure
mkdir -p "$OUTPUT_DIR"/{documentation,source-code,scripts,configs,web-interface}

echo "1. Collecting documentation files..."
find "$PROJECT_ROOT/docs" -name "*.md" -type f | while read file; do
    REL_PATH=$(echo "$file" | sed "s|$PROJECT_ROOT/||")
    DIR=$(dirname "$REL_PATH" | sed 's|docs/||')
    if [ "$DIR" = "." ]; then
        cp "$file" "$OUTPUT_DIR/documentation/"
    else
        mkdir -p "$OUTPUT_DIR/documentation/$DIR"
        cp "$file" "$OUTPUT_DIR/documentation/$DIR/"
    fi
done
echo "   ✅ Documentation files collected"

echo ""
echo "2. Collecting key source code files..."
# PHP includes (sample of key files)
find "$PROJECT_ROOT/moode-source/www/inc" -name "*.php" -type f | head -50 | while read file; do
    cp "$file" "$OUTPUT_DIR/source-code/" 2>/dev/null || true
done

# Command handlers
find "$PROJECT_ROOT/moode-source/www/command" -name "*.php" -type f | while read file; do
    cp "$file" "$OUTPUT_DIR/source-code/" 2>/dev/null || true
done
echo "   ✅ Source code files collected"

echo ""
echo "3. Collecting scripts..."
find "$PROJECT_ROOT/scripts" -name "*.sh" -type f | while read file; do
    cp "$file" "$OUTPUT_DIR/scripts/" 2>/dev/null || true
done

find "$PROJECT_ROOT/moode-source/usr/local/bin" -name "*.sh" -type f | while read file; do
    cp "$file" "$OUTPUT_DIR/scripts/" 2>/dev/null || true
done
echo "   ✅ Scripts collected"

echo ""
echo "4. Collecting configuration files..."
find "$PROJECT_ROOT/moode-source/etc" -type f \( -name "*.conf" -o -name "*.service" -o -name "*.overwrite" \) | while read file; do
    REL_PATH=$(echo "$file" | sed "s|$PROJECT_ROOT/moode-source/||")
    DIR=$(dirname "$REL_PATH")
    mkdir -p "$OUTPUT_DIR/configs/$DIR"
    cp "$file" "$OUTPUT_DIR/configs/$DIR/" 2>/dev/null || true
done
echo "   ✅ Configuration files collected"

echo ""
echo "5. Collecting web interface key files..."
# Key PHP files from web root
for file in "$PROJECT_ROOT/moode-source/www"/*.php; do
    [ -f "$file" ] && cp "$file" "$OUTPUT_DIR/web-interface/" 2>/dev/null || true
done
echo "   ✅ Web interface files collected"

echo ""
echo "6. Creating file list for reference..."
cat > "$OUTPUT_DIR/FILE_LIST.txt" << EOF
moOde Project Files Prepared for RAG Upload
============================================

Documentation: $(find "$OUTPUT_DIR/documentation" -type f | wc -l | tr -d ' ') files
Source Code: $(find "$OUTPUT_DIR/source-code" -type f | wc -l | tr -d ' ') files
Scripts: $(find "$OUTPUT_DIR/scripts" -type f | wc -l | tr -d ' ') files
Configs: $(find "$OUTPUT_DIR/configs" -type f | wc -l | tr -d ' ') files
Web Interface: $(find "$OUTPUT_DIR/web-interface" -type f | wc -l | tr -d ' ') files

Total: $(find "$OUTPUT_DIR" -type f ! -name "FILE_LIST.txt" | wc -l | tr -d ' ') files

Upload Instructions:
1. Open WebUI: http://localhost:3000
2. Go to: Knowledge or RAG section
3. Upload files from each category:
   - documentation/
   - source-code/
   - scripts/
   - configs/
   - web-interface/

Or upload entire directories at once.
EOF

echo "   ✅ File list created"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FILES PREPARED FOR RAG UPLOAD                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Files organized in: $OUTPUT_DIR"
echo ""
echo "Categories:"
echo "  📄 Documentation: $OUTPUT_DIR/documentation/"
echo "  💻 Source Code: $OUTPUT_DIR/source-code/"
echo "  🔧 Scripts: $OUTPUT_DIR/scripts/"
echo "  ⚙️  Configs: $OUTPUT_DIR/configs/"
echo "  🌐 Web Interface: $OUTPUT_DIR/web-interface/"
echo ""
echo "Next: Upload these files to Open WebUI RAG knowledge base"
echo ""

