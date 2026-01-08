#!/bin/bash
# PI 5 ENABLE BOOT PROMPTS AND SET LANDSCAPE
# Make boot verbose and set display_rotate=1 for Landscape

set -e

echo "=========================================="
echo "PI 5 ENABLE BOOT PROMPTS + LANDSCAPE"
echo "Show boot messages and set Landscape"
echo "=========================================="
echo ""

ssh pi2 << 'BOOTANDLANDSCAPE'
export DISPLAY=:0

# Find config files
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
else
    CONFIG_FILE="/boot/config.txt"
    CMDLINE_FILE="/boot/cmdline.txt"
fi

echo "=== STEP 1: ENABLE VERBOSE BOOT (SHOW PROMPTS) ==="
# Remove quiet from cmdline to show boot prompts
if [ -f "$CMDLINE_FILE" ]; then
    sudo sed -i 's/ quiet//g' "$CMDLINE_FILE"
    sudo sed -i 's/quiet //g' "$CMDLINE_FILE"
    echo "✅ Removed 'quiet' from cmdline.txt"
    echo "Boot will now show all prompts and messages"
fi

# Also ensure systemd shows status
if ! grep -q "systemd.show_status=yes" "$CMDLINE_FILE" 2>/dev/null; then
    sudo sed -i 's/$/ systemd.show_status=yes/' "$CMDLINE_FILE"
    echo "✅ Added systemd.show_status=yes"
fi

echo ""
echo "=== STEP 2: SET LANDSCAPE (display_rotate=1) ==="
# Remove old rotation
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"

# Set to 1 (90° rotation = Portrait to Landscape)
echo "display_rotate=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE" > /dev/null

echo "✅ Set display_rotate=1 (90° rotation)"
echo "✅ Set hdmi_group=0 (standard HDMI)"

echo ""
echo "=== STEP 3: VERIFY CONFIGURATION ==="
echo "Config.txt:"
sudo grep -E "display_rotate|hdmi_group" "$CONFIG_FILE" | grep -v "^#"

echo ""
echo "Cmdline.txt:"
cat "$CMDLINE_FILE" | head -1

echo ""
echo "=== READY FOR REBOOT ==="
echo "After reboot:"
echo "  - Boot will show all prompts/messages"
echo "  - Display will be Landscape (1280x400)"
echo "  - display_rotate=1 will be active"
BOOTANDLANDSCAPE

echo ""
echo "=== REBOOTING PI 5 ==="
ssh pi2 "sudo reboot" || true

echo ""
echo "✅ Pi 5 rebooting with:"
echo "  - Verbose boot (all prompts visible)"
echo "  - display_rotate=1 (Landscape)"
echo ""
echo "You will see all boot messages now!"


