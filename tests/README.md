# Tests for copy-claude-response

This directory contains comprehensive tests for the `copy-claude-response` script, focusing on macOS functionality.

## Test Framework

Uses **Bats (Bash Automated Testing System)** for lightweight bash script testing.

## Test Structure

```
tests/
├── test_copy_claude_response.bats  # Main test suite
├── test_helpers.bash               # Test utilities and mocks
├── fixtures/                       # Test data
│   └── sample_transcript.json      # Mock Claude transcript
├── run_tests.sh                    # Test runner script
└── README.md                       # This file
```

## Running Tests

### Prerequisites

Install dependencies:
```bash
make install-deps
# or manually:
brew install bats-core jq
```

### Run All Tests
```bash
make test
# or directly:
./tests/run_tests.sh
```

### Run Tests with Verbose Output
```bash
make test-verbose
# or directly:
cd tests && bats --verbose-run test_copy_claude_response.bats
```

## Test Coverage

### Unit Tests
- **`generate_preview()`**
  - ✅ Short text handling
  - ✅ Long text truncation with ellipsis
  - ✅ Empty input handling
  - ✅ Whitespace-only input
  - ✅ UTF-8 character preservation

- **`format_time_ago()`**
  - ✅ Seconds ago formatting
  - ✅ Minutes ago formatting  
  - ✅ Hours ago formatting
  - ✅ Empty timestamp handling

- **`copy_to_clipboard()` (macOS)**
  - ✅ pbcopy integration
  - ✅ UTF-8 content preservation

### Integration Tests

- **Command Pattern Matching**
  - ✅ `/copy-response` recognition
  - ✅ `/copy-prompt` recognition
  - ✅ Numbered commands (`/copy-response 2`)
  - ✅ Non-matching command passthrough

- **List Mode**
  - ✅ `/copy-response list` 
  - ✅ `/copy-prompt list`
  - ✅ List with count (`list 3`)
  - ✅ Timestamp display
  - ✅ Preview truncation

- **Find Mode**
  - ✅ `/copy-response find "text"`
  - ✅ `/copy-prompt find "text"`
  - ✅ Matching results display
  - ✅ No results handling

- **Debug Mode**
  - ✅ Debug output format
  - ✅ Content details (byte/character count)

### End-to-End Tests

- **Content Processing**
  - ✅ Multi-part response grouping
  - ✅ UTF-8 content handling
  - ✅ Empty response handling
  - ✅ Request ID grouping

- **Error Handling**
  - ✅ Invalid response numbers
  - ✅ Missing transcript files
  - ✅ Graceful degradation

- **JSON Output**
  - ✅ Valid JSON response format
  - ✅ Proper decision/reason structure

## Mock Setup

### Test Environment
- **Clipboard**: Mocks `pbcopy` to capture clipboard content
- **Transcript**: Uses `fixtures/sample_transcript.json` with various message types
- **Timestamps**: Dynamic timestamp generation for time-ago testing

### Test Data
The sample transcript includes:
- Multi-part assistant responses
- Various user prompts
- UTF-8 content
- Empty messages
- Long content for truncation testing

## Platform Focus

Tests are **macOS-specific** and focus on:
- `pbcopy` clipboard integration
- macOS-specific timestamp handling
- UTF-8 encoding with macOS tools

## Cleanup

Clean up test artifacts:
```bash
make clean
```

## Adding New Tests

1. Add test cases to `test_copy_claude_response.bats`
2. Use helpers from `test_helpers.bash`
3. Add test data to `fixtures/` if needed
4. Follow existing naming conventions:
   - Unit tests: `@test "function_name does something"`
   - Integration: `@test "script handles command"`
   - E2E: `@test "end-to-end scenario"`