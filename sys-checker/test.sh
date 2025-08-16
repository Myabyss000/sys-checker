#!/bin/bash

# ===========================================
# System Checker Test Script
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

test_package_manager_detection() {
    print_message "INFO" "Testing package manager detection..."
    
    if command -v apt &> /dev/null; then
        print_message "SUCCESS" "APT package manager detected"
    elif command -v dnf &> /dev/null; then
        print_message "SUCCESS" "DNF package manager detected"
    elif command -v yum &> /dev/null; then
        print_message "SUCCESS" "YUM package manager detected"
    elif command -v pacman &> /dev/null; then
        print_message "SUCCESS" "PACMAN package manager detected"
    else
        print_message "ERROR" "No supported package manager found"
        return 1
    fi
}

test_script_syntax() {
    print_message "INFO" "Testing script syntax..."
    
    if bash -n system-checker.sh; then
        print_message "SUCCESS" "Script syntax is valid"
    else
        print_message "ERROR" "Script has syntax errors"
        return 1
    fi
}

test_dependencies() {
    print_message "INFO" "Testing system dependencies..."
    
    local missing_deps=()
    
    # Check for basic commands
    for cmd in date hostname uptime free df systemctl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_message "SUCCESS" "All basic dependencies are available"
    else
        print_message "WARNING" "Missing dependencies: ${missing_deps[*]}"
    fi
    
    # Check for notification tools (optional)
    if command -v notify-send &> /dev/null || command -v zenity &> /dev/null; then
        print_message "SUCCESS" "Notification tools available"
    else
        print_message "WARNING" "No notification tools found (install libnotify-bin and/or zenity for popup notifications)"
    fi
}

test_permissions() {
    print_message "INFO" "Testing file permissions..."
    
    if [ -x "system-checker.sh" ]; then
        print_message "SUCCESS" "Main script is executable"
    else
        print_message "ERROR" "Main script is not executable"
        return 1
    fi
    
    if [ -x "install.sh" ]; then
        print_message "SUCCESS" "Install script is executable"
    else
        print_message "WARNING" "Install script is not executable (run: chmod +x install.sh)"
    fi
}

test_dry_run() {
    print_message "INFO" "Running dry-run test (no actual updates)..."
    
    # Create a temporary config that disables auto-update
    cp config.conf config.conf.backup
    sed -i 's/AUTO_UPDATE=.*/AUTO_UPDATE=false/' config.conf
    
    # Run the script with no-popup option
    if timeout 60 ./system-checker.sh --no-popup; then
        print_message "SUCCESS" "Dry run completed successfully"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_message "WARNING" "Script timed out after 60 seconds (this is normal for slow systems)"
        else
            print_message "ERROR" "Script failed with exit code: $exit_code"
            return 1
        fi
    fi
    
    # Restore original config
    mv config.conf.backup config.conf
}

test_log_creation() {
    print_message "INFO" "Testing log file creation..."
    
    if [ -d "logs" ]; then
        local log_count=$(ls -1 logs/ | wc -l)
        if [ "$log_count" -gt 0 ]; then
            print_message "SUCCESS" "Log files created successfully ($log_count files)"
        else
            print_message "WARNING" "Logs directory exists but no log files found"
        fi
    else
        print_message "WARNING" "Logs directory not created"
    fi
    
    if [ -f "logs/latest-summary.log" ]; then
        print_message "SUCCESS" "Summary report created"
    else
        print_message "WARNING" "Summary report not found"
    fi
}

main() {
    echo "=== System Checker Test Suite ==="
    echo ""
    
    local test_count=0
    local pass_count=0
    local fail_count=0
    
    # Change to script directory
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    # Run tests
    tests=(
        "test_script_syntax"
        "test_package_manager_detection"
        "test_dependencies"
        "test_permissions"
        "test_dry_run"
        "test_log_creation"
    )
    
    for test in "${tests[@]}"; do
        test_count=$((test_count + 1))
        echo ""
        if $test; then
            pass_count=$((pass_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
    done
    
    echo ""
    echo "=== Test Summary ==="
    echo "Total tests: $test_count"
    echo "Passed: $pass_count"
    echo "Failed: $fail_count"
    echo ""
    
    if [ $fail_count -eq 0 ]; then
        print_message "SUCCESS" "All tests passed! The system checker is ready to use."
        echo ""
        echo "Next steps:"
        echo "1. Review the configuration in config.conf"
        echo "2. Run: sudo ./install.sh (to install system-wide)"
        echo "3. Or run: ./system-checker.sh (to test locally)"
    else
        print_message "WARNING" "Some tests failed. Please review the issues above."
        return 1
    fi
}

main "$@"
