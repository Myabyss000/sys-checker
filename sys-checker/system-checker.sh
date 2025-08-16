#!/bin/bash

# ===========================================
# Linux System Checker and Auto-Updater
# ===========================================
# Author: System Administrator
# Description: Automated system package management with reporting
# Supports: Ubuntu/Debian (apt), RHEL/CentOS/Fedora (yum/dnf), Arch (pacman)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
REPORT_FILE="$LOG_DIR/system-report-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_FILE="$LOG_DIR/latest-summary.log"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create necessary directories
mkdir -p "$LOG_DIR"

# Function to log messages with timestamp
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$REPORT_FILE"
    
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

# Function to detect package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        log_message "ERROR" "No supported package manager found"
        exit 1
    fi
}

# Function to get system information
get_system_info() {
    log_message "INFO" "Collecting system information..."
    
    echo "=== SYSTEM INFORMATION ===" >> "$REPORT_FILE"
    {
        echo "Hostname: $(hostname)"
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Uptime: $(uptime -p)"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
        echo "Disk Usage: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
        echo ""
    } >> "$REPORT_FILE"
}

# Function to check disk space
check_disk_space() {
    log_message "INFO" "Checking disk space..."
    
    echo "=== DISK SPACE CHECK ===" >> "$REPORT_FILE"
    df -h >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Check if any partition is over 80% full
    while read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        filesystem=$(echo "$line" | awk '{print $1}')
        mountpoint=$(echo "$line" | awk '{print $6}')
        
        if [[ "$usage" =~ ^[0-9]+$ ]] && [ "$usage" -gt 80 ]; then
            log_message "WARNING" "Disk usage high: $filesystem ($mountpoint) is $usage% full"
        fi
    done < <(df -h | tail -n +2)
}

# Function to update package lists
update_package_lists() {
    local pkg_manager="$1"
    
    log_message "INFO" "Updating package lists..."
    
    case "$pkg_manager" in
        "apt")
            if sudo apt update >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "Package lists updated successfully"
            else
                log_message "ERROR" "Failed to update package lists"
                return 1
            fi
            ;;
        "dnf")
            if sudo dnf check-update >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "Package cache refreshed successfully"
            else
                # dnf check-update returns 100 when updates are available, which is normal
                if [ $? -eq 100 ]; then
                    log_message "SUCCESS" "Package cache refreshed successfully (updates available)"
                else
                    log_message "ERROR" "Failed to refresh package cache"
                    return 1
                fi
            fi
            ;;
        "yum")
            if sudo yum check-update >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "Package cache refreshed successfully"
            else
                # yum check-update returns 100 when updates are available, which is normal
                if [ $? -eq 100 ]; then
                    log_message "SUCCESS" "Package cache refreshed successfully (updates available)"
                else
                    log_message "ERROR" "Failed to refresh package cache"
                    return 1
                fi
            fi
            ;;
        "pacman")
            if sudo pacman -Sy >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "Package database synchronized successfully"
            else
                log_message "ERROR" "Failed to synchronize package database"
                return 1
            fi
            ;;
    esac
}

# Function to check for available updates
check_available_updates() {
    local pkg_manager="$1"
    local update_count=0
    
    log_message "INFO" "Checking for available updates..."
    
    echo "=== AVAILABLE UPDATES ===" >> "$REPORT_FILE"
    
    case "$pkg_manager" in
        "apt")
            update_count=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)
            if [ "$update_count" -gt 1 ]; then
                update_count=$((update_count - 1))  # Subtract header line
                log_message "INFO" "$update_count package(s) available for upgrade"
                apt list --upgradable >> "$REPORT_FILE" 2>/dev/null
            else
                log_message "SUCCESS" "All packages are up to date"
            fi
            ;;
        "dnf")
            update_count=$(dnf list updates 2>/dev/null | grep -c "^[^L]" || true)
            if [ "$update_count" -gt 0 ]; then
                log_message "INFO" "$update_count package(s) available for upgrade"
                dnf list updates >> "$REPORT_FILE" 2>/dev/null
            else
                log_message "SUCCESS" "All packages are up to date"
            fi
            ;;
        "yum")
            update_count=$(yum list updates 2>/dev/null | grep -c "^[^L]" || true)
            if [ "$update_count" -gt 0 ]; then
                log_message "INFO" "$update_count package(s) available for upgrade"
                yum list updates >> "$REPORT_FILE" 2>/dev/null
            else
                log_message "SUCCESS" "All packages are up to date"
            fi
            ;;
        "pacman")
            update_count=$(pacman -Qu 2>/dev/null | wc -l || true)
            if [ "$update_count" -gt 0 ]; then
                log_message "INFO" "$update_count package(s) available for upgrade"
                pacman -Qu >> "$REPORT_FILE" 2>/dev/null
            else
                log_message "SUCCESS" "All packages are up to date"
            fi
            ;;
    esac
    
    echo "" >> "$REPORT_FILE"
    echo "$update_count"
}

