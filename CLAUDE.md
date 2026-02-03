# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Composer plugin providing Claude Code extensions (commands, agents, skills) for PHP development. On `composer require dykyi-roman/awesome-claude-code`, components auto-copy to the project's `.claude/` directory without overwriting existing files.

**Documentation:** [README.md](README.md) | [docs/](docs/) | [CHANGELOG.md](CHANGELOG.md) | [llms.txt](llms.txt)

## Commands

```bash
make help              # Show all available commands
make list-commands     # List slash commands
make list-skills       # List skills
make list-agents       # List agents
make validate-claude   # Validate .claude structure
make test              # Install in test environment (tests/)
make test-clear        # Clear test environment
make release           # Prepare release (run checks)
```

## Architecture

### Composer Plugin

`src/ComposerPlugin.php` subscribes to `POST_PACKAGE_INSTALL` and `POST_PACKAGE_UPDATE` events. Copies `.claude/{commands,agents,skills}/` to target project. Existing files are never overwritten.

### Component Structure

```
.claude/
├── commands/           # 10 slash commands
├── agents/             # 23 subagents
├── skills/             # 87 skills (knowledge + generators + templates)
│   └── name/
│       ├── SKILL.md    # Skill definition
│       └── references/ # Detailed documentation
└── settings.json       # Hooks and permissions
```

### Component Statistics

| Component | Count |
|-----------|-------|
| Commands  | 10    |
| Agents    | 23    |
| Skills    | 87    |
| Hooks     | 10    |

### Component Flow

```
COMMANDS                      AGENTS                        SKILLS
────────                      ──────                        ──────
/acc-commit ──────────────→ (direct Bash)

/acc-write-claude-component ─────────→ acc-claude-code-expert ─────→ acc-claude-code-knowledge

/acc-audit-ddd ───────────→ acc-ddd-auditor ────────────→ 4 knowledge skills
                                  │
                                  └──→ (Task) acc-ddd-generator

/acc-audit-architecture ──→ acc-architecture-auditor (coordinator)
                                  │
                                  ├──→ (Task) acc-structural-auditor ──→ 12 skills
                                  │           └── DDD, Clean, Hexagonal, Layered, SOLID, GRASP (6 knowledge)
                                  │           └── solid-violations, code-smells, bounded-contexts, immutability, leaky-abstractions, encapsulation (6 analyzers)
                                  │
                                  ├──→ (Task) acc-behavioral-auditor ──→ 13 skills
                                  │           └── CQRS, Event Sourcing, EDA, Strategy, State, etc.
                                  │
                                  ├──→ (Task) acc-integration-auditor ─→ 12 skills
                                  │           └── Outbox, Saga, Stability, ADR
                                  │
                                  ├──→ (Task) acc-ddd-generator
                                  └──→ (Task) acc-pattern-generator (coordinator)
                                                     │
                                                     ├──→ (Task) acc-stability-generator ──→ 5 skills
                                                     ├──→ (Task) acc-behavioral-generator ─→ 5 skills
                                                     ├──→ (Task) acc-creational-generator ─→ 3 skills
                                                     └──→ (Task) acc-integration-generator → 7 skills

/acc-audit-claude-components → (direct Read/Glob/Grep) ───→ audits .claude/ folder

/acc-audit-psr ───────────→ acc-psr-auditor ────────────→ PSR knowledge skills
                                  │
                                  └──→ PSR create-* skills

/acc-write-documentation ─→ acc-documentation-writer ───→ template skills
                                  │
                                  └──→ (Task) acc-diagram-designer

/acc-audit-documentation ─→ acc-documentation-auditor ──→ QA knowledge skills

/acc-write-test ──────────→ acc-test-generator ─────────→ acc-testing-knowledge
                                                          test create-* skills

/acc-audit-test ──────────→ acc-test-auditor ───────────→ acc-testing-knowledge
                                  │                       test analyze skills
                                  └──→ (Task) acc-test-generator
```

## Component Formats

### Commands (`.claude/commands/*.md`)

