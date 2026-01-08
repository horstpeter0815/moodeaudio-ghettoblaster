#!/bin/bash
################################################################################
#
# PCM5122 Oversampling Filter Control Script
#
# - Lists available oversampling filters
# - Sets oversampling filter via ALSA mixer
# - Reads current filter setting
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

CARD_NUM=${1:-0}
ACTION=${2:-"get"}
FILTER_VALUE=${3:-""}

################################################################################
# Detect PCM5122 mixer control for oversampling
################################################################################

detect_oversampling_control() {
    # Try common control names for PCM5122 oversampling
    local controls=(
        "DSP Program"
        "Filter"
        "Oversampling Filter"
        "DAC Filter"
        "Digital Filter"
        "Interpolation Filter"
    )
    
    for ctrl in "${controls[@]}"; do
        if amixer -c "$CARD_NUM" scontrols 2>/dev/null | grep -qi "$ctrl"; then
            echo "$ctrl"
            return 0
        fi
    done
    
    # Try to find any control with "filter" or "oversampling" in name
    amixer -c "$CARD_NUM" scontrols 2>/dev/null | grep -iE "filter|oversampling" | head -1 | sed 's/Simple mixer control //' | sed "s/'//g"
}

################################################################################
# Get available filter options
################################################################################

get_filter_options() {
    local ctrl=$(detect_oversampling_control)
    
    if [ -z "$ctrl" ]; then
        echo "ERROR: No oversampling control found"
        return 1
    fi
    
    # Get available values from amixer
    amixer -c "$CARD_NUM" sget "$ctrl" 2>/dev/null | \
        grep -E "Items|:.*\[" | \
        sed 's/.*\[\(.*\)\].*/\1/' | \
        sed 's/|/ /g' | \
        tr -s ' ' | \
        sed 's/^ *//' | \
        sed 's/ *$//'
}

################################################################################
# Get current filter setting
################################################################################

get_current_filter() {
    local ctrl=$(detect_oversampling_control)
    
    if [ -z "$ctrl" ]; then
        echo "ERROR: No oversampling control found"
        return 1
    fi
    
    # Get current value
    amixer -c "$CARD_NUM" sget "$ctrl" 2>/dev/null | \
        grep -E ":.*\[" | \
        head -1 | \
        sed 's/.*\[\(.*\)\].*/\1/' | \
        sed 's/|.*//' | \
        sed 's/^ *//' | \
        sed 's/ *$//'
}

################################################################################
# Set filter
################################################################################

set_filter() {
    local ctrl=$(detect_oversampling_control)
    local value="$FILTER_VALUE"
    
    if [ -z "$ctrl" ]; then
        echo "ERROR: No oversampling control found"
        return 1
    fi
    
    if [ -z "$value" ]; then
        echo "ERROR: No filter value specified"
        return 1
    fi
    
    # Set via amixer
    amixer -c "$CARD_NUM" sset "$ctrl" "$value" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "OK: Filter set to $value"
        return 0
    else
        echo "ERROR: Failed to set filter"
        return 1
    fi
}

################################################################################
# Main execution
################################################################################

case "$ACTION" in
    "list")
        get_filter_options
        ;;
    "get")
        get_current_filter
        ;;
    "set")
        set_filter
        ;;
    *)
        echo "Usage: $0 [CARD_NUM] {list|get|set} [FILTER_VALUE]"
        echo ""
        echo "Examples:"
        echo "  $0 0 list              # List available filters"
        echo "  $0 0 get               # Get current filter"
        echo "  $0 0 set 'Bezier 1'    # Set filter to 'Bezier 1'"
        exit 1
        ;;
esac

