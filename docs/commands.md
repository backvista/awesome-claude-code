# Commands

Slash commands for Claude Code. Commands are user-invoked actions triggered by typing `/command-name` in the CLI.

## Overview

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/acc-commit` | Git workflow | After making changes, auto-generate commit message |
| `/acc-claude-code` | Component creation | When you need to create new commands, agents, or skills |
| `/acc-audit-claude-code` | Configuration audit | To check `.claude/` folder quality and find issues |
| `/acc-audit-architecture` | Code audit | To analyze PHP project architecture patterns |
| `/acc-audit-ddd` | DDD audit | To check DDD compliance in PHP projects |
| `/acc-audit-psr` | PSR audit | To verify PHP Standards Recommendations compliance |
| `/acc-write-documentation` | Doc generation | To create or update project documentation |
| `/acc-audit-documentation` | Doc audit | To check documentation quality and completeness |

---

## `/acc-claude-code`

**Path:** `commands/acc-claude-code.md`

Interactive wizard for creating Claude Code components.

**Usage:**
```
/acc-claude-code
```

**Process:**
1. Asks what to create (command/agent/skill/hook)
2. Gathers requirements through questions
3. Uses `acc-claude-code-expert` agent with `acc-claude-code-knowledge` skill
4. Creates component with proper structure
5. Validates and shows result

---

## `/acc-audit-claude-code`

**Path:** `commands/acc-audit-claude-code.md`

Audit `.claude/` folder structure and configuration quality.

**Usage:**
```
/acc-audit-claude-code
```

**Analyzes:**
- Commands (YAML frontmatter, descriptions, tool restrictions)
- Agents (naming, skills references, tool permissions)
- Skills (structure, size, references)
- Settings (hooks, permissions, secrets)
- Cross-references integrity

**Output:**
- File tree with status indicators
- Detailed issues analysis
- Prioritized recommendations
- Ready-to-apply quick fixes

---

## `/acc-commit`

**Path:** `commands/acc-commit.md`

Auto-generate commit message from diff and push to current branch.

**Usage:**
```
/acc-commit
```

---

## `/acc-audit-architecture`

**Path:** `commands/acc-audit-architecture.md`

Comprehensive multi-pattern architecture audit for PHP projects.

**Usage:**
```
/acc-audit-architecture <path-to-project>
```

**Analyzes:**
- DDD compliance
- CQRS patterns
- Clean Architecture
- Hexagonal Architecture
- Layered Architecture
- Event Sourcing
- Event-Driven Architecture
- Outbox Pattern
- Saga Pattern
- Stability Patterns

---

## `/acc-audit-ddd`

**Path:** `commands/acc-audit-ddd.md`

DDD compliance analysis for PHP projects.

**Usage:**
```
/acc-audit-ddd <path-to-project>
```

---

## `/acc-audit-psr`

**Path:** `commands/acc-audit-psr.md`

PSR compliance analysis for PHP projects.

**Usage:**
```
/acc-audit-psr <path-to-project>
```

**Checks:**
- PSR-1/PSR-12 coding style compliance
- PSR-4 autoloading structure
- PSR interface implementations

---

## `/acc-write-documentation`

**Path:** `commands/acc-write-documentation.md`

Generate documentation for a file, folder, or project.

**Usage:**
```
/acc-write-documentation <path-to-document>
```

**Generates:**
- README.md for projects
- ARCHITECTURE.md with diagrams
- API documentation
- Getting started guides

---

## `/acc-audit-documentation`

**Path:** `commands/acc-audit-documentation.md`

Audit documentation quality.

**Usage:**
```
/acc-audit-documentation <path-to-audit>
```

**Checks:**
- Completeness (all APIs documented)
- Accuracy (code matches docs)
- Clarity (no jargon, working examples)
- Consistency (uniform style)
- Navigation (working links)

---

## Navigation

[← Back to README](../README.md) | [Agents →](agents.md) | [Skills](skills.md) | [Component Flow](component-flow.md) | [Quick Reference](quick-reference.md)
