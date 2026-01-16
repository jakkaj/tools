# Research Dossier: Claude Code Hooks

**Generated**: 2026-01-15
**Research Query**: "Claude Code hooks - capabilities, events, configuration, and practical use cases"
**Mode**: Research-Only (External Research via Perplexity)
**Location**: docs/plans/006-hooks/research-dossier.md

---

## Executive Summary

### What Are Claude Code Hooks?

Claude Code hooks are automated shell commands that execute at specific points in Claude's workflow, providing a mechanism to intercept, validate, modify, or enforce actions **deterministically** without relying on the language model to remember to perform these tasks. They represent a fundamental shift in how developers can control AI-assisted coding workflows by providing predictable behavioral control over an otherwise probabilistic system.

### Why Hooks Matter

The core innovation lies in recognizing that large language models, while powerful, are probabilistic systems that occasionally forget important steps or fail to adhere to project conventions. Hooks solve this by creating a deterministic layer that operates independently of Claude's reasoning process. If you tell Claude to "always format files after editing," there is no guarantee this will happen on every execution. Hooks eliminate this uncertainty by making specific actions **mandatory** rather than suggested.

### Key Capabilities

1. **Logging and Auditing**: Track every action the agent attempts to take
2. **Intelligent Feedback**: Provide validation information before/after Claude processes
3. **Context Injection**: Add information to prompts before Claude processes them
4. **Automatic Remediation**: Fix common issues like code formatting automatically
5. **Security Boundaries**: Protect sensitive files and prevent dangerous operations
6. **Custom Notifications**: Alert users when Claude needs input or permission

### Quick Stats

- **Hook Events**: 10 distinct lifecycle events
- **Configuration Scopes**: 4 (Managed, User, Project, Local)
- **Hook Types**: 2 (command, prompt)
- **Timeout Maximum**: 600 seconds (as of v2.1.3)
- **Exit Codes**: 3 meaningful states (0=allow, 2=block, other=non-blocking error)

---

## Hook Events Reference

Claude Code provides 10 hook events that run at different points in the workflow:

### 1. PreToolUse

**When**: Runs after Claude creates tool parameters and **before** processing the tool call.

**Purpose**: The most powerful hook event - can intercept, validate, modify, or block actions before they happen.

**Capabilities**:
- Block tool execution (exit code 2)
- Modify tool inputs transparently (`updatedInput`)
- Allow/deny/ask permission decisions
- Provide feedback to Claude via stderr

**Common Matchers**:
- `Bash` - Shell commands
- `Edit` / `Write` - File modifications
- `Read` - File reading
- `Glob` / `Grep` - Search operations
- `Task` - Subagent tasks
- `WebFetch` / `WebSearch` - Web operations
- `mcp__<server>__<tool>` - MCP server tools

**Input Schema**:
```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../session.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm install",
    "description": "Install dependencies"
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

### 2. PermissionRequest

**When**: Runs when the user is shown a permission dialog.

**Purpose**: Automate permission decisions based on context rather than static rules.

**Capabilities**:
- Allow, deny, or ask permission decisions
- Modify tool inputs before approving
- Useful for automated/headless environments

**Matchers**: Same as PreToolUse

### 3. PostToolUse

**When**: Runs immediately **after** a tool completes successfully.

**Purpose**: Enforce reactive quality measures and provide feedback after actions.

**Capabilities**:
- Run formatters, linters, type checkers
- Provide feedback to Claude about results
- Cannot prevent already-executed actions
- Auto-commit changes

**Input Schema** (includes `tool_response`):
```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
  "tool_response": { "success": true, "content": "..." }
}
```

### 4. UserPromptSubmit

**When**: Fires immediately when the user submits a prompt, **before** Claude processes it.

**Purpose**: Input validation, security filtering, and context injection.

**Capabilities**:
- Block prompts (exit code 2)
- Add context Claude will see (`additionalContext`)
- Inject system time, git history, project guidelines
- Security filtering of prompts

### 5. Notification

**When**: Fires when Claude Code sends notifications (permission needed, idle input, auth success).

**Purpose**: Custom notification systems, desktop alerts, text-to-speech.

**Notification Types**:
- `permission_prompt` - Claude needs permission
- `idle_prompt` - Waiting for user input (60+ seconds idle)
- `auth_success` - Authentication completed
- `elicitation_dialog` - Dialog shown to user

**Input Schema**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "Notification",
  "notification_type": "permission_prompt",
  "message": "Claude needs your permission to use Bash"
}
```

