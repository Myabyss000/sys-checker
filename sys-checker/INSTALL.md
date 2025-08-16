# Quick Installation Guide

## Method 1: One-Line Install (Recommended)

```bash
# Download and install latest release automatically
curl -fsSL https://raw.githubusercontent.com/Myabyss000/sys-checker/main/quick-install.sh | sudo bash
```

## Method 2: Clone and Install

```bash
# Clone the repository
git clone https://github.com/Myabyss000/sys-checker.git
cd sys-checker

# Set permissions and install
make permissions
sudo make install
```

## Method 3: Manual Download

1. Go to https://github.com/Myabyss000/sys-checker/releases
2. Download the latest release archive
3. Extract and run:
```bash
tar -xzf system-checker-v*.tar.gz
cd system-checker-v*
chmod +x *.sh
sudo ./install.sh
```

## After Installation

```bash
# Test the installation
system-checker --help

# Run a system check
system-checker

# Run with auto-updates (careful!)
system-checker --auto-update
```

## Troubleshooting

If you encounter issues:
```bash
# Run diagnostics
make troubleshoot

# Check logs
tail -f /opt/system-checker/logs/latest-summary.log

# Get help
# Visit: https://github.com/Myabyss000/sys-checker/issues
```
