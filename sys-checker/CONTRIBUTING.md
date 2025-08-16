# Contributing to System Checker

Thank you for your interest in contributing to the System Checker project! This document provides guidelines for contributing to the project.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed and what behavior you expected**
- **Include system information** (OS, distribution, package manager)
- **Include relevant log files** from `/opt/system-checker/logs/`

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **Specify which distributions/package managers it should support**

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Test your changes** on multiple distributions if possible
3. **Ensure your code follows the existing style**
4. **Add tests** for new functionality
5. **Update documentation** as needed
6. **Make sure all tests pass**

## Development Guidelines

### Code Style

- Use **Bash best practices** (set -euo pipefail, quote variables, etc.)
- **Consistent indentation** (2 spaces for Bash scripts)
- **Meaningful variable names** and comments
- **Error handling** for all external commands
- **Logging** for important operations

### Testing

- Test on multiple Linux distributions:
  - Ubuntu/Debian (apt)
  - CentOS/RHEL/Fedora (yum/dnf)
  - Arch Linux (pacman)
- Run the test suite: `make test`
- Test both with and without auto-update enabled
- Verify logging and notification functionality

### Adding Support for New Package Managers

When adding support for a new package manager:

1. Add detection logic in `detect_package_manager()`
2. Add update logic in `update_package_lists()`, `check_available_updates()`, and `perform_updates()`
3. Add security update checking in `check_security_updates()` if supported
4. Update documentation in README.md
5. Add test cases

## Project Structure

```
sys-checker/
├── system-checker.sh      # Main script
├── config.conf           # Configuration file
├── install.sh            # Installation script
├── uninstall.sh          # Removal script
├── test.sh               # Test suite
├── Makefile              # Build automation
├── README.md             # Main documentation
├── CONTRIBUTING.md       # This file
├── LICENSE               # MIT License
├── .gitignore            # Git ignore rules
├── system-checker.service # Systemd service
├── system-checker.timer  # Systemd timer
└── crontab.example       # Cron examples
```

## Commit Messages

Use clear and meaningful commit messages:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools

Examples:
```
feat: add support for Alpine Linux (apk package manager)
fix: handle package manager timeout errors gracefully
docs: update installation instructions for Arch Linux
test: add integration tests for dnf package manager
```

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Test on all supported distributions
4. Create pull request
5. After merge, tag the release
6. Update release notes on GitHub

## Getting Help

- Check the [README.md](README.md) for usage instructions
- Look at existing [issues](../../issues) for similar problems
- Create a new issue with detailed information
- Join discussions in existing issues

## Recognition

Contributors will be acknowledged in:
- README.md contributors section
- Release notes
- Git commit history

Thank you for contributing to System Checker!
