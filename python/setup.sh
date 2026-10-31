#!/usr/bin/env bash
# Setup script for Python environment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Setting up Python Environment ==="

if command -v python3 >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} Found $(python3 --version)"
else
    echo -e "${YELLOW}[!]${NC} Python 3 not found."
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            echo "Installing Python via Homebrew..."
            brew install python
        else
            echo -e "${RED}Please install Python from https://www.python.org/downloads/ or install Homebrew.${NC}"
            exit 1
        fi
    elif [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y python3
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y python3
    else
        echo -e "${RED}Please install Python 3 using your system package manager.${NC}"
        exit 1
    fi
fi

echo -n "Testing starter script execution... "
python3 "$SCRIPT_DIR/trip_manager.py" >/dev/null
echo -e "${GREEN}[SUCCESS]${NC}"
echo "You can run Python with:"
echo "  python3 trip_manager.py"
echo "  (or from repo root: python3 python/trip_manager.py)"