### 6. Stop

**When**: Fires when Claude Code's main agent finishes responding and is about to stop.

**Purpose**: Prevent premature stopping, enforce completion criteria.

**Capabilities**:
- Block stoppage (exit code 2 or `decision: "block"`)
- Examine transcript to verify task completion
- Enforce quality gates before declaring success

**Input Schema** (includes `stop_hook_active`):
```json
{
  "session_id": "abc123",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
```

**Important**: Check `stop_hook_active` to prevent infinite loops!

### 7. SubagentStop

**When**: Fires when a subagent (spawned via Task tool) completes its work.

**Purpose**: Same as Stop but for subagents.

**Capabilities**: Same as Stop hook

### 8. SessionStart

**When**: Fires when Claude Code initializes a new session or resumes an existing one.

**Purpose**: Set up initial state, load project-specific configuration.

**Source Types**:
- `startup` - Fresh session start
- `resume` - Resuming previous session
- `clear` - Context cleared

**Input Schema**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

### 9. SessionEnd

**When**: Fires when the session terminates.

**Purpose**: Cleanup, backup session data, logging.

**Reason Types**:
- Normal exit
- Error
- User interruption

### 10. PreCompact

**When**: Fires before Claude Code performs a compaction operation (context window management).

**Purpose**: Backup transcript data before context compression.

**Note**: Cannot block compaction, only observe and prepare.

**Input Schema**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "PreCompact",
  "trigger": "manual" | "auto",
  "custom_instructions": "..."
}
```

---

## Configuration

### File Locations & Precedence

From highest to lowest precedence:

| Scope | Location | Purpose |
|-------|----------|---------|
| **Managed** | `/etc/claude-code/managed-settings.json` (Linux/macOS) or `C:\Program Files\ClaudeCode\` (Windows) | Organization-wide policies, cannot be overridden |
| **Command Line** | CLI arguments | Temporary session overrides |
| **Local Project** | `.claude/settings.local.json` | Personal project overrides (not committed) |
| **Project** | `.claude/settings.json` | Team-shared settings (committed to git) |
| **User** | `~/.claude/settings.json` | Personal global settings |

### Hook Configuration Structure

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script.sh",
            "timeout": 60,
            "env": {
              "KEY": "value"
            }
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

- **Exact match**: `"Bash"` matches only the Bash tool
- **Regex**: `"Edit|Write"` matches either tool
- **Wildcards**: `"Notebook.*"` matches NotebookRead, NotebookEdit
- **All tools**: `"*"` or empty string `""`
- **MCP tools**: `"mcp__<server>__<tool>"` (e.g., `"mcp__github__create_pull_request"`)

**Important**: Matchers are **case-sensitive**! `"bash"` will NOT match the Bash tool.

### Hook Types

1. **command** - Shell commands
   ```json
   {
     "type": "command",
     "command": "./scripts/validate.sh",
     "timeout": 60
   }
   ```

2. **prompt** - LLM-based decisions (for Stop/SubagentStop)
   ```json
   {
     "type": "prompt",
     "prompt": "Evaluate if all tasks are complete. Respond: {\"ok\": true} or {\"ok\": false, \"reason\": \"...\"}"
   }
   ```

### Timeout Configuration

- **Default**: 60 seconds
- **Maximum**: 600 seconds (as of v2.1.3)
- Configure per-hook with `timeout` field in milliseconds

---

## Hook Input & Output

### Common Input Fields (All Hooks)

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../session.jsonl",
  "cwd": "/Users/current/working/directory",
  "permission_mode": "default" | "plan" | "acceptEdits" | "dontAsk" | "bypassPermissions",
  "hook_event_name": "PreToolUse"
}
```

### Tool-Specific Input Fields

#### Bash Tool
```json
{
  "tool_input": {
    "command": "npm run build",
    "description": "Build the project",
    "timeout": 120000
  }
}
```

#### Edit Tool
```json
{
  "tool_input": {
    "file_path": "/absolute/path/to/file.ts",
    "old_string": "const foo = 1;",
    "new_string": "const foo = 2;",
    "replace_all": false
  }
}
```

#### Write Tool
```json
{
  "tool_input": {
    "file_path": "/absolute/path/to/new-file.ts",
    "content": "// File content here"
  }
}
```

