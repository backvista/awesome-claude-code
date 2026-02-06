# Quick Reference

Component paths, formats, and best practices. Use this as a cheat sheet when creating or modifying components.

## When to Use This Document

- Creating new commands, agents, or skills
- Checking correct YAML frontmatter format
- Finding component paths
- Following best practices

---

## Component Paths

| Type    | Path                           | Invocation       |
|---------|--------------------------------|------------------|
| Command | `.claude/commands/name.md`     | `/name`          |
| Agent   | `.claude/agents/name.md`       | Auto or explicit |
| Skill   | `.claude/skills/name/SKILL.md` | `/name` or auto  |
| Hook    | `.claude/settings.json`        | On event         |

## YAML Frontmatter

### Command

```yaml
---
description: Required
allowed-tools: Optional
model: Optional (sonnet/haiku/opus)
argument-hint: Optional
---
```

### Agent

```yaml
---
name: Required
description: Required
tools: Optional (default: all)
model: Optional (default: sonnet)
permissionMode: Optional
skills: Optional
---
```

### Skill

```yaml
---
name: Required (lowercase, hyphens)
description: Required (max 1024 chars)
allowed-tools: Optional
---
```

## Best Practices

1. **Specific descriptions** — not "helps with code" but "analyzes Python for vulnerabilities"
2. **PROACTIVELY keyword** — triggers automatic agent invocation
3. **Minimal tools** — only what's needed
4. **Skills < 500 lines** — use references/ for details
5. **Test in isolation** — verify before integration

## File Structure

```
.claude/
├── commands/                     # 23 commands
│   ├── acc-audit-*.md            # Audit commands (8): architecture, ci, claude-components,
│   │                             #   ddd, documentation, patterns, performance, psr, security, test
│   ├── acc-bug-fix.md
│   ├── acc-ci-*.md               # CI commands (3): setup, fix, optimize
│   ├── acc-code-review.md
│   ├── acc-commit.md
│   ├── acc-generate-*.md         # Generate commands (3): ddd, patterns, psr
│   ├── acc-refactor.md
│   ├── acc-write-*.md            # Write commands (3): claude-component, documentation, test
│   └── ...
├── agents/                       # 42 agents
│   ├── acc-*-auditor.md          # Auditors (12): architecture, behavioral, creational,
│   │                             #   ddd, documentation, integration, pattern, psr,
│   │                             #   stability, structural, test
│   ├── acc-*-generator.md        # Generators (7): architecture, behavioral, creational,
│   │                             #   ddd, integration, pattern, psr, stability
│   ├── acc-*-coordinator.md      # Coordinators (4): bug-fix, ci, code-review, refactor
│   ├── acc-*-reviewer.md         # Reviewers (4): performance, readability, security, testability
│   ├── acc-ci-*.md               # CI agents (9): ci-coordinator, ci-debugger, ci-fixer,
│   │                             #   ci-security-agent, deployment-agent, docker-agent,
│   │                             #   pipeline-architect, pipeline-optimizer,
│   │                             #   static-analysis-agent, test-pipeline-agent
│   └── ...
├── skills/                       # 157 skills
│   ├── acc-*-knowledge/          # 25 knowledge skills
│   ├── acc-check-*/              # 55 analyzer skills
│   ├── acc-find-*/               # 9 bug detection skills
│   ├── acc-detect-*/             # 6 detection skills
│   ├── acc-analyze-*/            # 4 analysis skills
│   ├── acc-create-*/             # 57 generator skills
│   ├── acc-*-template/           # 9 template skills
│   └── acc-*/                    # 7 other skills (estimate, suggest, bug-*)
└── settings.json

docs/                             # Documentation (root level)
├── commands.md
├── agents.md
├── skills.md
├── component-flow.md
├── hooks.md
├── mcp.md
└── quick-reference.md
```

## Statistics

| Component | Count |
|-----------|-------|
| Commands | 23 |
| Agents | 42 |
| Knowledge Skills | 25 |
| Analyzer Skills | 59 |
| Generator Skills | 57 |
| Template Skills | 9 |
| Other Skills | 7 |
| **Total Skills** | **157** |

---

## Navigation

[← Back to README](../README.md) | [Commands](commands.md) | [Agents](agents.md) | [Skills](skills.md) | [Component Flow](component-flow.md)
