#!/bin/bash
# Install REST API tools on Raspberry Pi OS
# Run this on the Pi after first boot

set -e

echo "=========================================="
echo "Installing REST API Tools"
echo "=========================================="

# Update system
echo "Step 1: Updating system..."
sudo apt update
sudo apt upgrade -y

# Install essential tools
echo "Step 2: Installing essential tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    netcat \
    nmap \
    htop \
    vim \
    nano

# Install Python REST libraries
echo "Step 3: Installing Python REST libraries..."
pip3 install --user \
    requests \
    flask \
    flask-restful \
    fastapi \
    uvicorn \
    httpx \
    aiohttp

# Install Node.js and npm (for additional REST tools)
echo "Step 4: Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install REST client tools
echo "Step 5: Installing REST client tools..."
sudo npm install -g httpie http-server

# Install additional utilities
echo "Step 6: Installing additional utilities..."
sudo apt install -y \
    sqlite3 \
    mysql-client \
    postgresql-client \
    redis-tools \
    mosquitto-clients

# Create REST API test script
echo "Step 7: Creating REST API test script..."
cat > ~/test_rest_api.sh << 'EOF'
#!/bin/bash
# Test REST API connectivity

echo "Testing REST API tools..."

# Test curl
echo "1. Testing curl..."
curl -s http://localhost:80 > /dev/null && echo "✅ HTTP (port 80) accessible" || echo "❌ HTTP (port 80) not accessible"

# Test Moode API (if available)
echo "2. Testing Moode API..."
curl -s http://localhost:81/api/help > /dev/null && echo "✅ Moode API (port 81) accessible" || echo "⚠️  Moode API (port 81) not accessible"

# Test Python requests
echo "3. Testing Python requests..."
python3 << PYTHON_EOF
import requests
try:
    r = requests.get('http://localhost:80', timeout=2)
    print("✅ Python requests working")
except:
    print("⚠️  Python requests - no server running")
PYTHON_EOF

# Test jq
echo "4. Testing jq..."
echo '{"test": "value"}' | jq . > /dev/null && echo "✅ jq working" || echo "❌ jq not working"

echo ""
echo "REST API tools installation complete!"
EOF

chmod +x ~/test_rest_api.sh

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed tools:"
echo "  ✅ curl, wget, git"
echo "  ✅ python3, pip3"
echo "  ✅ Python REST libraries (requests, flask, fastapi)"
echo "  ✅ Node.js, npm"
echo "  ✅ httpie, http-server"
echo "  ✅ jq (JSON processor)"
echo "  ✅ Database clients (sqlite3, mysql, postgresql, redis)"
echo "  ✅ MQTT client (mosquitto-clients)"
echo ""
echo "Test script created: ~/test_rest_api.sh"
echo "Run it to verify installation"
echo ""

