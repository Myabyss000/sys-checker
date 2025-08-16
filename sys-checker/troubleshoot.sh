#!/bin/bash

# ===========================================
# System Checker Troubleshooting Script
# ===========================================

set -euo pipefail

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

check_system_info() {
    print_message "INFO" "System Information:"
    echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"' 2>/dev/null || echo "Unknown")"
    echo "  Kernel: $(uname -r 2>/dev/null || echo "Unknown")"
    echo "  Architecture: $(uname -m 2>/dev/null || echo "Unknown")"
    echo "  Shell: $SHELL"
    echo "  User: $(whoami) (UID: $(id -u))"
    echo ""
}

check_package_manager() {
    print_message "INFO" "Package Manager Detection:"
    
    local found=false
    
    if command -v apt &> /dev/null; then
        print_message "SUCCESS" "APT detected: $(apt --version 2>/dev/null | head -1)"
        found=true
    fi
    
    if command -v dnf &> /dev/null; then
        print_message "SUCCESS" "DNF detected: $(dnf --version 2>/dev/null | head -1)"
        found=true
    fi
    
    if command -v yum &> /dev/null; then
        print_message "SUCCESS" "YUM detected: $(yum --version 2>/dev/null | head -1)"
        found=true
    fi
    
    if command -v pacman &> /dev/null; then
        print_message "SUCCESS" "PACMAN detected: $(pacman --version 2>/dev/null | head -1)"
        found=true
    fi
    
    if [ "$found" = false ]; then
        print_message "ERROR" "No supported package manager found!"
        echo "  Supported: apt, dnf, yum, pacman"
    fi
    echo ""
}

check_dependencies() {
    print_message "INFO" "Dependency Check:"
    
    local deps=("bash" "date" "hostname" "uptime" "free" "df" "systemctl" "grep" "awk" "sed")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo "  ✓ $dep"
        else
            echo "  ✗ $dep (MISSING)"
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        print_message "SUCCESS" "All core dependencies are available"
    else
        print_message "ERROR" "Missing dependencies: ${missing[*]}"
    fi
    echo ""
}

check_notification_tools() {
    print_message "INFO" "Notification Tools:"
    
    if command -v notify-send &> /dev/null; then
        print_message "SUCCESS" "notify-send available: $(which notify-send)"
    else
        print_message "WARNING" "notify-send not found"
        echo "  Install with: sudo apt install libnotify-bin"
    fi
    
    if command -v zenity &> /dev/null; then
        print_message "SUCCESS" "zenity available: $(which zenity)"
    else
        print_message "WARNING" "zenity not found"
        echo "  Install with: sudo apt install zenity"
    fi
    echo ""
}

check_services() {
    print_message "INFO" "System Services:"
    
    local services=("cron" "crond" "systemd-resolved" "networking")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_message "SUCCESS" "$service is running"
        elif systemctl list-unit-files --type=service 2>/dev/null | grep -q "^$service.service"; then
            print_message "WARNING" "$service is available but not running"
        else
            echo "  - $service: not available"
        fi
    done
    echo ""
}

check_permissions() {
    print_message "INFO" "File Permissions:"
    
    local files=("system-checker.sh" "install.sh" "uninstall.sh" "test.sh")
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            if [ -x "$file" ]; then
                print_message "SUCCESS" "$file is executable"
            else
                print_message "WARNING" "$file exists but is not executable"
                echo "  Fix with: chmod +x $file"
            fi
        else
            print_message "ERROR" "$file not found"
        fi
    done
    echo ""
}

check_disk_space() {
    print_message "INFO" "Disk Space:"
    
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "  Root filesystem: $usage% used"
    
    if [ "$usage" -gt 90 ]; then
        print_message "ERROR" "Disk space critically low!"
    elif [ "$usage" -gt 80 ]; then
        print_message "WARNING" "Disk space getting low"
    else
        print_message "SUCCESS" "Disk space is okay"
    fi
    echo ""
}

check_network() {
    print_message "INFO" "Network Connectivity:"
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_message "SUCCESS" "Internet connectivity available"
    else
        print_message "WARNING" "No internet connectivity detected"
    fi
    
    # Test package repository access
    if command -v apt &> /dev/null; then
        if timeout 10 apt-cache policy &> /dev/null; then
            print_message "SUCCESS" "Package repositories accessible"
        else
            print_message "WARNING" "Package repositories may not be accessible"
        fi
    fi
    echo ""
}

common_fixes() {
    print_message "INFO" "Common Fixes:"
    echo ""
    
    echo "1. Install missing notification tools:"
    echo "   sudo apt update && sudo apt install -y libnotify-bin zenity"
    echo ""
    
    echo "2. Fix file permissions:"
    echo "   chmod +x system-checker.sh install.sh uninstall.sh test.sh"
    echo ""
    
    echo "3. Update package lists:"
    echo "   sudo apt update  # Ubuntu/Debian"
    echo "   sudo dnf check-update  # Fedora"
    echo "   sudo yum check-update  # CentOS/RHEL"
    echo ""
    
    echo "4. Install cron service:"
    echo "   sudo apt install -y cron && sudo systemctl enable cron"
    echo ""
    
    echo "5. Test system checker without auto-update:"
    echo "   ./system-checker.sh --no-popup"
    echo ""
    
    echo "6. Check logs for detailed errors:"
    echo "   tail -f logs/system-report-*.log"
    echo ""
}

main() {
    echo "=== System Checker Troubleshooting ==="
    echo ""
    
    # Change to script directory
    if [ -f "system-checker.sh" ]; then
        echo "Running from: $(pwd)"
    else
        print_message "WARNING" "system-checker.sh not found in current directory"
        echo "Please run this script from the sys-checker directory"
        echo ""
    fi
    
    check_system_info
    check_package_manager
    check_dependencies
    check_notification_tools
    check_services
    check_permissions
    check_disk_space
    check_network
    common_fixes
    
    print_message "INFO" "Troubleshooting complete!"
    echo "If you're still having issues, please create an issue at:"
    echo "https://github.com/Myabyss000/sys-checker/issues"
}

main "$@"
