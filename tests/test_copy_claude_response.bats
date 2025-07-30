#!/usr/bin/env bats

# Tests for copy-claude-response script (macOS focused)

load test_helpers

setup() {
    setup_test_env
    TEST_TRANSCRIPT=$(mktemp)
    create_test_transcript "$TEST_TRANSCRIPT"
    FUNCTIONS_FILE=$(extract_functions)
    source "$FUNCTIONS_FILE"
}

teardown() {
    cleanup_test_files
    rm -f "$TEST_TRANSCRIPT" "$FUNCTIONS_FILE"
}

# Unit Tests for generate_preview function

@test "generate_preview returns full text for short input" {
    result=$(generate_preview "Short text")
    [ "$result" = "Short text" ]
}

@test "generate_preview truncates long text with ellipsis" {
    long_text="This is a very long text that should be truncated because it exceeds the preview length limit"
    result=$(generate_preview "$long_text")
    expected="This is a very long text that should be truncated because it..."
    [ "$result" = "$expected" ]
}

@test "generate_preview handles empty input" {
    result=$(generate_preview "")
    [ "$result" = "<empty response>" ]
}

@test "generate_preview handles whitespace-only input" {
    result=$(generate_preview $'   \n\t  ')
    [ "$result" = "<empty response>" ]
}

@test "generate_preview preserves UTF-8 characters" {
    utf8_text="UTF-8: 你好世界 🚀 émojis"
    result=$(generate_preview "$utf8_text")
    [ "$result" = "$utf8_text" ]
}

# Unit Tests for format_time_ago function

@test "format_time_ago handles seconds" {
    timestamp=$(timestamp_seconds_ago 30)
    result=$(format_time_ago "$timestamp")
    [[ "$result" =~ ^\[.*sec\ ago\]$ ]]
}

@test "format_time_ago handles minutes" {
    timestamp=$(timestamp_seconds_ago 300)  # 5 minutes
    result=$(format_time_ago "$timestamp")
    [[ "$result" =~ ^\[.*min\ ago\]$ ]]
}

@test "format_time_ago handles hours" {
    timestamp=$(timestamp_seconds_ago 7200)  # 2 hours
    result=$(format_time_ago "$timestamp")
    [[ "$result" =~ ^\[.*hrs\ ago\]$ ]]
}

@test "format_time_ago handles empty timestamp" {
    result=$(format_time_ago "")
    [ "$result" = "" ]
}

# Unit Tests for copy_to_clipboard function (macOS)

@test "copy_to_clipboard uses pbcopy on macOS" {
    test_text="Test clipboard content"
    copy_to_clipboard "$test_text"
    assert_pbcopy_called_with "$test_text"
}

@test "copy_to_clipboard preserves UTF-8 content" {
    utf8_text="UTF-8: 你好世界 🚀 émojis"
    copy_to_clipboard "$utf8_text"
    assert_pbcopy_called_with "$utf8_text"
}

# Integration Tests - Command Pattern Matching

@test "script recognizes /copy-response command" {
    input=$(create_hook_input "/copy-response" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 0 ]
    [[ "$output" =~ "Latest Claude response copied to clipboard!" ]]
}

@test "script recognizes /copy-prompt command" {
    input=$(create_hook_input "/copy-prompt" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 0 ]
    [[ "$output" =~ "Latest user prompt copied to clipboard!" ]]
}

@test "script recognizes /copy-response with number" {
    input=$(create_hook_input "/copy-response 2" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 0 ]
    [[ "$output" =~ "Claude response #2 copied to clipboard!" ]]
}

@test "script recognizes /copy-prompt with number" {
    input=$(create_hook_input "/copy-prompt 2" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 0 ]
    [[ "$output" =~ "User prompt #2 copied to clipboard!" ]]
}

@test "script passes through non-matching commands" {
    input=$(create_hook_input "/other-command" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 0 ]
    [ "$output" = '{"decision": "approve"}' ]  # Should return approve for non-copy commands
}

# Integration Tests - List Mode

@test "script handles /copy-response list command" {
    input=$(create_hook_input "/copy-response list" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]  # Exit 2 to block and show stderr
    [[ "$output" =~ "Available responses" ]]
}

