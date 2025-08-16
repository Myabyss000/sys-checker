# Linux System Checker & Auto-Updater
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

An automated system maintenance tool for Linux that checks for package updates, monitors system health, and provides detailed reports. Supports multiple Linux distributions and package managers.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/Myabyss000/sys-checker.git
cd sys-checker

# Install and run
sudo make install
system-checker
```

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#-quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Scheduling](#scheduling)
- [Output and Logs](#output-and-logs)
- [Supported Distributions](#supported-distributions)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

### 🚀 Core Functionality
- **Multi-Distribution Support**: Works with Ubuntu/Debian (apt), RHEL/CentOS/Fedora (yum/dnf), and Arch Linux (pacman)
- **Automated Package Management**: Check for updates and optionally install them automatically
- **System Health Monitoring**: Disk space, services, and system logs checking
- **Security Updates**: Special handling for security-related updates
- **Comprehensive Reporting**: Detailed logs and summary reports
- **Flexible Scheduling**: Support for both cron and systemd timers

### 📊 Monitoring Capabilities
- System information collection (OS, kernel, uptime, memory, disk usage)
- Package update availability checking
- Security update identification
- Critical system service status monitoring
- Recent system error log analysis
- Disk space usage alerts (warnings for >80% usage)

### 🔧 Notification Options
- Desktop popup notifications (notify-send, zenity)
- Detailed log files with timestamps
- Summary reports for quick overview
- Configurable notification preferences

## Installation

### Quick Install
```bash
# Clone or download the repository
git clone https://github.com/Myabyss000/sys-checker.git
cd sys-checker

# Make scripts executable and install
chmod +x *.sh
sudo ./install.sh
```

### One-Line Install from GitHub
```bash
# Download and install latest release directly
curl -fsSL https://raw.githubusercontent.com/Myabyss000/sys-checker/main/quick-install.sh | sudo bash
```

### Manual Installation
```bash
# Copy files to system location
sudo mkdir -p /opt/system-checker
sudo cp system-checker.sh /opt/system-checker/
sudo cp config.conf /opt/system-checker/
sudo chmod +x /opt/system-checker/system-checker.sh

# Create symbolic link for easy access
sudo ln -sf /opt/system-checker/system-checker.sh /usr/local/bin/system-checker

# Set up scheduling (choose one)
# Option 1: Cron (daily at 2 AM)
echo "0 2 * * * /opt/system-checker/system-checker.sh >/dev/null 2>&1" | sudo crontab -

# Option 2: Systemd timer (see systemd setup below)
```

## Usage

### Basic Commands
```bash
# Run system check
system-checker

# Run with automatic updates enabled
system-checker --auto-update

# Run without popup notifications
system-checker --no-popup

# Show help
system-checker --help
```

### Configuration
Edit `/opt/system-checker/config.conf` to customize behavior:

```bash
# Enable/disable automatic updates (DANGEROUS - use with caution)
AUTO_UPDATE=false

# Show popup notifications
SHOW_POPUP=true

# Keep log files for X days
KEEP_LOGS_DAYS=30

# Enable different check types
CHECK_SECURITY=true
CHECK_SERVICES=true
CHECK_LOGS=true
```

## Scheduling

### Cron Setup
The installation script can set up a daily cron job automatically, or you can configure it manually:

```bash
# Edit crontab
sudo crontab -e

# Add daily check at 2 AM
0 2 * * * /opt/system-checker/system-checker.sh >/dev/null 2>&1

# Alternative schedules:
# Every 6 hours: 0 */6 * * *
# Weekly on Sunday: 0 2 * * 0
# Monthly on 1st: 0 2 1 * *
```

### Systemd Timer Setup
For modern systems, use systemd timers:

```bash
# Enable and start the timer (if created during installation)
sudo systemctl enable --now system-checker.timer

# Check timer status
sudo systemctl status system-checker.timer

# View timer logs
sudo journalctl -u system-checker.service
```

### Custom Systemd Service (Manual)
If you need to create the systemd service manually:

```bash
# Create service file
sudo tee /etc/systemd/system/system-checker.service << EOF
[Unit]
Description=System Package Checker and Updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/system-checker/system-checker.sh
User=root
WorkingDirectory=/opt/system-checker

[Install]
WantedBy=multi-user.target
EOF

# Create timer file
sudo tee /etc/systemd/system/system-checker.timer << EOF
[Unit]
Description=Run System Checker Daily
Requires=system-checker.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1800

[Timer]
WantedBy=timers.target
EOF

# Reload and enable
sudo systemctl daemon-reload
sudo systemctl enable --now system-checker.timer
```

## Output and Logs

### Log Locations
- **Detailed Reports**: `/opt/system-checker/logs/system-report-YYYYMMDD-HHMMSS.log`
- **Latest Summary**: `/opt/system-checker/logs/latest-summary.log`
- **Configuration**: `/opt/system-checker/config.conf`

### Sample Report Structure
```
=== SYSTEM INFORMATION ===
Hostname: server01
OS: Ubuntu 22.04.3 LTS
Kernel: 5.15.0-91-generic
Architecture: x86_64
Uptime: up 5 days, 3 hours, 22 minutes
Memory Usage: 2.1G/7.8G
Disk Usage: 45G/98G (47% used)

