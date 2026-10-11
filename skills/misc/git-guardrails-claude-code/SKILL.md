---
name: git-guardrails-claude-code
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, Claude sees a message telling it that it does not have authority to access these commands.

## Needs

- `jq`, used by the guard script to read each command and by step 3 to merge the settings file. Check with `jq --version`; install with `sudo apt-get install jq` (Debian/Ubuntu) or `brew install jq` (macOS). Without jq the guard blocks every Bash command with a message naming jq, so install it before step 2.

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)?

### 2. Copy the hook script

The bundled script is at: [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)

Copy it to the target location based on scope:

- **Project**: `.claude/hooks/block-dangerous-git.sh`
- **Global**: `~/.claude/hooks/block-dangerous-git.sh`

Make it executable with `chmod +x`.

### 3. Add hook to settings

The hook entry the settings file must gain:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
    }
  ]
}
```

(Global scope uses `~/.claude/hooks/block-dangerous-git.sh` as the command.)

Never write the settings file by hand or overwrite it: it may already hold other hooks (session hooks, other PreToolUse guards) that must survive. Set the two variables for the chosen scope, then run the merge exactly as written. It creates the file when missing, keeps a backup, appends the entry to `hooks.PreToolUse` (creating the array when the key is absent), leaves every other key and hook untouched, and adds nothing when the guard is already there.

```bash
# Project scope:
SETTINGS=.claude/settings.json
HOOK='"$CLAUDE_PROJECT_DIR"/.claude/hooks/block-dangerous-git.sh'
# Global scope instead:
# SETTINGS=~/.claude/settings.json
# HOOK='~/.claude/hooks/block-dangerous-git.sh'

mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"
jq --arg cmd "$HOOK" '
  .hooks.PreToolUse = ((.hooks.PreToolUse // [])
    + (if any((.hooks.PreToolUse // [])[].hooks[]?; .command == $cmd) then []
       else [{"matcher": "Bash", "hooks": [{"type": "command", "command": $cmd}]}] end))
' "$SETTINGS.bak" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
```

Then validate. This prints `true` and exits 0 only when every key outside `hooks` is unchanged, every hook event other than `PreToolUse` is unchanged, the old `PreToolUse` entries are still first and in order, and the guard appears exactly once:

```bash
jq -e --arg cmd "$HOOK" --slurpfile old "$SETTINGS.bak" '
  ($old[0]) as $o
  | (del(.hooks) == ($o | del(.hooks)))
  and (((.hooks // {}) | del(.PreToolUse)) == (($o.hooks // {}) | del(.PreToolUse)))
  and (.hooks.PreToolUse[0:(($o.hooks.PreToolUse // []) | length)] == ($o.hooks.PreToolUse // []))
  and ([.hooks.PreToolUse[].hooks[]? | select(.command == $cmd)] | length == 1)
' "$SETTINGS" && rm "$SETTINGS.bak"
```

If the validation prints `false` or an error, put the backup back with `mv "$SETTINGS.bak" "$SETTINGS"; rm -f "$SETTINGS.tmp"`, read the error (usually the settings file was not valid JSON: check with `jq . "$SETTINGS"`), fix the cause, and go back to the start of step 3. Do not move to step 4 until the validation passes.

### 4. Ask about customization

Ask if user wants to add or remove any patterns from the blocked list. Edit the copied script accordingly.

### 5. Verify

Run a quick test:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
```

Should exit with code 2 and print a BLOCKED message to stderr.