# Function to perform system updates
perform_updates() {
    local pkg_manager="$1"
    local auto_update="$2"
    
    if [ "$auto_update" != "true" ]; then
        log_message "INFO" "Auto-update disabled. Skipping package updates."
        return 0
    fi
    
    log_message "INFO" "Performing system updates..."
    
    echo "=== SYSTEM UPDATES ===" >> "$REPORT_FILE"
    
    case "$pkg_manager" in
        "apt")
            if sudo apt upgrade -y >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "System packages updated successfully"
            else
                log_message "ERROR" "Failed to update system packages"
                return 1
            fi
            ;;
        "dnf")
            if sudo dnf upgrade -y >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "System packages updated successfully"
            else
                log_message "ERROR" "Failed to update system packages"
                return 1
            fi
            ;;
        "yum")
            if sudo yum update -y >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "System packages updated successfully"
            else
                log_message "ERROR" "Failed to update system packages"
                return 1
            fi
            ;;
        "pacman")
            if sudo pacman -Su --noconfirm >> "$REPORT_FILE" 2>&1; then
                log_message "SUCCESS" "System packages updated successfully"
            else
                log_message "ERROR" "Failed to update system packages"
                return 1
            fi
            ;;
    esac
    
    echo "" >> "$REPORT_FILE"
}

# Function to check for security updates
check_security_updates() {
    local pkg_manager="$1"
    
    log_message "INFO" "Checking for security updates..."
    
    echo "=== SECURITY UPDATES ===" >> "$REPORT_FILE"
    
    case "$pkg_manager" in
        "apt")
            if command -v unattended-upgrade &> /dev/null; then
                unattended-upgrade --dry-run >> "$REPORT_FILE" 2>&1 || true
            fi
            ;;
        "dnf")
            dnf updateinfo list security >> "$REPORT_FILE" 2>/dev/null || true
            ;;
        "yum")
            yum updateinfo list security >> "$REPORT_FILE" 2>/dev/null || true
            ;;
    esac
    
    echo "" >> "$REPORT_FILE"
}

# Function to check system services
check_system_services() {
    log_message "INFO" "Checking critical system services..."
    
    echo "=== SYSTEM SERVICES STATUS ===" >> "$REPORT_FILE"
    
    local services=("ssh" "sshd" "systemd-resolved" "networkd" "cron" "crond")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "$service: RUNNING" >> "$REPORT_FILE"
        elif systemctl list-unit-files --type=service | grep -q "^$service.service"; then
            echo "$service: STOPPED" >> "$REPORT_FILE"
            log_message "WARNING" "Service $service is not running"
        fi
    done
    
    echo "" >> "$REPORT_FILE"
}

