#!/bin/bash

# ===========================================
# System Checker Uninstallation Script
# ===========================================

set -euo pipefail

INSTALL_DIR="/opt/system-checker"
BIN_DIR="/usr/local/bin"
SYSTEMD_DIR="/etc/systemd/system"

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

remove_systemd_service() {
    print_message "INFO" "Removing systemd service and timer..."
    
    # Stop and disable timer
    if systemctl is-enabled system-checker.timer &>/dev/null; then
        systemctl stop system-checker.timer
        systemctl disable system-checker.timer
        print_message "SUCCESS" "Systemd timer stopped and disabled"
    fi
    
    # Stop service if running
    if systemctl is-active system-checker.service &>/dev/null; then
        systemctl stop system-checker.service
        print_message "SUCCESS" "Systemd service stopped"
    fi
    
    # Remove service files
    if [ -f "$SYSTEMD_DIR/system-checker.service" ]; then
        rm -f "$SYSTEMD_DIR/system-checker.service"
        print_message "SUCCESS" "Removed systemd service file"
    fi
    
    if [ -f "$SYSTEMD_DIR/system-checker.timer" ]; then
        rm -f "$SYSTEMD_DIR/system-checker.timer"
        print_message "SUCCESS" "Removed systemd timer file"
    fi
    
    # Reload systemd
    systemctl daemon-reload
}

remove_cron_job() {
    print_message "INFO" "Removing cron job..."
    
    # Remove from root crontab
    if crontab -l 2>/dev/null | grep -q "system-checker"; then
        crontab -l 2>/dev/null | grep -v "system-checker" | crontab -
        print_message "SUCCESS" "Removed cron job from root crontab"
    fi
    
    # Check for user crontabs (optional)
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            if sudo -u "$username" crontab -l 2>/dev/null | grep -q "system-checker"; then
                sudo -u "$username" bash -c "crontab -l 2>/dev/null | grep -v 'system-checker' | crontab -"
                print_message "SUCCESS" "Removed cron job from user $username"
            fi
        fi
    done
}

remove_files() {
    print_message "INFO" "Removing system checker files..."
    
    # Remove symbolic link
    if [ -L "$BIN_DIR/system-checker" ]; then
        rm -f "$BIN_DIR/system-checker"
        print_message "SUCCESS" "Removed symbolic link"
    fi
    
    # Ask about log files
    if [ -d "$INSTALL_DIR/logs" ] && [ "$(ls -A "$INSTALL_DIR/logs" 2>/dev/null)" ]; then
        echo ""
        read -p "Do you want to remove log files? [y/N]: " remove_logs
        case "$remove_logs" in
            [yY][eE][sS]|[yY])
                rm -rf "$INSTALL_DIR/logs"
                print_message "SUCCESS" "Removed log files"
                ;;
            *)
                print_message "INFO" "Keeping log files in $INSTALL_DIR/logs"
                # Just remove the scripts, keep logs
                if [ -f "$INSTALL_DIR/system-checker.sh" ]; then
                    rm -f "$INSTALL_DIR/system-checker.sh"
                fi
                if [ -f "$INSTALL_DIR/config.conf" ]; then
                    rm -f "$INSTALL_DIR/config.conf"
                fi
                print_message "SUCCESS" "Removed script files, kept logs"
                return
                ;;
        esac
    fi
    
    # Remove entire directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_message "SUCCESS" "Removed installation directory"
    fi
}

show_completion_message() {
    print_message "SUCCESS" "System Checker has been completely uninstalled!"
    echo ""
    echo "What was removed:"
    echo "  • Installation directory: $INSTALL_DIR"
    echo "  • Command shortcut: $BIN_DIR/system-checker"
    echo "  • Cron jobs (if any)"
    echo "  • Systemd service and timer (if any)"
    echo ""
    echo "System Checker is now completely removed from your system."
}

main() {
    echo "=== System Checker Uninstallation ==="
    echo ""
    
    print_message "WARNING" "This will completely remove System Checker from your system."
    echo ""
    read -p "Are you sure you want to continue? [y/N]: " confirm
    
    case "$confirm" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            print_message "INFO" "Uninstallation cancelled."
            exit 0
            ;;
    esac
    
    check_root
    remove_systemd_service
    remove_cron_job
    remove_files
    show_completion_message
}

main "$@"
