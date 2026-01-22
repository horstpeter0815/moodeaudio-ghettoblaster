#!/bin/bash
#
# Upload moOde Working Image to GitHub Release
# This script uploads an existing image file to GitHub
#

set -e

REPO_OWNER="horstpeter0815"
REPO_NAME="moode-working-image"
RELEASE_TAG="v1.0-working"

# Find the most recent image zip file
IMAGE_ZIP=$(ls -t ~/Downloads/moode-10.2-working-*.img.zip 2>/dev/null | head -1)

if [ -z "$IMAGE_ZIP" ] || [ ! -f "$IMAGE_ZIP" ]; then
    echo "❌ Error: Image file not found!"
    echo "Expected: ~/Downloads/moode-10.2-working-*.img.zip"
    echo ""
    echo "Create the image first:"
    echo "  cd scripts/deployment"
    echo "  ./CREATE_WORKING_IMAGE_FROM_SD.sh"
    exit 1
fi

IMAGE_SIZE=$(ls -lh "$IMAGE_ZIP" | awk '{print $5}')
echo "=========================================="
echo "UPLOAD IMAGE TO GITHUB"
echo "=========================================="
echo ""
echo "Image file: $IMAGE_ZIP"
echo "Size: $IMAGE_SIZE"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Release tag: $RELEASE_TAG"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not installed"
    echo ""
    echo "Install it:"
    echo "  brew install gh"
    echo "  gh auth login"
    exit 1
fi

# Check if authenticated
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI not authenticated"
    echo ""
    echo "Authenticate:"
    echo "  gh auth login"
    echo ""
    echo "Make sure to grant 'workflow' scope for releases"
    exit 1
fi

# Check if repository exists
if ! gh repo view "$REPO_OWNER/$REPO_NAME" &>/dev/null; then
    echo "⚠️  Repository doesn't exist. Creating it..."
    echo ""
    
    # Create repository
    gh repo create "$REPO_NAME" \
        --public \
        --description "moOde 10.2 Working Image - Complete working configuration" \
        --clone=false
    
    echo "✅ Repository created: https://github.com/$REPO_OWNER/$REPO_NAME"
    echo ""
    
    # Wait a moment for GitHub to process
    sleep 2
else
    echo "✅ Repository exists: https://github.com/$REPO_OWNER/$REPO_NAME"
    echo ""
fi

# Check if release already exists
if gh release view "$RELEASE_TAG" --repo "$REPO_OWNER/$REPO_NAME" &>/dev/null; then
    echo "⚠️  Release $RELEASE_TAG already exists"
    echo ""
    read -p "Delete existing release and create new one? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing release..."
        gh release delete "$RELEASE_TAG" --repo "$REPO_OWNER/$REPO_NAME" --yes
        echo "✅ Release deleted"
        echo ""
    else
        echo "Cancelled. Use a different tag or delete the release manually."
        exit 1
    fi
fi

# Create release with file
echo "Creating release and uploading image..."
echo "This may take a few minutes (1.6GB upload)..."
echo ""

gh release create "$RELEASE_TAG" \
    --repo "$REPO_OWNER/$REPO_NAME" \
    --title "moOde 10.2 Working Image - Complete Setup" \
    --notes "Complete working moOde 10.2 image ready to burn!

**What's Included:**
- Complete moOde 10.2 installation
- Display: 1280x400 landscape, touchscreen calibrated
- Audio: HiFiBerry AMP100, volume optimized (Digital 75%, Analogue 100%)
- Network: WiFi (NAM YANG 2) configured
- Filters: CamillaDSP ready (Bose Wave filters available)
- Radio: 6 curated stations
- Volume: Optimized settings (MPD software volume control)

**Quick Start:**
1. Download the image zip file
2. Extract: \`unzip moode-10.2-working-*.img.zip\`
3. Burn to SD card using Balena Etcher or dd
4. Boot Raspberry Pi 5
5. Access: http://moode.local

**Hardware:**
- Raspberry Pi 5 (8GB)
- HiFiBerry AMP100
- 1280x400 touchscreen (WaveShare)

**SSH Access:**
- User: andre
- Password: 0815

Ready to use! Just download, burn, and boot! 🎵" \
    "$IMAGE_ZIP"

echo ""
echo "=========================================="
echo "✅ UPLOAD COMPLETE!"
echo "=========================================="
echo ""
echo "Release URL:"
echo "https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest"
echo ""
echo "Share this link with your friend:"
echo "https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest"
echo ""
echo "They can download the image and burn it to SD card!"
echo ""
