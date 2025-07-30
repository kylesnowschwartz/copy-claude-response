#!/bin/bash

# Test runner for copy-claude-response script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}Copy Claude Response Test Suite${NC}"
echo "==============================="

# Check if bats is installed
if ! command -v bats >/dev/null 2>&1; then
    echo -e "${RED}Error: bats is not installed${NC}"
    echo ""
    echo "Install bats using Homebrew:"
    echo "  brew install bats-core"
    echo ""
    echo "Or using npm:"
    echo "  npm install -g bats"
    exit 1
fi

# Check if jq is installed (required by the script)
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo ""
    echo "Install jq using Homebrew:"
    echo "  brew install jq"
    exit 1
fi

# Check if the main script exists
MAIN_SCRIPT="$PROJECT_DIR/copy-claude-response"
if [[ ! -f "$MAIN_SCRIPT" ]]; then
    echo -e "${RED}Error: Main script not found at $MAIN_SCRIPT${NC}"
    exit 1
fi

# Make sure the script is executable
chmod +x "$MAIN_SCRIPT"

echo -e "${YELLOW}Running tests...${NC}"
echo ""

# Run the tests
cd "$SCRIPT_DIR"
if bats test_copy_claude_response.bats; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo ""
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi