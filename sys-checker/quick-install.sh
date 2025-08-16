#!/bin/bash

# ===========================================
# Quick Install Script for GitHub Releases
# ===========================================
# This script downloads and installs the latest release from GitHub

set -euo pipefail

# Configuration
GITHUB_REPO="Myabyss000/sys-checker"
INSTALL_DIR="/opt/system-checker"
TEMP_DIR="/tmp/sys-checker-install"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_message "ERROR" "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    local missing_deps=()
    
    for cmd in curl wget tar; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_message "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        print_message "INFO" "Please install them using your package manager"
        exit 1
    fi
}

get_latest_release() {
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    
    if command -v curl &> /dev/null; then
        curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget &> /dev/null; then
        wget -qO- "$api_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        print_message "ERROR" "Neither curl nor wget is available"
        exit 1
    fi
}

download_and_install() {
    local version="$1"
    local download_url="https://github.com/$GITHUB_REPO/releases/download/$version/system-checker-$version.tar.gz"
    
    print_message "INFO" "Downloading System Checker $version..."
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download release
    if command -v curl &> /dev/null; then
        curl -L -o "system-checker.tar.gz" "$download_url"
    else
        wget -O "system-checker.tar.gz" "$download_url"
    fi
    
    # Extract files
    print_message "INFO" "Extracting files..."
    tar -xzf system-checker.tar.gz
    
    # Run installation
    print_message "INFO" "Running installation..."
    chmod +x install.sh
    ./install.sh
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    print_message "SUCCESS" "System Checker $version installed successfully!"
}

main() {
    echo "=== System Checker GitHub Installer ==="
    echo ""
    
    check_root
    check_dependencies
    
    print_message "INFO" "Fetching latest release information..."
    local latest_version
    latest_version=$(get_latest_release)
    
    if [ -z "$latest_version" ]; then
        print_message "ERROR" "Could not determine latest version"
        exit 1
    fi
    
    print_message "INFO" "Latest version: $latest_version"
    
    # Ask for confirmation
    read -p "Do you want to install System Checker $latest_version? [Y/n]: " confirm
    case "$confirm" in
        [nN][oO]|[nN])
            print_message "INFO" "Installation cancelled"
            exit 0
            ;;
    esac
    
    download_and_install "$latest_version"
}

main "$@"
