#!/bin/bash
################################################################################
#
# START DISPLAY CHAIN SIMULATION
#
# Entry point for Docker container to start the display chain simulation
#
################################################################################

set +e  # Don't exit on error - keep container running

# Create log directory
mkdir -p /var/log/display-chain

# Install required packages (non-blocking)
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq \
    xvfb \
    x11-xserver-utils \
    xrandr \
    chromium \
    jq \
    > /dev/null 2>&1 || echo "Some packages may not be available in container"

# Make scripts executable
chmod +x /test-display/*.sh 2>/dev/null || true

# Run simulation
/test-display/simulate-display-chain.sh 2>&1 | tee /var/log/display-chain/startup.log

# Keep container running for interactive use
echo "Simulation complete. Container will stay running for 1 hour."
echo "You can now run analysis scripts interactively."
sleep 3600

