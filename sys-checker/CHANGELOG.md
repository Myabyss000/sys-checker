# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of System Checker
- Multi-distribution support (Ubuntu/Debian, RHEL/CentOS/Fedora, Arch Linux)
- Automatic package manager detection (apt, yum, dnf, pacman)
- Comprehensive system health monitoring
- Security update checking
- System service status monitoring
- Disk space monitoring with alerts
- Desktop notification support
- Configurable auto-update functionality
- Detailed logging with timestamps
- Summary report generation
- Cron job scheduling support
- Systemd timer support
- Installation and uninstallation scripts
- Test suite for validation
- Makefile for easy management

### Security
- Auto-update disabled by default for safety
- Comprehensive input validation
- Secure file permissions handling
- Log rotation to prevent disk space issues

## [1.0.0] - 2025-08-16

### Added
- Initial stable release
- Complete system checker functionality
- Full documentation and examples
- Installation automation
- Cross-distribution compatibility

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- Secure defaults for all configuration options