# Function to check system logs for errors
check_system_logs() {
    log_message "INFO" "Checking system logs for recent errors..."
    
    echo "=== RECENT SYSTEM ERRORS ===" >> "$REPORT_FILE"
    
    # Check journalctl for errors in the last 24 hours
    if command -v journalctl &> /dev/null; then
        journalctl --since "24 hours ago" --priority=err --no-pager >> "$REPORT_FILE" 2>/dev/null || true
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Function to generate summary
generate_summary() {
    local pkg_manager="$1"
    local update_count="$2"
    local start_time="$3"
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_message "INFO" "Generating summary report..."
    
    cat > "$SUMMARY_FILE" << EOF
===========================================
SYSTEM CHECK SUMMARY REPORT
===========================================
Date: $(date)
Hostname: $(hostname)
Package Manager: $pkg_manager
Start Time: $start_time
End Time: $end_time
Duration: $(($(date -d "$end_time" +%s) - $(date -d "$start_time" +%s))) seconds

RESULTS:
- Available Updates: $update_count package(s)
- Detailed Report: $REPORT_FILE

RECOMMENDATIONS:
EOF

    if [ "$update_count" -gt 0 ]; then
        echo "- Consider applying available updates" >> "$SUMMARY_FILE"
    else
        echo "- System is up to date" >> "$SUMMARY_FILE"
    fi
    
    # Check for high disk usage
    if df -h | awk 'NR>1 {gsub(/%/,"",$5); if($5>80) print $0}' | grep -q .; then
        echo "- WARNING: High disk usage detected" >> "$SUMMARY_FILE"
    fi
    
    echo "" >> "$SUMMARY_FILE"
    echo "For detailed information, check: $REPORT_FILE" >> "$SUMMARY_FILE"
}

# Function to send popup notification
send_popup_notification() {
    local message="$1"
    
    if command -v notify-send &> /dev/null; then
        notify-send "System Check Complete" "$message"
    elif command -v zenity &> /dev/null; then
        zenity --info --text="System Check Complete\n\n$message"
    else
        log_message "WARNING" "No notification system found. Summary saved to: $SUMMARY_FILE"
    fi
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        # Create default configuration
        cat > "$CONFIG_FILE" << EOF
# System Checker Configuration
AUTO_UPDATE=false
SHOW_POPUP=true
KEEP_LOGS_DAYS=30
CHECK_SECURITY=true
CHECK_SERVICES=true
CHECK_LOGS=true
EOF
        log_message "INFO" "Created default configuration file: $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Function to cleanup old logs
cleanup_old_logs() {
    local keep_days="${KEEP_LOGS_DAYS:-30}"
    
    find "$LOG_DIR" -name "system-report-*.log" -type f -mtime "+$keep_days" -delete 2>/dev/null || true
    log_message "INFO" "Cleaned up logs older than $keep_days days"
}

# Main execution function
main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "=== LINUX SYSTEM CHECKER STARTED ===" >> "$REPORT_FILE"
    log_message "INFO" "Starting system check and update process..."
    
    # Load configuration
    load_config
    
    # Detect package manager
    local pkg_manager=$(detect_package_manager)
    log_message "INFO" "Detected package manager: $pkg_manager"
    
    # Cleanup old logs
    cleanup_old_logs
    
    # Collect system information
    get_system_info
    
    # Check disk space
    check_disk_space
    
    # Update package lists
    update_package_lists "$pkg_manager"
    
    # Check for available updates
    local update_count=$(check_available_updates "$pkg_manager")
    
    # Check for security updates if enabled
    if [ "${CHECK_SECURITY:-true}" == "true" ]; then
        check_security_updates "$pkg_manager"
    fi
    
    # Check system services if enabled
    if [ "${CHECK_SERVICES:-true}" == "true" ]; then
        check_system_services
    fi
    
    # Check system logs if enabled
    if [ "${CHECK_LOGS:-true}" == "true" ]; then
        check_system_logs
    fi
    
    # Perform updates if auto-update is enabled
    if [ "${AUTO_UPDATE:-false}" == "true" ]; then
        perform_updates "$pkg_manager" "$AUTO_UPDATE"
    fi
    
    # Generate summary
    generate_summary "$pkg_manager" "$update_count" "$start_time"
    
    log_message "SUCCESS" "System check completed successfully"
    echo "=== LINUX SYSTEM CHECKER COMPLETED ===" >> "$REPORT_FILE"
    
    # Show popup notification if enabled
    if [ "${SHOW_POPUP:-true}" == "true" ]; then
        local summary_msg="Updates available: $update_count\nReport saved to: $REPORT_FILE"
        send_popup_notification "$summary_msg"
    fi
    
    # Display summary
    cat "$SUMMARY_FILE"
}

# Help function
show_help() {
    cat << EOF
Linux System Checker and Auto-Updater

Usage: $0 [OPTIONS]

OPTIONS:
    --auto-update       Enable automatic package updates
    --no-popup         Disable popup notifications
    --help             Show this help message

Configuration file: $CONFIG_FILE
Log directory: $LOG_DIR

Supported package managers: apt, dnf, yum, pacman
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-update)
            AUTO_UPDATE=true
            shift
            ;;
        --no-popup)
            SHOW_POPUP=false
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main