```yaml
---
description: Required. When to use this command.
allowed-tools: Optional. Comma-separated tool names.
model: Optional. sonnet/haiku/opus
argument-hint: Optional. Hint for arguments.
---

Instructions. Use $ARGUMENTS for user input.
```

### Agents (`.claude/agents/*.md`)

```yaml
---
name: required-name
description: Required. Include "PROACTIVELY" for auto-invocation.
tools: Optional. Default: all tools.
model: Optional. Default: sonnet.
skills: Optional. Auto-load skills.
---

Agent prompt.
```

### Skills (`.claude/skills/name/SKILL.md`)

```yaml
---
name: lowercase-with-hyphens
description: Required. Max 1024 chars.
---

Skill instructions. Keep under 500 lines.
Use references/ folder for detailed documentation.
```

### Hooks (`.claude/settings.json`)

Hooks execute shell commands on Claude Code events. See `docs/hooks.md` for all 10 hooks.

- **PreToolUse** — runs before tool execution (validation, blocking)
- **PostToolUse** — runs after tool execution (formatting, checks)

### MCP Servers

Model Context Protocol servers extend capabilities. See `docs/mcp.md`.

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"]
    }
  }
}
```

## Naming Convention

All components use `acc-` prefix (Awesome Claude Code) to avoid conflicts with user components.

## Command Arguments

All commands support meta-instructions via `--` separator:

```bash
/acc-audit-ddd ./src -- focus on aggregate boundaries
/acc-write-test src/Order.php -- only unit tests, skip integration
/acc-commit v2.5.0 -- mention breaking changes
```

## Agent Design Rules

- **Max 15 skills per agent** — exceeding this indicates SRP violation (God-Agent antipattern)
- Use coordinator pattern for complex auditors (delegate to specialized sub-agents via Task tool)
- Agents with 0 skills are valid coordinators that orchestrate other agents

## Component Integration Rules

When adding new components, verify proper integration in the component chain:

### After Adding a Skill
1. **Verify agent usage** — ensure skill is listed in relevant agent's `skills:` frontmatter
2. Check if skill should be used by appropriate generator/auditor agent

### After Adding an Agent
1. **Verify command usage** — ensure agent is invoked by relevant command via `Task` tool
2. Check component flow diagram for correct placement

### Integration Checklist
```
Skill → Agent (skills: frontmatter) → Command (Task tool call)
```

## Documentation Updates

When adding, removing, or modifying components, **always update**:

1. Component tables in `README.md` and `docs/`
2. Statistics (counts) where mentioned
3. Component flow diagram if flow changes
4. `CHANGELOG.md` for release notes

## Testing

```bash
# Install in test environment (uses Docker)
make test

# Check installed components
ls -la tests/.claude/

# Clean up
make test-clear
```

Test environment uses Docker with PHP-FPM. See `tests/docker-compose.yml`.

## Quick Validation

```bash
# Validate all components have correct frontmatter
make validate-claude

# Count components
find .claude/skills -maxdepth 1 -type d | tail -n +2 | wc -l  # Skills
find .claude/agents -name "*.md" | wc -l                       # Agents
find .claude/commands -name "*.md" | wc -l                     # Commands
```

## Adding New Components

### New Skill Workflow
```bash
# 1. Create skill directory and SKILL.md
mkdir -p .claude/skills/acc-new-skill
# 2. Add YAML frontmatter with name: and description:
# 3. Add skill to relevant agent's skills: list
# 4. Update docs/skills.md and README.md counts
# 5. Add to CHANGELOG.md
```

### New Agent Workflow
```bash
# 1. Create .claude/agents/acc-new-agent.md
# 2. Add YAML frontmatter (name, description, tools, model, skills)
# 3. If coordinator, ensure it invokes sub-agents via Task tool
# 4. Update docs/agents.md and README.md counts
# 5. Add to CHANGELOG.md
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Skill not loading | Check `skills:` in agent frontmatter |
| Agent not invoked | Check command uses `Task` tool with correct `subagent_type` |
| Validation fails | Ensure frontmatter starts with `---` |
| Component not copied | Check `src/ComposerPlugin.php` copies the directory |
