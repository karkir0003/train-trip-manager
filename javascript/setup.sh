#!/usr/bin/env bash
# Setup script for JavaScript (Node.js) environment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Setting up JavaScript (Node.js) Environment ==="

if command -v node >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} Found Node.js $(node -v)"
else
    echo -e "${YELLOW}[!]${NC} Node.js not found. Installing..."
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install node
        else
            echo "Downloading and installing official Node.js package..."
            curl -fsSL https://nodejs.org/dist/v20.18.0/node-v20.18.0.pkg -o /tmp/node.pkg
            sudo installer -pkg /tmp/node.pkg -target /
            rm -f /tmp/node.pkg
        fi
    elif [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y nodejs npm
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y nodejs
    else
        echo -e "${RED}Please install Node.js from https://nodejs.org${NC}"
        exit 1
    fi
fi

echo -n "Testing starter script execution... "
node "$SCRIPT_DIR/trip_manager.js" >/dev/null
echo -e "${GREEN}[SUCCESS]${NC}"
echo "You can run JavaScript with:"
echo "  node trip_manager.js"
echo "  (or: npm test / npm start)"
