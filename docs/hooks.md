# Hooks

Hooks execute shell commands in response to Claude Code events. Copy the hooks you need to your `.claude/settings.json`.

## Available Hooks

| Hook                                          | Type  | Event       | Description                          |
|-----------------------------------------------|-------|-------------|--------------------------------------|
| [Auto-format PHP](#auto-format-php)           | info  | Edit\|Write | Runs `php-cs-fixer` on PHP files     |
| [Require strict_types](#require-strict_types) | block | Write       | Requires `declare(strict_types=1)`   |
| [Protect vendor/](#protect-vendor)            | block | Edit\|Write | Prevents modification of vendor/     |
| [PHP Syntax Check](#php-syntax-check)         | info  | Edit\|Write | Validates PHP syntax                 |
| [Auto-run Tests](#auto-run-tests)             | info  | Edit\|Write | Runs tests for modified class        |
| [Final Domain Classes](#final-domain-classes) | warn  | Edit\|Write | Warns if Domain class not final      |
| [File Size Check](#file-size-check)           | warn  | Edit\|Write | Detects God Class antipattern        |
| [No Direct Commits](#no-direct-commits)       | block | PreToolUse  | Forbids commits to main/master       |
| [Protect Migrations](#protect-migrations)     | block | PreToolUse  | Prevents editing existing migrations |
| [Test Without Source](#test-without-source)   | warn  | PreToolUse  | Warns when changing only tests       |

## Hook Types

- **block** — Stops operation on failure (`exit 1`)
- **warn** — Shows warning but continues
- **info** — Shows information, never fails

## Hooks Reference

### Auto-format PHP

Automatically formats PHP files with PSR-12 after editing.

**Requirements:** `composer global require friendsofphp/php-cs-fixer`

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *.php ]]; then php-cs-fixer fix \"$CLAUDE_FILE_PATHS\" --quiet 2>/dev/null || true; fi"
    }
  ]
}
```

---

### Require strict_types

Blocks creation of PHP files without `declare(strict_types=1)`.

```json
{
  "matcher": "Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *.php ]] && ! head -3 \"$CLAUDE_FILE_PATHS\" | grep -q 'strict_types=1'; then echo '❌ Missing declare(strict_types=1)'; exit 1; fi"
    }
  ]
}
```

---

### Protect vendor/

Prevents any modification to vendor/ directory.

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *vendor/* ]]; then echo '❌ Cannot modify vendor/'; exit 1; fi"
    }
  ]
}
```

---

### PHP Syntax Check

Validates PHP syntax after editing.

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *.php ]]; then php -l \"$CLAUDE_FILE_PATHS\" 2>&1 | grep -v 'No syntax errors' || true; fi"
    }
  ]
}
```

---

### Auto-run Tests

Automatically runs PHPUnit tests for the modified class.

**Requirements:** PHPUnit configured in project

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == src/*.php ]]; then class=$(basename \"${CLAUDE_FILE_PATHS%.php}\"); phpunit --filter \"$class\" 2>/dev/null || true; fi"
    }
  ]
}
```

---

### Final Domain Classes

Warns when Domain layer classes are not declared as `final`.

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == */Domain/*.php ]] && grep -q '^class ' \"$CLAUDE_FILE_PATHS\" && ! grep -q '^final class\\|^readonly class\\|^final readonly class' \"$CLAUDE_FILE_PATHS\"; then echo '⚠️ Domain classes should be final'; fi"
    }
  ]
}
```

---

### File Size Check

Warns when PHP file exceeds 300 lines (potential God Class).

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *.php ]]; then lines=$(wc -l < \"$CLAUDE_FILE_PATHS\"); if [[ $lines -gt 300 ]]; then echo \"⚠️ File has $lines lines (>300). Consider splitting.\"; fi; fi"
    }
  ]
}
```

## PreToolUse Hooks

PreToolUse hooks execute **before** the tool runs — ideal for validation and blocking.

---

### No Direct Commits

Forbids direct commits to main/master branches.

```json
{
  "matcher": "Bash(git commit*)",
  "hooks": [
    {
      "type": "command",
      "command": "branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); if [[ \"$branch\" == 'main' || \"$branch\" == 'master' ]]; then echo '❌ Direct commits to '$branch' forbidden. Create a feature branch.'; exit 1; fi"
    }
  ]
}
```

---

### Protect Migrations

Prevents editing existing database migrations. Create new migrations instead.

```json
{
  "matcher": "Edit",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *migrations/* ]]; then echo '❌ Cannot edit existing migrations. Create a new migration instead.'; exit 1; fi"
    }
  ]
}
```

---

### Test Without Source

Warns when modifying test files without corresponding source code changes.

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *Test.php ]] && ! git diff --name-only 2>/dev/null | grep -qv 'Test.php'; then echo '⚠️ Changing tests without changing source code'; fi"
    }
  ]
}
```

## Installation

Add hooks to your `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git commit*)",
        "hooks": [
          // paste PreToolUse hooks here
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          // paste PostToolUse hooks here
        ]
      }
    ]
  }
}
```

## Environment Variables

Available in hook commands:

| Variable | Description |
|----------|-------------|
| `CLAUDE_FILE_PATHS` | Path to the modified file |
| `CLAUDE_TOOL_NAME` | Name of the tool that triggered the hook |

## Tips

- Use `|| true` at the end to prevent blocking on errors
- Use `2>/dev/null` to suppress stderr
- Use `exit 1` to block the operation
- Test hooks manually before adding to settings