=== AVAILABLE UPDATES ===
12 package(s) available for upgrade

=== SECURITY UPDATES ===
3 security updates available

=== SYSTEM SERVICES STATUS ===
ssh: RUNNING
cron: RUNNING
systemd-resolved: RUNNING
```

## Supported Distributions

### Tested Distributions
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 10, 11, 12
- **CentOS**: 7, 8 (Stream)
- **RHEL**: 7, 8, 9
- **Fedora**: 35+
- **Arch Linux**: Current

### Package Managers
- **APT** (apt): Ubuntu, Debian, and derivatives
- **DNF** (dnf): Fedora 22+, RHEL 8+, CentOS 8+
- **YUM** (yum): CentOS 7, RHEL 7, older Fedora
- **Pacman** (pacman): Arch Linux, Manjaro

## Security Considerations

### Permissions
- The script requires sudo/root access for package management
- Log files are created with appropriate permissions
- Configuration file should be protected from unauthorized access

### Auto-Update Safety
- **AUTO_UPDATE=false** by default for safety
- When enabled, only updates packages without removing or installing new ones
- Test thoroughly before enabling in production environments
- Consider using `--auto-update` flag for manual control instead

### Network Requirements
- Internet connection required for package manager operations
- Script handles network timeouts gracefully
- Can work offline for system health checks only

## Troubleshooting

### Quick Diagnostics
Run the built-in troubleshooting tool to diagnose common issues:

```bash
# Run troubleshooting diagnostics
make troubleshoot
# or directly:
./troubleshoot.sh
```

### Common Issues

**Permission Denied**
```bash
# Ensure script is executable
chmod +x /opt/system-checker/system-checker.sh

# Run with proper privileges
sudo system-checker
```

**Package Manager Not Found**
```bash
# The script auto-detects package managers
# Ensure your distribution's package manager is installed and in PATH
```

**Notifications Not Showing**
```bash
# Install notification dependencies
# Ubuntu/Debian/Kali:
sudo apt install libnotify-bin zenity

# RHEL/CentOS/Fedora:
sudo dnf install libnotify zenity
# or
sudo yum install libnotify zenity

# Arch:
sudo pacman -S libnotify zenity
```

**Installation Dependencies Error**
```bash
# If you get "Unable to locate package notify-send" or similar:
# The correct package names are:
sudo apt install libnotify-bin zenity  # NOT notify-send

# Run troubleshooting to check all dependencies:
make troubleshoot
```

# RHEL/CentOS/Fedora:
sudo dnf install libnotify zenity
# or
sudo yum install libnotify zenity

# Arch:
sudo pacman -S libnotify zenity
```

**Cron Job Not Running**
```bash
# Check if cron service is running
sudo systemctl status cron
# or
sudo systemctl status crond

# Check cron logs
sudo journalctl -u cron
# or
tail -f /var/log/cron
```

### Log Analysis
```bash
# View latest summary
cat /opt/system-checker/logs/latest-summary.log

# View detailed logs
ls -la /opt/system-checker/logs/
tail -f /opt/system-checker/logs/system-report-*.log

# Check for errors in logs
grep -i error /opt/system-checker/logs/system-report-*.log
```

## Contributing

### Development
- Script is written in Bash for maximum compatibility
- Follows best practices for error handling and logging
- Modular design for easy extension

### Adding New Features
1. Fork the repository
2. Create a feature branch
3. Add your functionality following existing patterns
4. Test on multiple distributions
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or contributions:
1. **Run Diagnostics**: `make troubleshoot` - Use the built-in troubleshooting tool
2. **Check Documentation**: Review the [README](https://github.com/Myabyss000/sys-checker/blob/main/README.md) and troubleshooting sections
3. **Search Issues**: Check [existing issues](https://github.com/Myabyss000/sys-checker/issues) for similar problems
4. **Create New Issue**: [Report bugs or request features](https://github.com/Myabyss000/sys-checker/issues/new/choose)
5. **Security Issues**: Use [GitHub Security Advisories](https://github.com/Myabyss000/sys-checker/security/advisories/new) for security concerns
6. **Contribute**: See [CONTRIBUTING.md](https://github.com/Myabyss000/sys-checker/blob/main/CONTRIBUTING.md) for contribution guidelines

**Repository**: https://github.com/Myabyss000/sys-checker

---

**⚠️ Important Notes:**
- Always test in a non-production environment first
- Review logs regularly for any issues
- Keep the configuration file secure
- Monitor disk space in log directory
- Consider backup strategies for critical systems