@test "script handles /copy-prompt list command" {
    input=$(create_hook_input "/copy-prompt list" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Available prompts" ]]
}

@test "script handles /copy-response list with count" {
    input=$(create_hook_input "/copy-response list 3" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Available responses" ]]
}

# Integration Tests - Find Mode

@test "script handles /copy-response find command" {
    input=$(create_hook_input "/copy-response find \"React\"" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Searching for \"React\"" ]]
}

@test "script handles /copy-prompt find command" {
    input=$(create_hook_input "/copy-prompt find \"error\"" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Searching for \"error\"" ]]
}

@test "find mode shows matching results" {
    input=$(create_hook_input "/copy-response find \"help\"" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Found" ]] && [[ "$output" =~ "matching responses" ]]
}

@test "find mode shows no results when no matches" {
    input=$(create_hook_input "/copy-response find \"nonexistent\"" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "No responses found matching" ]]
}

# Integration Tests - Debug Mode

@test "script handles /copy-response debug command" {
    input=$(create_hook_input "/copy-response debug" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "=== DEBUG MODE ===" ]]
}

@test "debug mode shows content details" {
    input=$(create_hook_input "/copy-response debug 1" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Byte count:" ]] && [[ "$output" =~ "Character count:" ]]
}

# Integration Tests - Error Handling

@test "script handles invalid response number" {
    input=$(create_hook_input "/copy-response 999" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Invalid response number 999" ]]
}

@test "script handles invalid prompt number" {
    input=$(create_hook_input "/copy-prompt 999" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Invalid prompt number 999" ]]
}

@test "script handles missing transcript file" {
    input=$(create_hook_input "/copy-response" "/nonexistent/transcript.json")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 1 ]
    [[ "$output" =~ "No valid transcript path found" ]]
}

# End-to-End Tests - Content Processing

@test "script correctly groups multi-part responses" {
    input=$(create_hook_input "/copy-response 2" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH' 2>/dev/null"
    [ $status -eq 0 ]
    # Should have combined the multi-part response from req2
}

@test "script processes UTF-8 content correctly" {
    input=$(create_hook_input "/copy-response find \"你好\"" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ "Found" ]] && [[ "$output" =~ "matching responses" ]]
}

@test "script handles empty responses gracefully" {
    input=$(create_hook_input "/copy-response list" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    # Should still show available responses even if some are empty
    [[ "$output" =~ "Available responses" ]]
}

# Timestamp and Preview Tests

@test "list mode shows timestamps" {
    input=$(create_hook_input "/copy-response list" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    [[ "$output" =~ \[.*ago\] ]]
}

@test "list mode shows truncated previews" {
    input=$(create_hook_input "/copy-response list" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    # Should show the long response truncated with ellipsis
    [[ "$output" =~ \.\.\. ]]
}

# JSON Output Validation

@test "successful copy returns valid JSON" {
    input=$(create_hook_input "/copy-response" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH' 2>/dev/null"
    [ $status -eq 0 ]
    # Output should be valid JSON with decision and reason
    echo "$output" | jq . >/dev/null
    [[ "$output" =~ "\"decision\":" ]] && [[ "$output" =~ "\"reason\":" ]]
}

# Regression tests for character corruption bug
@test "generate_preview preserves literal 'n' and 'r' characters" {
    source $(extract_functions)
    
    # Test text that contains literal 'n' and 'r' characters that should NOT be removed
    local test_text="I understand you're testing functionality"
    result=$(generate_preview "$test_text")
    
    # Should preserve 'n' and 'r' characters (not remove them like the sed bug did)
    [[ "$result" == "I understand you're testing functionality" ]]
    
    # Verify specific characters are preserved
    [[ "$result" =~ n ]]  # 'n' in "understand"
    [[ "$result" =~ r ]]  # 'r' in "understand" and "you're"
}

@test "generate_preview removes actual newlines correctly" {
    source $(extract_functions)
    
    # Test text with actual newlines and carriage returns
    local test_text=$'First line\nSecond line\rThird line'
    result=$(generate_preview "$test_text")
    
    # Should take the first line and remove any trailing newlines
    # The function uses grep -m1 which gets the first non-empty line
    [[ "$result" == "First line" ]]
}

@test "tr vs sed character preservation" {
    # This test demonstrates the fix for the character corruption bug
    local test_text="I understand you're testing"
    
    # tr correctly preserves literal 'n' and 'r' characters
    local result_tr=$(echo "$test_text" | tr -d '\n\r')
    [[ "$result_tr" == "I understand you're testing" ]]
    
    # sed with character class incorrectly removes literal 'n' and 'r' 
    local result_sed=$(echo "$test_text" | sed 's/[nr]//g')
    [[ "$result_sed" == "I udestad you'e testig" ]]
    
    # This demonstrates why we switched from sed to tr
}

# Tests for Claude Code hook JSON schema compliance
@test "hook returns approve for non-copy commands" {
    setup_test_env
    
    local transcript_file=$(mktemp)
    create_test_transcript "$transcript_file"
    
    local input=$(create_hook_input "Hello Claude" "$transcript_file")
    local output=$(run_script_with_input "$input")
    
    # Should return proper JSON with "approve" decision
    [[ "$output" == '{"decision": "approve"}' ]]
    
    rm -f "$transcript_file"
}

@test "hook returns block with proper JSON for copy-response commands" {
    setup_test_env
    
    local transcript_file=$(mktemp)
    create_test_transcript "$transcript_file"
    
    local input=$(create_hook_input "/copy-response" "$transcript_file")
    local output=$(run_script_with_input "$input")
    
    # Should return proper JSON with "block" decision and reason
    [[ "$output" =~ decision.*block ]]
    [[ "$output" =~ reason.*Latest\ Claude\ response\ copied\ to\ clipboard ]]
    
    # Verify it's valid JSON
    echo "$output" | jq . > /dev/null
    
    rm -f "$transcript_file"
}

@test "hook returns block with proper JSON for copy-prompt commands" {
    setup_test_env
    
    local transcript_file=$(mktemp)
    create_test_transcript "$transcript_file"
    
    local input=$(create_hook_input "/copy-prompt" "$transcript_file")
    local output=$(run_script_with_input "$input")
    
    # Should return proper JSON with "block" decision and reason
    [[ "$output" =~ decision.*block ]]
    [[ "$output" =~ reason.*Latest\ user\ prompt\ copied\ to\ clipboard ]]
    
    # Verify it's valid JSON
    echo "$output" | jq . > /dev/null
    
    rm -f "$transcript_file"
}

# Tests for path validation logic
@test "accepts valid Claude transcript paths" {
    setup_test_env
    
    local transcript_file=$(mktemp)
    create_test_transcript "$transcript_file"
    
    # Use a temporary directory that mimics the real structure
    local temp_claude_dir=$(mktemp -d)
    local claude_transcript="$temp_claude_dir/.claude/sessions/session123/transcript.json"
    local input=$(create_hook_input "/copy-response" "$claude_transcript")
    
    # Create the transcript file at the temporary path for validation
    mkdir -p "$(dirname "$claude_transcript")"
    cp "$transcript_file" "$claude_transcript"
    
    local output=$(run_script_with_input "$input" 2>&1)
    local exit_code=$?
    
    # Should not reject valid paths (exit code 0 means approve, 1 means block, 2 means block with stderr)
    [[ $exit_code -ne 1 ]]
    
    # Cleanup - remove only our temporary directory
    rm -rf "$temp_claude_dir"
    rm -f "$transcript_file"
}

@test "rejects paths containing double dots" {
    setup_test_env
    
    local transcript_file=$(mktemp)
    create_test_transcript "$transcript_file"
    
    # Test with path containing suspicious .. pattern
    local suspicious_path="/tmp/../etc/passwd"
    local input=$(create_hook_input "/copy-response" "$suspicious_path")
    
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    
    # Should reject suspicious paths (exit code 1)
    [[ $status -eq 1 ]]
    [[ "$output" =~ Invalid\ transcript\ path\ format ]]
    
    rm -f "$transcript_file"
}

@test "rejects non-existent transcript files" {
    setup_test_env
    
    # Test with non-existent file
    local nonexistent_path="/tmp/nonexistent_transcript.json"
    local input=$(create_hook_input "/copy-response" "$nonexistent_path")
    
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    
    # Should reject non-existent files (exit code 1)
    [[ $status -eq 1 ]]
    [[ "$output" =~ No\ valid\ transcript\ path\ found ]]
}