#### Read Tool
```json
{
  "tool_input": {
    "file_path": "/absolute/path/to/file.ts",
    "offset": 0,
    "limit": 100
  }
}
```

### Exit Code Semantics

| Exit Code | Meaning | Behavior |
|-----------|---------|----------|
| **0** | Success | Proceed normally. stdout may contain JSON for structured control |
| **2** | Blocking error | Block the action. stderr message shown to Claude |
| **Other** | Non-blocking error | Continue normally. stderr shown to user only |

### Exit Code 2 Behavior by Event

| Hook Event | Exit Code 2 Behavior |
|------------|---------------------|
| `PreToolUse` | Blocks the tool call, shows stderr to Claude |
| `PermissionRequest` | Denies the permission, shows stderr to Claude |
| `PostToolUse` | Shows stderr to Claude (tool already ran) |
| `Notification` | N/A, shows stderr to user only |
| `Stop` | Blocks stoppage, shows stderr to Claude |
| `SubagentStop` | Blocks stoppage, shows stderr to Claude |
| `PreCompact` | N/A, shows stderr to user only |

### Structured JSON Output

For sophisticated control beyond exit codes:

```json
{
  "continue": true,
  "stopReason": "Optional message when continue is false",
  "suppressOutput": false,
  "systemMessage": "Optional warning to display to user",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow" | "deny" | "ask",
    "permissionDecisionReason": "Explanation",
    "updatedInput": { "modified": "tool input" }
  }
}
```

### Event-Specific Output Fields

#### PreToolUse
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow" | "deny" | "ask",
    "permissionDecisionReason": "Shown to Claude if denied, user if asking",
    "updatedInput": { "command": "modified command" }
  }
}
```

#### PostToolUse
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "decision": "block" | undefined,
    "reason": "Explanation fed to Claude",
    "additionalContext": "Extra context for Claude"
  }
}
```

#### Stop / SubagentStop
```json
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block" | undefined,
    "reason": "Why work must continue"
  }
}
```

#### UserPromptSubmit
```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "decision": "block" | undefined,
    "reason": "Shown to user if blocked",
    "additionalContext": "Added to prompt Claude sees"
  }
}
```

---

## Practical Examples

### 1. Log All Bash Commands (Audit Trail)

**Event**: PreToolUse | **Matcher**: Bash

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"\\(.tool_input.command) - \\(.tool_input.description // \"No description\")\"' >> ~/.claude/bash-command-log.txt"
          }
        ]
      }
    ]
  }
}
```

### 2. Protect Sensitive Files

**Event**: PreToolUse | **Matcher**: Edit|Write

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 -c \"import json, sys; data=json.load(sys.stdin); path=data.get('tool_input',{}).get('file_path',''); sys.exit(2 if any(p in path for p in ['.env', 'package-lock.json', '.git/']) else 0)\""
          }
        ]
      }
    ]
  }
}
```

### 3. Auto-Format TypeScript After Edits

**Event**: PostToolUse | **Matcher**: Edit|Write

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.ts$'; then npx prettier --write \"$file_path\"; fi; }"
          }
        ]
      }
    ]
  }
}
```

### 4. Block npm in Favor of pnpm/bun

**Event**: PreToolUse | **Matcher**: Bash

`.claude/hooks/enforce-pnpm.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

if [ -f pnpm-lock.yaml ] && echo "$cmd" | grep -Eq '\bnpm\b'; then
  echo "This repo uses pnpm. Replace 'npm' with 'pnpm'." 1>&2
  exit 2
fi

exit 0
```

### 5. Desktop Notification When Permission Needed (macOS)

**Event**: Notification | **Matcher**: permission_prompt

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "terminal-notifier -title 'Claude Code' -message 'Permission needed' -sound Glass"
          }
        ]
      }
    ]
  }
}
```

### 6. Text-to-Speech When Claude Stops

**Event**: Stop

```python
#!/usr/bin/env python3
import pyttsx3

def main():
    engine = pyttsx3.init()
    rate = engine.getProperty('rate')
    engine.setProperty('rate', rate - 50)
    engine.say("Claude Code is done")
    engine.runAndWait()

if __name__ == "__main__":
    main()
```

### 7. Block Dangerous Bash Commands (Firewall)

