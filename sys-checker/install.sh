#!/bin/bash

# ===========================================
# System Checker Installation Script
# ===========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

install_dependencies() {
    print_message "INFO" "Installing dependencies..."
    
    if command -v apt &> /dev/null; then
        apt update
        # Install dependencies with error handling
        local packages=("cron" "libnotify-bin" "zenity")
        for package in "${packages[@]}"; do
            if apt install -y "$package"; then
                print_message "SUCCESS" "Installed $package"
            else
                print_message "WARNING" "Failed to install $package (might already be installed or unavailable)"
            fi
        done
        
        # Ensure cron service is running
        if systemctl list-unit-files | grep -q "^cron.service"; then
            systemctl enable cron 2>/dev/null || true
            systemctl start cron 2>/dev/null || true
        elif systemctl list-unit-files | grep -q "^crond.service"; then
            systemctl enable crond 2>/dev/null || true
            systemctl start crond 2>/dev/null || true
        fi
        
    elif command -v dnf &> /dev/null; then
        dnf install -y cronie libnotify zenity
        systemctl enable crond
        systemctl start crond
    elif command -v yum &> /dev/null; then
        yum install -y cronie libnotify zenity
        systemctl enable crond
        systemctl start crond
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm cronie libnotify zenity
        systemctl enable cronie
        systemctl start cronie
    fi
    
    print_message "SUCCESS" "Dependencies installation completed"
}

install_system_checker() {
    print_message "INFO" "Installing System Checker..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    
    # Copy files
    cp "$SCRIPT_DIR/system-checker.sh" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/config.conf" "$INSTALL_DIR/"
    
    # Set permissions
    chmod +x "$INSTALL_DIR/system-checker.sh"
    chmod 644 "$INSTALL_DIR/config.conf"
    
    # Create symlink for easy access
    ln -sf "$INSTALL_DIR/system-checker.sh" "$BIN_DIR/system-checker"
    
    print_message "SUCCESS" "System Checker installed to $INSTALL_DIR"
}

create_systemd_service() {
    print_message "INFO" "Creating systemd service..."
    
    cat > "$SYSTEMD_DIR/system-checker.service" << EOF
[Unit]
Description=System Package Checker and Updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/system-checker.sh
User=root
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

    cat > "$SYSTEMD_DIR/system-checker.timer" << EOF
[Unit]
Description=Run System Checker Daily
Requires=system-checker.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    print_message "SUCCESS" "Systemd service created"
}

setup_cron_job() {
    print_message "INFO" "Setting up cron job..."
    
    # Create cron job that runs daily at 2 AM
    crontab -l 2>/dev/null | grep -v "system-checker" > /tmp/crontab.tmp || true
    echo "0 2 * * * $INSTALL_DIR/system-checker.sh >/dev/null 2>&1" >> /tmp/crontab.tmp
    crontab /tmp/crontab.tmp
    rm -f /tmp/crontab.tmp
    
    print_message "SUCCESS" "Cron job scheduled (daily at 2:00 AM)"
}

show_completion_message() {
    print_message "SUCCESS" "Installation completed!"
    echo ""
    echo "System Checker has been installed with the following features:"
    echo "  • Installed to: $INSTALL_DIR"
    echo "  • Configuration: $INSTALL_DIR/config.conf"
    echo "  • Logs directory: $INSTALL_DIR/logs"
    echo "  • Command shortcut: system-checker"
    echo ""
    echo "Usage:"
    echo "  system-checker                 # Run system check"
    echo "  system-checker --auto-update   # Run with automatic updates"
    echo "  system-checker --help          # Show help"
    echo ""
    echo "Scheduling options:"
    echo "  • Cron job: Already configured to run daily at 2:00 AM"
    echo "  • Systemd timer: Run 'sudo systemctl enable --now system-checker.timer'"
    echo ""
    echo "Configuration:"
    echo "  Edit $INSTALL_DIR/config.conf to customize behavior"
    echo ""
    echo "To run a test now: sudo system-checker"
}

main() {
    echo "=== System Checker Installation ==="
    echo ""
    
    check_root
    install_dependencies
    install_system_checker
    
    # Ask user for scheduling preference
    echo ""
    echo "Choose scheduling method:"
    echo "1) Cron (traditional, works on all systems)"
    echo "2) Systemd timer (modern, better logging)"
    echo "3) Both"
    echo "4) None (manual scheduling)"
    echo ""
    read -p "Enter choice [1-4]: " choice
    
    case "$choice" in
        1)
            setup_cron_job
            ;;
        2)
            create_systemd_service
            systemctl enable --now system-checker.timer
            print_message "SUCCESS" "Systemd timer enabled and started"
            ;;
        3)
            setup_cron_job
            create_systemd_service
            systemctl enable --now system-checker.timer
            print_message "SUCCESS" "Both cron and systemd timer configured"
            ;;
        4)
            print_message "INFO" "Skipping automatic scheduling"
            ;;
        *)
            print_message "WARNING" "Invalid choice. Skipping automatic scheduling"
            ;;
    esac
    
    show_completion_message
}

main "$@"
