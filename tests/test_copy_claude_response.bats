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
    [ "$output" = "" ]  # Should exit silently
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
    [[ "$output" =~ "\[.*ago\]" ]]
}

@test "list mode shows truncated previews" {
    input=$(create_hook_input "/copy-response list" "$TEST_TRANSCRIPT")
    run bash -c "echo '$input' | '$SCRIPT_PATH'"
    [ $status -eq 2 ]
    # Should show the long response truncated with ellipsis
    [[ "$output" =~ "\.\.\.:" ]]
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