**Event**: PreToolUse | **Matcher**: Bash

`.claude/hooks/pre-bash-firewall.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

deny_patterns=(
  'rm\s+-rf\s+/'
  'git\s+reset\s+--hard'
  'curl\s+.*\s*|\s*bash'
  'wget\s+.*\s*|\s*sh'
)

for pattern in "${deny_patterns[@]}"; do
  if echo "$cmd" | grep -Eq "$pattern"; then
    echo "Blocked: Command matches dangerous pattern '$pattern'" 1>&2
    exit 2
  fi
done

exit 0
```

### 8. Pre-Commit Quality Gate

**Event**: PreToolUse | **Matcher**: Bash

Block `git commit` unless tests have passed:

```bash
#!/bin/bash
input_data=$(cat)
command=$(echo "$input_data" | jq -r '.tool_input.command // empty')

# Only validate git commit commands
if ! echo "$command" | grep -q "git commit"; then
    exit 0
fi

# Check if pre-commit validation passed
if [ ! -f /tmp/agent-pre-commit-pass ]; then
    echo "Tests must pass before committing. Run test suite first." >&2
    exit 2
fi

exit 0
```

### 9. Context Injection at Session Start

**Event**: SessionStart

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'conda activate myenv' >> \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ]
  }
}
```

### 10. Auto-Commit After Edits

**Event**: PostToolUse | **Matcher**: Edit

`.claude/hooks/post-edit-commit.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore(ai): apply Claude edit"
fi

exit 0
```

---

## Component-Scoped Hooks

Hooks can be defined in agent/skill YAML frontmatter, scoping them to specific components:

```yaml
---
name: secure-operations
description: Perform operations with security checks

hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

This approach enables reusable agents with embedded hooks that don't interfere with global configuration.

---

## Security Considerations

### 1. Hook Script Modification Risk

**Critical**: Hooks cannot be protected from modification by Claude itself. If a malicious prompt tricks Claude into editing hook scripts, guardrails can be circumvented.

**Mitigation**: Use managed settings with `allowManagedHooksOnly: true`:
```json
{
  "allowManagedHooksOnly": true,
  "hooks": { ... }
}
```

### 2. Input Validation

Always validate JSON input from stdin:

```python
#!/usr/bin/env python3
import json, sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f'Error: Invalid JSON input: {e}', file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get('tool_name', '')
tool_input = input_data.get('tool_input', {})

if not tool_name or not isinstance(tool_input, dict):
    print('Error: Invalid hook input structure', file=sys.stderr)
    sys.exit(1)
```

### 3. Path Traversal Prevention

Validate file paths against traversal attacks:

```python
import os

file_path = tool_input.get('file_path', '')
absolute_path = os.path.abspath(file_path)
project_root = os.path.abspath(os.getcwd())

if not absolute_path.startswith(project_root):
    print('Error: Path traversal detected', file=sys.stderr)
    sys.exit(2)
```

### 4. Never Output Sensitive Data

Hook stderr/stdout may be captured in logs. Never output API keys, passwords, or auth tokens.

### 5. Enterprise Deployment

For organization-wide policies, use managed settings that cannot be overridden:

