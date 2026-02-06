# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Composer plugin providing Claude Code extensions for PHP development with DDD, CQRS, and Clean Architecture patterns. Installs to target projects via `composer require dykyi-roman/awesome-claude-code`.

## Commands

```bash
make validate-claude        # Validate structure (run before commits)
make list-commands          # List all slash commands
make list-agents            # List all agents
make list-skills            # List all skills
./bin/acc upgrade           # Force upgrade components (creates backup)
make test                   # Install in Docker test environment
make test-clear             # Clear test environment
make release                # Prepare release
```

## Architecture

```
.claude/
├── commands/     # Slash commands (user-invocable, 20+)
├── agents/       # Subagents (Task tool targets, 40+)
├── skills/       # Skills (knowledge, generators, analyzers, 150+)
└── settings.json # Hooks and permissions
```

**Execution Flow:**
```
User Input → Command → Coordinator Agent → Specialized Agents (parallel via Task) → Skills → Output
```

**Composer Plugin:** `src/ComposerPlugin.php` subscribes to `POST_PACKAGE_INSTALL` and `POST_PACKAGE_UPDATE` events. Copies `.claude/` components to target project. Existing files never overwritten.

## Adding Components

Integration chain: **Skill → Agent (skills: frontmatter) → Command (Task tool)**

### Command (`.claude/commands/name.md`)
```yaml
---
description: Required
allowed-tools: Optional
model: Optional (sonnet/haiku/opus)
argument-hint: Optional (e.g. "<path> [-- instructions]")
---
```

### Agent (`.claude/agents/name.md`)
```yaml
---
name: Required
description: Required
tools: Optional
skills: Optional (list skill names)
---
```

For coordinators (3+ phases), add `TaskCreate, TaskUpdate` to tools and include `acc-task-progress-knowledge` skill.

### Skill (`.claude/skills/name/SKILL.md`)
```yaml
---
name: Required (lowercase, hyphens)
description: Required (max 1024 chars)
---
```

Max 500 lines — extract large content to `references/` folder.

## Key Rules

- **`acc-` prefix** — all components use this to avoid conflicts
- **`--` separator** — pass meta-instructions: `/acc-audit-ddd ./src -- focus on aggregates`
- **After changes** — run `make validate-claude`, update `docs/*.md` and `CHANGELOG.md`
- **New components** — update corresponding `docs/commands.md`, `docs/agents.md`, or `docs/skills.md`

## Documentation

| Document | Description |
|----------|-------------|
| `docs/commands.md` | All slash commands with examples |
| `docs/agents.md` | All agents with descriptions |
| `docs/skills.md` | All skills by category |
| `docs/hooks.md` | Available hooks |
| `docs/component-flow.md` | Full architecture diagram |

## CI/CD Commands

```bash
/acc-ci-setup               # Setup CI pipeline from scratch
/acc-ci-fix                 # Fix CI pipeline issues
/acc-ci-optimize            # Optimize CI pipeline performance
/acc-audit-ci               # Audit CI configuration
```

## Versioning

When releasing new version:
1. Update `CHANGELOG.md` with new features
2. Run `make validate-claude`
3. Update component counts in `README.md`, `docs/*.md` if significantly changed
4. Run `make release`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Skill not loading | Check `skills:` in agent frontmatter |
| Agent not invoked | Check command uses `Task` tool with correct `subagent_type` |
| Validation fails | Ensure frontmatter starts with `---` |
