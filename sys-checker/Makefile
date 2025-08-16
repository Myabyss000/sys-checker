# System Checker Makefile

.PHONY: help install uninstall test clean permissions troubleshoot

help:
	@echo "Linux System Checker & Auto-Updater"
	@echo ""
	@echo "Available targets:"
	@echo "  help        - Show this help message"
	@echo "  permissions - Set correct file permissions"
	@echo "  test        - Run test suite"
	@echo "  troubleshoot- Run troubleshooting diagnostics"
	@echo "  install     - Install system-checker (requires sudo)"
	@echo "  uninstall   - Uninstall system-checker (requires sudo)"
	@echo "  clean       - Clean up log files and temporary files"
	@echo ""
	@echo "Usage examples:"
	@echo "  make permissions    # Set up file permissions"
	@echo "  make troubleshoot   # Diagnose common issues"
	@echo "  make test           # Test the installation"
	@echo "  sudo make install   # Install system-wide"

permissions:
	@echo "Setting file permissions..."
	chmod +x system-checker.sh
	chmod +x install.sh
	chmod +x uninstall.sh
	chmod +x test.sh
	chmod +x quick-install.sh
	chmod +x troubleshoot.sh
	chmod 644 config.conf
	chmod 644 README.md
	@echo "Permissions set successfully."

test: permissions
	@echo "Running test suite..."
	./test.sh

troubleshoot: permissions
	@echo "Running troubleshooting diagnostics..."
	./troubleshoot.sh

install: permissions
	@echo "Installing System Checker..."
	@if [ "$$EUID" -ne 0 ]; then \
		echo "Error: Installation requires root privileges. Use 'sudo make install'"; \
		exit 1; \
	fi
	./install.sh

uninstall:
	@echo "Uninstalling System Checker..."
	@if [ "$$EUID" -ne 0 ]; then \
		echo "Error: Uninstallation requires root privileges. Use 'sudo make uninstall'"; \
		exit 1; \
	fi
	./uninstall.sh

clean:
	@echo "Cleaning up temporary files..."
	rm -rf logs/
	rm -f config.conf.backup
	rm -f *.tmp
	@echo "Cleanup completed."
