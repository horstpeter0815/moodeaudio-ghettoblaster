#!/bin/bash
# Fix Bose Wave filters config on moOde system
# Run this on the moOde system

CONFIG_FILE="/usr/share/camilladsp/configs/bose_wave_filters.yml"

echo "Fixing Bose Wave filters config..."

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Create backup
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
echo "Backup created: ${CONFIG_FILE}.backup"

# Fix the pipeline entries - add type: Filter to filter entries
sudo sed -i '/^  - band_20$/{N; s/\(band_20\)\n\(- bypassed: null\)/\1\n  type: Filter\n\2/}' "$CONFIG_FILE"

# For the second filter entry (channel 1), add type: Filter before processors
sudo sed -i '/^  - band_20$/{:a;N;/^processors:/!ba;s/\(band_20\)\n\(processors:\)/\1\n  type: Filter\n\2/}' "$CONFIG_FILE"

# Actually, let's use a more reliable approach - use Python to fix it properly
sudo tee /tmp/fix_config.py > /dev/null << 'ENDPYTHON'
import yaml
import sys

config_file = '/usr/share/camilladsp/configs/bose_wave_filters.yml'

try:
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    # Fix pipeline entries
    if 'pipeline' in config:
        for i, entry in enumerate(config['pipeline']):
            # If entry has 'channels' and 'names' but no 'type', it's a Filter
            if 'channels' in entry and 'names' in entry and 'type' not in entry:
                config['pipeline'][i]['type'] = 'Filter'
    
    # Write back
    with open(config_file, 'w') as f:
        yaml.dump(config, f, sort_keys=False, default_flow_style=False, allow_unicode=True)
    
    print("Config fixed successfully")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
ENDPYTHON

sudo python3 /tmp/fix_config.py

if [ $? -eq 0 ]; then
    echo "✓ Config fixed!"
    
    # Validate
    echo "Validating config..."
    camilladsp -c "$CONFIG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✓ Config is valid!"
        echo ""
        echo "Restarting CamillaDSP..."
        sudo killall -s SIGHUP camilladsp 2>/dev/null || echo "CamillaDSP not running (will start when needed)"
    else
        echo "✗ Config validation failed"
        echo "Restoring backup..."
        sudo mv "${CONFIG_FILE}.backup" "$CONFIG_FILE"
        exit 1
    fi
else
    echo "✗ Failed to fix config"
    exit 1
fi

sudo rm -f /tmp/fix_config.py
echo "Done!"

