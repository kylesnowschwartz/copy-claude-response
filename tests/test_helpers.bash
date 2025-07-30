#!/bin/bash

# Test helpers for copy-claude-response script

# Get the absolute path to the script and test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/copy-claude-response"
FIXTURES_DIR="$TEST_DIR/fixtures"

# Source the main script functions for unit testing
# We need to extract functions without executing the main logic
source_script_functions() {
    # Extract only the function definitions from the script
    # Skip the main execution logic at the bottom
    sed -n '/^# Function to generate preview/,/^# Read hook input/p' "$SCRIPT_PATH" | head -n -2
}

# Create a temporary transcript file for testing
create_test_transcript() {
    local transcript_file="$1"
    cp "$FIXTURES_DIR/sample_transcript.json" "$transcript_file"
}

# Mock pbcopy command for macOS testing
setup_pbcopy_mock() {
    export PBCOPY_FILE=$(mktemp)
    
    # Create a mock pbcopy function that captures input to a file
    pbcopy() {
        cat > "$PBCOPY_FILE"
    }
    export -f pbcopy
}

# Verify pbcopy was called with expected content
assert_pbcopy_called_with() {
    local expected="$1"
    local actual=""
    if [[ -f "$PBCOPY_FILE" ]]; then
        actual=$(cat "$PBCOPY_FILE")
    fi
    if [[ "$actual" != "$expected" ]]; then
        echo "Expected pbcopy to be called with: '$expected'"
        echo "But was called with: '$actual'"
        return 1
    fi
}

# Create mock hook input JSON
create_hook_input() {
    local prompt="$1"
    local transcript_path="$2"
    
    cat <<EOF
{
    "prompt": "$prompt",
    "transcript_path": "$transcript_path"
}
EOF
}

# Clean up test files
cleanup_test_files() {
    rm -f /tmp/test_transcript_*.json
    rm -f /tmp/test_input_*.json
    if [[ -n "$PBCOPY_FILE" && -f "$PBCOPY_FILE" ]]; then
        rm -f "$PBCOPY_FILE"
    fi
}

# Set up test environment with all mocks
setup_test_env() {
    setup_pbcopy_mock
    
    # Ensure jq is available (required by script)
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq is required for testing"
    fi
}

# Calculate time ago for testing timestamps (macOS compatible)
get_seconds_ago() {
    local seconds="$1"
    # Use Python for cross-platform compatibility
    python3 -c "
import datetime
now = datetime.datetime.now(datetime.timezone.utc)
past = now - datetime.timedelta(seconds=$seconds)
print(past.strftime('%Y-%m-%dT%H:%M:%SZ'))
"
}

# Create timestamp that is N seconds ago (macOS compatible)
timestamp_seconds_ago() {
    local seconds="$1"
    python3 -c "
import datetime
now = datetime.datetime.now(datetime.timezone.utc)
past = now - datetime.timedelta(seconds=$seconds)
print(past.strftime('%Y-%m-%dT%H:%M:%SZ'))
"
}

# Helper to run the script with input
run_script_with_input() {
    local input="$1"
    echo "$input" | "$SCRIPT_PATH"
}

# Extract functions from script for unit testing
extract_functions() {
    # Create a temporary file with just the functions
    local temp_file=$(mktemp)
    
    # Extract just the function definitions we need
    cat > "$temp_file" << 'EOF'
# Constants
PREVIEW_LENGTH=60

# Function to generate preview text for responses
generate_preview() {
    local response="$1"
    # Get first non-empty line as preview (truncate if too long)
    # Use printf and tr to preserve UTF-8 encoding - match main script behavior
    local preview=$(printf '%s' "$response" | grep -m1 -v '^[[:space:]]*$' | cut -c1-$PREVIEW_LENGTH | tr -d '\n\r')
    if [ -z "$preview" ]; then
        preview="<empty response>"
    elif [ ${#preview} -eq $PREVIEW_LENGTH ]; then
        preview="${preview}..."
    fi
    echo "$preview"
}

# Function to format timestamp as "time ago" display (macOS compatible)
format_time_ago() {
    local timestamp="$1"
    local time_display=""
    if [[ -n "$timestamp" ]]; then
        # Calculate time ago using python for cross-platform compatibility
        local now_epoch=$(date +%s)
        local msg_epoch=$(python3 -c "
import datetime
try:
    dt = datetime.datetime.fromisoformat('$timestamp'.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print($now_epoch)
")
        local diff_sec=$((now_epoch - msg_epoch))
        
        if [[ $diff_sec -lt 60 ]]; then
            time_display=$(printf "[%4.1f sec ago]" "$diff_sec")
        elif [[ $diff_sec -lt 3600 ]]; then
            local diff_min=$(python3 -c "print($diff_sec / 60)")
            time_display=$(printf "[%4.1f min ago]" "$diff_min")
        else
            local diff_hr=$(python3 -c "print($diff_sec / 3600)")
            time_display=$(printf "[%4.2f hrs ago]" "$diff_hr")
        fi
    fi
    echo "$time_display"
}

# Function to copy text to clipboard (cross-platform)
copy_to_clipboard() {
    local text="$1"
    # In test mode, always use the mocked pbcopy function
    if declare -F pbcopy >/dev/null 2>&1; then
        # pbcopy function exists (mocked)
        printf '%s' "$text" | pbcopy
    elif command -v pbcopy >/dev/null 2>&1; then
        # macOS - printf preserves UTF-8 better than echo
        printf '%s' "$text" | pbcopy
    elif command -v xclip >/dev/null 2>&1; then
        # Linux - printf preserves UTF-8 better than echo
        printf '%s' "$text" | xclip -selection clipboard
    elif command -v clip.exe >/dev/null 2>&1; then
        # Windows/WSL - write to temp file with UTF-8 BOM then read back
        local temp_file=$(mktemp)
        printf '\xEF\xBB\xBF%s' "$text" > "$temp_file"
        powershell.exe -Command "Get-Content -Path '$(wslpath -w "$temp_file")' -Encoding UTF8 | Set-Clipboard"
        rm "$temp_file"
    else
        echo "No clipboard utility found (pbcopy, xclip, or clip.exe)" >&2
        exit 1
    fi
}
EOF
    
    echo "$temp_file"
}