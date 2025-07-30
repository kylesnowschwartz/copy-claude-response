# Makefile for copy-claude-response

.PHONY: test test-verbose install-deps clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test         - Run all tests"
	@echo "  test-verbose - Run tests with verbose output"
	@echo "  install-deps - Install test dependencies (bats, jq)"
	@echo "  clean        - Clean up test artifacts"
	@echo "  help         - Show this help message"

# Run tests
test:
	@./tests/run_tests.sh

# Run tests with verbose output
test-verbose:
	@cd tests && bats --verbose-run test_copy_claude_response.bats

# Install test dependencies on macOS
install-deps:
	@echo "Installing test dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing bats-core and jq via Homebrew..."; \
		brew install bats-core jq; \
	else \
		echo "Homebrew not found. Please install manually:"; \
		echo "  - bats: https://github.com/bats-core/bats-core"; \
		echo "  - jq: https://stedolan.github.io/jq/"; \
	fi

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@rm -f /tmp/test_transcript_*.json
	@rm -f /tmp/test_input_*.json
	@find tests -name "*.tmp" -delete 2>/dev/null || true
	@echo "Clean complete."