```json
{
  "allowManagedHooksOnly": true,
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/opt/org/hooks/validate-bash.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Environment Variables

Claude Code provides these environment variables for hooks:

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Project root directory |
| `CLAUDE_ENV_FILE` | Path to env file sourced before Bash commands |
| `CLAUDE_FILE_PATHS` | Paths of files being operated on |
| `CLAUDE_TOOL_NAME` | Name of the tool being used |
| `CLAUDE_WORKING_DIR` | Current working directory |
| `CLAUDE_SESSION_ID` | Current session identifier |

**Note**: Environment variables set in one Bash command are NOT available in subsequent commands (each runs in a fresh shell). Use `$CLAUDE_ENV_FILE` workaround for persistent env setup.

---

## Best Practices & Gotchas

### Best Practices

1. **Use PreToolUse for policy guards, PostToolUse for cleanup/feedback**
2. **Test scripts in your shell first, then wire into hooks**
3. **Keep block messages specific and constructive** so Claude can self-correct
4. **Quote variables, avoid unsafe expansions, use absolute paths**
5. **Block-at-submit strategy**: Validate at commit time, not edit time
6. **Smart dispatching**: Check specific commands before running expensive validations

### Known Gotchas

1. **Context Consumption**: Auto-formatting hooks can consume significant tokens (160k+ reported). Consider manual formatting between sessions.

2. **Stop Hook Infinite Loops**: Check `stop_hook_active` to prevent loops:
   ```python
   if input_data.get('stop_hook_active'):
       sys.exit(0)  # Don't block again
   ```

3. **Matcher Case Sensitivity**: `"bash"` will NOT match `Bash` tool!

4. **Parallel Execution**: Multiple matching hooks execute in parallel, not sequentially. No interdependencies allowed.

5. **Block-at-Write Confusion**: Blocking Claude mid-plan during file editing confuses the agent. Block at commit time instead.

---

## Interactive Setup

Use the `/hooks` slash command for interactive hook configuration:

```
/hooks
```

This opens a UI to:
- View registered hooks
- Create new hooks
- Select events and matchers
- Choose storage scope (User/Project/Local)

---

## Debugging Hooks

### Enable Debug Mode

```bash
claude --debug
```

Shows verbose hook execution details.

### View Hook Progress

Press `Ctrl+O` for verbose mode during execution.

### Manual Testing

Test scripts directly:
```bash
echo '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' | ./my-hook.sh
echo $?  # Check exit code
```

### Common Issues

1. **Hook not firing**: Check matcher case sensitivity
2. **JSON parse errors**: Validate JSON syntax with `jsonlint`
3. **Permission denied**: Ensure scripts are executable (`chmod +x`)
4. **Wrong output**: Ensure JSON goes to stdout, errors to stderr

---

## Integration with Permission System

Hooks interact with Claude Code's permission system in a layered architecture:

1. **Hooks execute first** and can make permission decisions
2. **Traditional permission rules** provide fallback enforcement

### Permission Modes

| Mode | Description | Hook Behavior |
|------|-------------|---------------|
| `default` | Normal operation | Hooks can block, remaining follows normal rules |
| `plan` | Analyze only | Hooks execute for read-only operations |
| `acceptEdits` | Auto-approve edits | Hooks still execute for validation |
| `dontAsk` | Auto-deny unless pre-approved | Hooks can still allow exceptions |
| `bypassPermissions` | Skip all permissions | Hooks still execute for monitoring |

---

## Summary: Hook Events Quick Reference

| Event | Fires When | Can Block? | Best For |
|-------|------------|------------|----------|
| **PreToolUse** | Before tool execution | Yes (exit 2) | Validation, security, input modification |
| **PermissionRequest** | Permission dialog shown | Yes | Automated permission decisions |
| **PostToolUse** | After tool completes | No (feedback only) | Formatting, linting, logging |
| **UserPromptSubmit** | User submits prompt | Yes | Input validation, context injection |
| **Notification** | Claude sends notification | No | Custom alerts, TTS, desktop notifications |
| **Stop** | Agent finishes | Yes | Completion verification |
| **SubagentStop** | Subagent finishes | Yes | Subagent completion verification |
| **SessionStart** | Session begins | No | Environment setup |
| **SessionEnd** | Session ends | No | Cleanup, logging |
| **PreCompact** | Before compaction | No | Transcript backup |

---

## Resources & Citations

### Official Documentation
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Settings Documentation](https://code.claude.com/docs/en/settings)

### Community Resources
- [claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) - Comprehensive hook examples
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Steve Kinney's Hook Examples](https://stevekinney.com/courses/ai-development/claude-code-hook-examples)

### Tutorials & Guides
- [Having Fun with Claude Code Hooks](https://stacktoheap.com/blog/2025/08/03/having-fun-with-claude-code-hooks/)
- [How I Use Every Claude Code Feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)
- [Claude Code Hooks for uv Projects](https://pydevtools.com/blog/claude-code-hooks-for-uv/)

---

## Next Steps

This research provides a comprehensive foundation for experimenting with Claude Code hooks. Potential directions:

1. **Create a hooks library** with reusable security, formatting, and notification hooks
2. **Implement project-specific hooks** for this tools repository
3. **Build a hook development workflow** with testing and debugging patterns
4. **Explore advanced patterns** like prompt-type hooks for intelligent decisions
5. **Enterprise deployment patterns** with managed settings

---

**Research Complete**: 2026-01-15
**Report Location**: `/Users/jordanknight/github/tools/docs/plans/006-hooks/research-dossier.md`
