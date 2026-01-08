#!/bin/bash
# Organize Scripts - Move scripts to appropriate directories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Create directories
mkdir -p scripts/{network,deployment,setup,fixes,wizard,audio,display}
mkdir -p tools/{build,fix,test,monitor}
mkdir -p archive/scripts

echo "📦 Organizing scripts..."

# Network scripts
echo "🌐 Moving network scripts..."
for script in SETUP_GHETTOBLASTER_WIFI_CLIENT.sh VERIFY_GHETTOBLASTER_CONNECTION.sh \
              COMPLETE_GHETTOBLASTER_SETUP.sh FIX_NETWORK_PRECISE.sh \
              FIX_ETHERNET_DEFINITIVE.sh FIX_PRIORITIZE_ETHERNET.sh \
              CONFIGURE_WIFI_ON_SD.sh CONFIGURE_WLAN_ONLY.sh \
              SETUP_WIFI_NETWORK.sh WIFI_SETUP_SD_CARD.sh \
              SETUP_ETHERNET_DHCP.sh FIX_NETWORK_CONFLICT.sh \
              APPLY_WIFI_CONFIG.sh CONFIGURE_TAVEE_WIFI.sh \
              WAIT_FOR_PI_BOOT.sh; do
    if [ -f "$script" ]; then
        mv "$script" scripts/network/ 2>/dev/null && echo "  ✅ $script"
    fi
done

# Wizard scripts
echo "🧙 Moving wizard scripts..."
for script in DEPLOY_WIZARD_NOW.sh COMPLETE_WIZARD_SETUP.sh; do
    if [ -f "$script" ]; then
        mv "$script" scripts/wizard/ 2>/dev/null && echo "  ✅ $script"
    fi
done

# Build scripts (move to tools/build or archive old ones)
echo "🔨 Organizing build scripts..."
for script in START_BUILD_36.sh BUILD_WITH_USERNAME_FIX.sh \
              MONITOR_BUILD_OUTPUT.sh MONITOR_BUILD_LIVE.sh \
              CLEANUP_OLD_BUILDS.sh; do
    if [ -f "$script" ]; then
        # Check if old (90+ days)
        if [ $(find "$script" -mtime +90 2>/dev/null | wc -l) -gt 0 ]; then
            mv "$script" archive/scripts/$(date +%Y-%m-%d)_$(basename "$script") 2>/dev/null && echo "  📦 Archived: $script"
        else
            mv "$script" tools/build/ 2>/dev/null && echo "  ✅ $script"
        fi
    fi
done

# Deployment scripts
echo "🚀 Moving deployment scripts..."
for script in DEPLOY_FIX_SCRIPT.sh BURN_IMAGE_TO_SD.sh \
              BURN_IMAGE_AUTO.sh burn-sd-fast.sh \
              burn-ghettoblaster-to-sd.sh copy-to-sd.sh \
              deploy-simple.sh deploy-with-password.sh; do
    if [ -f "$script" ]; then
        mv "$script" scripts/deployment/ 2>/dev/null && echo "  ✅ $script"
    fi
done

# Audio scripts
echo "🔊 Moving audio scripts..."
for script in activate-camilladsp-*.sh check-audio-chain.sh \
              diagnose-camilladsp.sh test-bose-filters-on-pi.sh; do
    if [ -f "$script" ]; then
        mv "$script" scripts/audio/ 2>/dev/null && echo "  ✅ $script"
    fi
done

# Display scripts
echo "🖥️  Moving display scripts..."
for script in FIX_DISPLAY_NOW.sh APPLY_XINITRC_DISPLAY.sh \
              pi5-fix-orientation-timing.sh pi5-fix-landscape-complete.sh \
              analyze-display-issue-properly.sh; do
    if [ -f "$script" ]; then
        mv "$script" scripts/display/ 2>/dev/null && echo "  ✅ $script"
    fi
done

# Archive old/unused scripts (90+ days old, not recently used)
echo "📦 Archiving old scripts..."
find . -maxdepth 1 -name "*.sh" -type f -mtime +90 | while read script; do
    basename_script=$(basename "$script")
    # Skip if it's a toolbox script or important script
    if [[ ! "$basename_script" =~ ^(toolbox|build|fix|test|monitor|version)\.sh$ ]] && \
       [[ ! "$basename_script" =~ ^(complete_test_suite|create_wizard_agent)\.sh$ ]]; then
        mv "$script" archive/scripts/$(date +%Y-%m-%d)_"$basename_script" 2>/dev/null && \
        echo "  📦 Archived: $basename_script"
    fi
done

echo ""
echo "✅ Organization complete!"
echo ""
echo "Summary:"
echo "  Network: $(ls -1 scripts/network/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo "  Wizard: $(ls -1 scripts/wizard/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo "  Deployment: $(ls -1 scripts/deployment/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo "  Audio: $(ls -1 scripts/audio/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo "  Display: $(ls -1 scripts/display/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo "  Build: $(ls -1 tools/build/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo "  Archived: $(ls -1 archive/scripts/ 2>/dev/null | wc -l | tr -d ' ') scripts"
echo ""
echo "Remaining in root: $(find . -maxdepth 1 -name "*.sh" -type f | wc -l | tr -d ' ') scripts"

