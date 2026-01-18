#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2014 The moOde audio player project / Tim Curtis
#

# Screen blanking: Use both Screen saver and DPMS
# Set framebuffer to 1280x400 before X server starts
fbset -g 1280 400 1280 400 16 >/dev/null 2>&1

xset s 600 0
xset +dpms
xset dpms 600 0 0

# Get configuration
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")
DSI_PORT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_port'")
DSI_SCN_ROTATE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_rotate'")
PI_MODEL=$(/var/www/util/pirev.py | awk -F"\t" '{print $2}' | cut -c 1)

# Get screen res (use W,H for chromium)
if fgrep -q "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt; then
	# KMS disabled - use default or DSI settings
	if [ "$DSI_SCN_TYPE" = "none" ]; then
		SCREEN_RES=$(fbset -s 2>/dev/null | awk '$1 == "geometry" {print $2","$3}')
		[ -z "$SCREEN_RES" ] && SCREEN_RES="640,480"
	else
		SCREEN_RES="1280,400"
	fi
else
	# KMS enabled
	if [ "$DSI_SCN_TYPE" = "none" ]; then
		SCREEN_RES=$(fbset -s 2>/dev/null | awk '$1 == "geometry" {print $2","$3}')
		[ -z "$SCREEN_RES" ] && SCREEN_RES="640,480"
	else
		SCREEN_RES="1280,400"
	fi
fi

# Set screen rotation
if [ "$DSI_SCN_TYPE" = "none" ]; then
	# HDMI screens (default is landscape)
    if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
        DISPLAY=:0 xrandr --output HDMI-2 --rotate left
        SCREEN_RES="1280,400"
    fi
elif [ "$DSI_SCN_TYPE" = "2" ] || [ "$DSI_SCN_TYPE" = "other" ]; then
	# DSI screens (use size WxH for --mode)
	SCREEN_RES_DSI=$(echo $SCREEN_RES | awk -F"," '{print $1"x"$2}')
	# 1X ports use DSI-1 | 2X ports use DSI-1-1 or DSI-1-2
	[[ $PI_MODEL = "5" ]] && DSI_PORT_NAME="DSI-1-$DSI_PORT" || DSI_PORT_NAME="DSI-$DSI_PORT"
    if [ "$DSI_SCN_ROTATE" = "0" ]; then
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate normal --mode $SCREEN_RES_DSI
    elif [ "$DSI_SCN_ROTATE" = "90" ]; then
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate right --mode $SCREEN_RES_DSI
    elif [ "$DSI_SCN_ROTATE" = "180" ]; then
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate inverted --mode $SCREEN_RES_DSI
    elif [ "$DSI_SCN_ROTATE" = "270" ]; then
        DISPLAY=:0 xrandr --output $DSI_PORT_NAME --rotate left --mode $SCREEN_RES_DSI
    fi
else
	echo "Touch1 is set in config and cmdline txt files"
fi

# Get display type config
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")
PEPPY_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'")

# Launch WebUI or Peppy
if [ "$WEBUI_SHOW" = "1" ]; then
	# Clear browser cache
	$(/var/www/util/sysutil.sh clearbrcache)
	# Launch chromium browser
	chromium \
	--app="http://localhost/" \
	--window-size="$SCREEN_RES" \
	--window-position="0,0" \
	--enable-features="OverlayScrollbar" \
	--no-first-run \
	--disable-infobars \
	--disable-session-crashed-bubble \
	--kiosk
elif [ "$PEPPY_SHOW" = "1" ]; then
	if [ "$PEPPY_TYPE" = "meter" ]; then
		cd /opt/peppymeter && python3 peppymeter.py
	else
		cd /opt/peppyspectrum && python3 spectrum.py
	fi
fi
