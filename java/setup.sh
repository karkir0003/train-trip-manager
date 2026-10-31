#!/usr/bin/env bash
# Setup script for Java environment (Amazon Corretto 21 JDK)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Setting up Java Environment ==="

# Check if java/javac are already available in PATH or ~/.corretto
export PATH="$HOME/.local/bin:$HOME/.corretto/amazon-corretto-21.jdk/Contents/Home/bin:$PATH"

if command -v java >/dev/null 2>&1 && command -v javac >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} Found Java: $(javac -version 2>&1)"
else
    echo -e "${YELLOW}[!]${NC} Java JDK not found in PATH."
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    if [ "$OS" = "Darwin" ]; then
        CORRETTO_ARCH="aarch64"
        if [ "$ARCH" = "x86_64" ]; then
            CORRETTO_ARCH="x64"
        fi

        INSTALL_DIR="$HOME/.corretto"
        mkdir -p "$INSTALL_DIR"
        mkdir -p "$HOME/.local/bin"

        echo "Downloading Amazon Corretto 21 JDK for macOS ($CORRETTO_ARCH)..."
        curl -sL "https://corretto.aws/downloads/latest/amazon-corretto-21-${CORRETTO_ARCH}-macos-jdk.tar.gz" | tar -xz -C "$INSTALL_DIR"

        JDK_HOME=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "amazon-corretto-21*" | head -n 1)/Contents/Home
        ln -sf "$JDK_HOME/bin/java" "$HOME/.local/bin/java"
        ln -sf "$JDK_HOME/bin/javac" "$HOME/.local/bin/javac"

        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${GREEN}[OK]${NC} Amazon Corretto 21 installed to $JDK_HOME"
    elif [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y default-jdk
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y java-21-openjdk-devel
    else
        echo -e "${RED}Please install Java 17+ or Amazon Corretto from https://aws.amazon.com/corretto/${NC}"
        exit 1
    fi
fi

echo -n "Testing starter script execution... "
java "$SCRIPT_DIR/TripManager.java" >/dev/null
echo -e "${GREEN}[SUCCESS]${NC}"
echo "You can run Java with:"
echo "  java TripManager.java"
echo "  (or: make)"
