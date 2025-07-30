# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code hook that adds `/copy-response` and `/copy-prompt` commands to copy Claude's responses or user prompts to the clipboard. The main script (`copy-claude-response`) is a bash hook that intercepts these commands before they reach Claude, parses the conversation transcript, and copies the requested content to the system clipboard.

## Key Commands

### Testing
```bash
# Run all tests
make test

# Run tests with verbose output
make test-verbose

# Install test dependencies (bats, jq)
make install-deps

# Alternative test runner
./tests/run_tests.sh
```

### Development
```bash
# Clean up test artifacts
make clean

# Make script executable (if needed)
chmod +x copy-claude-response
```

## Architecture

### Core Components

- **copy-claude-response**: Main bash script that implements the Claude Code hook
- **tests/**: Complete test suite using BATS (Bash Automated Testing System)
  - `test_copy_claude_response.bats`: 34 comprehensive test cases
  - `test_helpers.bash`: Test utilities and setup functions
  - `fixtures/sample_transcript.json`: Sample conversation data

### Hook Mechanism

The script works as a `UserPromptSubmit` hook that:
1. Intercepts commands matching `/copy-(response|prompt)` pattern
2. Parses the Claude Code transcript JSON using `jq`
3. Extracts and groups multi-part messages by request ID
4. Copies selected content to clipboard using platform-specific utilities
5. Blocks the command from reaching Claude by returning `{"decision": "block"}`

### Cross-Platform Clipboard Support

- **macOS**: Uses `pbcopy`
- **Linux**: Uses `xclip` 
- **Windows/WSL**: Uses `clip.exe` via PowerShell with UTF-8 BOM handling

### Command Patterns

- `/copy-response` or `/copy-prompt`: Copy latest item
- `/copy-response 3`: Copy specific numbered item
- `/copy-response list`: List available items with previews
- `/copy-response find "keyword"`: Search for items containing text

## Dependencies

- **bash**: Main script language
- **jq**: JSON parsing (required at runtime)
- **bats**: Testing framework (dev dependency)
- Platform clipboard utility: `pbcopy`, `xclip`, or `clip.exe`

## Testing Strategy

The test suite covers:
- Unit tests for utility functions (`generate_preview`, `format_time_ago`)
- Integration tests for full command workflows
- Error handling and edge cases
- UTF-8 character preservation
- Cross-platform clipboard functionality

Tests use temporary files and mock transcript data to avoid dependencies on actual Claude conversations.

## Important Implementation Details

- Uses `printf` instead of `echo` for UTF-8 preservation
- Handles multi-part Claude responses by grouping by request ID
- Implements time-based formatting (seconds, minutes, hours ago)
- Robust error handling for missing dependencies
- Preview generation with 60-character truncation