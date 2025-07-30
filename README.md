# Claude Code Response & Prompt Copier

A Claude Code hook that adds `/copy-response` and `/copy-prompt` commands to quickly copy Claude's responses or your prompts to your clipboard.

![Demo](img/demo.gif)

## Features

- 📋 **Quick Copy**: `/copy-response` copies the latest response, `/copy-prompt` copies the latest prompt
- 🔢 **Numbered Access**: `/copy-response 3` or `/copy-prompt 2` copies a specific item
- 📝 **List Items**: `/copy-response list` or `/copy-prompt list` shows available items with previews
- 🔍 **Search Content**: `/copy-response find "keyword"` or `/copy-prompt find "text"` finds items containing text
- ⏰ **Timestamps**: Shows when each response or prompt was created
- 🖥️ **Cross-Platform**: Works on macOS, Linux, and Windows/WSL

## Installation

1. **Download the script:**

   ```bash
   curl -o copy-claude-response https://raw.githubusercontent.com/Twizzes/copy-claude-response/main/copy-claude-response
   chmod +x copy-claude-response
   ```

2. **Place it somewhere in your PATH** (or note the full path):

   ```bash
   mv copy-claude-response ~/.local/bin/
   ```

3. **Configure the hook** in your Claude Code settings (`~/.claude/settings.json`):

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "/path/to/copy-claude-response"
             }
           ]
         }
       ]
     }
   }
   ```

## Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `/copy-response` | Copy the latest Claude response |
| `/copy-response 2` | Copy response #2 |
| `/copy-response list` | List last 10 responses with previews |
| `/copy-response list 5` | List last 5 responses |
| `/copy-response find "error"` | Find responses containing "error" |
| `/copy-prompt` | Copy the latest user prompt |
| `/copy-prompt 3` | Copy prompt #3 |
| `/copy-prompt list` | List last 10 prompts with previews |
| `/copy-prompt list 7` | List last 7 prompts |
| `/copy-prompt find "debug"` | Find prompts containing "debug" |

### Examples

**Copy latest response:**

```
/copy-response
```

> Latest Claude response copied to clipboard!

**List recent responses:**

```
/copy-response list
```

```
Available responses (1-3):
    3 [ 2.1 min ago]: Here's the updated function with error handling...
    2 [15.3 min ago]: I'll help you debug this issue. First, let's check...
    1 [ 1.2 hrs ago]: To implement this feature, we need to modify...
```

**Search for specific content:**

```
/copy-response find "git commit"
```

```
Searching for "git commit":
    2 [15.3 min ago]: I'll help you debug this issue. First, let's check...
    5 [ 2.1 hrs ago]: You can create a git commit using the following...
Found 2 matching responses
```

**Copy latest prompt:**

```
/copy-prompt
```

> Latest user prompt copied to clipboard!

**List recent prompts:**

```
/copy-prompt list
```

```
Available prompts (1-3):
    3 [ 1.2 min ago]: How do I fix this error in my React component?
    2 [12.5 min ago]: Please review this code and suggest improvements
    1 [ 45.3 min ago]: Can you help me debug this API integration?
```

## How It Works

The script:

1. **Intercepts** `/copy-response` and `/copy-prompt` commands before Claude processes them
2. **Parses** the conversation transcript to extract Claude's responses or user prompts
3. **Groups** multi-part messages by request ID for complete content
4. **Copies** the selected response or prompt to your system clipboard
5. **Blocks** the command from reaching Claude to prevent confusion

## Platform Support

- **macOS**: Uses `pbcopy`
- **Linux**: Uses `xclip` (install with `sudo apt install xclip`)
- **Windows/WSL**: Uses `clip.exe` via PowerShell for proper UTF-8 handling

## Troubleshooting

**Hook not working?**

- Run `/hooks` in Claude Code to verify the hook is registered
- Check that the script path is correct and executable
- Use `claude --debug` to see hook execution details

**Clipboard not working?**

- **Linux**: Install xclip: `sudo apt install xclip`
- **WSL**: Ensure Windows clipboard integration is enabled

**No responses found?**

- The script only finds text responses from Claude
- Responses with only tool calls won't appear in the list

**Hook not triggering?**

- Do not create custom slash commands named `/copy-response` or `/copy-prompt` - this will prevent the hook from triggering

## Limitations

- Only copies text responses from Claude (responses with only tool calls won't appear)
- Only copies text prompts from users (prompts with only images or attachments won't appear)
- The slash commands WILL NOT AUTO-COMPLETE, this is because we are hooking UserPromptSubmission, which slash commands (that exist) do not trigger
- Requires `jq` for JSON parsing
- Platform-specific clipboard utilities must be installed

## Requirements

- Claude Code with hooks support
- Bash shell
- `jq` for JSON parsing
- Platform-specific clipboard utility (pbcopy/xclip/clip.exe)

## Contributing

Found a bug or have a feature request? Please open an issue or submit a pull request!

## License

Apache License 2.0 - feel free to modify and share!
