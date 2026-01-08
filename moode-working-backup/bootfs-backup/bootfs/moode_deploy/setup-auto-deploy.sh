#!/bin/bash
# Setup script to enable auto-deployment
# Run this ONCE on the Raspberry Pi to set up auto-deployment

# Copy auto-deploy script to a location that runs on boot
sudo cp /boot/moode_deploy/auto-deploy.sh /usr/local/bin/auto-deploy.sh
sudo chmod +x /usr/local/bin/auto-deploy.sh

# Create systemd service for auto-deployment
sudo tee /etc/systemd/system/moode-deploy.service > /dev/null <<EOF
[Unit]
Description=moOde Auto-Deployment
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-deploy.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable moode-deploy.service
sudo systemctl start moode-deploy.service

echo "Auto-deployment service installed and started!"

