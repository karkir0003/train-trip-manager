#!/usr/bin/env bash
# Setup script for C++ environment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Setting up C++ Environment ==="

CXX_CMD=""
if command -v clang++ >/dev/null 2>&1; then
    CXX_CMD="clang++"
elif command -v g++ >/dev/null 2>&1; then
    CXX_CMD="g++"
else
    echo -e "${YELLOW}[!]${NC} No C++ compiler found. Installing..."
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        echo "Please complete the Xcode dialog if prompted."
        exit 0
    elif [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y build-essential
        CXX_CMD="g++"
    elif [ -f /etc/redhat-release ]; then
        sudo dnf groupinstall -y "Development Tools"
        CXX_CMD="g++"
    else
        echo -e "${RED}Please install a C++17 compatible compiler (clang++ or g++).${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}[OK]${NC} Found $($CXX_CMD --version | head -n 1)"

echo -n "Testing compilation and execution... "
TMP_BIN="$SCRIPT_DIR/test_trip_manager_bin"
"$CXX_CMD" -std=c++17 "$SCRIPT_DIR/trip_manager.cpp" -o "$TMP_BIN"
"$TMP_BIN" >/dev/null
rm -f "$TMP_BIN"
echo -e "${GREEN}[SUCCESS]${NC}"

echo "You can run C++ with:"
echo "  make"
echo "  (or: make run / make clean)"
