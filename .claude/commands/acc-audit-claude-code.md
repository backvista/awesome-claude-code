---
description: Comprehensive audit of .claude folder. Checks structure, quality, cross-references, antipatterns, resource usage (orphaned components), behavior verification (description vs implementation), and context alignment (project architecture support).
allowed-tools: Read, Glob, Grep, Bash
model: opus
---

# Claude Code Configuration Audit

Perform a comprehensive audit of the `.claude/` folder in the current project.

## Pre-flight Check

1. Check if `.claude/` folder exists in the current working directory
2. If missing, skip to **Missing Configuration** section

## Audit Process

### Step 1: Scan Structure

Discover all components:

```
.claude/
├── commands/           # Slash commands (*.md)
├── agents/             # Custom agents (*.md)
├── skills/             # Skills (name/SKILL.md)
├── plans/              # Plan files
├── settings.json       # Project settings
├── settings.local.json # Local settings (gitignored)
├── CLAUDE.md           # Project instructions
└── README.md           # Documentation
```

Use Glob to find:
- `.claude/commands/*.md`
- `.claude/agents/*.md`
- `.claude/skills/*/SKILL.md`
- `.claude/settings.json`
- `.claude/settings.local.json`
- `.claude/CLAUDE.md`

### Step 2: Analyze Each Component

For each file found, evaluate against quality criteria:

#### Commands Quality Criteria

| Criterion | ✅ Good | ⚠️ Improve | ❌ Problem |
|-----------|---------|------------|------------|
| YAML frontmatter | Valid, all fields | Missing optional fields | Invalid/missing |
| Description | Clear, specific | Too generic | Missing |
| Instructions | Step-by-step, clear | Vague steps | No instructions |
| $ARGUMENTS handling | Documented, validated | Used but not documented | Ignored |
| Tool restrictions | Appropriate for task | Too permissive | Missing when needed |

#### Agents Quality Criteria

| Criterion | ✅ Good | ⚠️ Improve | ❌ Problem |
|-----------|---------|------------|------------|
| YAML frontmatter | name, description, tools | Missing optional | Invalid/missing |
| Name | Lowercase, hyphenated | Inconsistent casing | Invalid characters |
| Description | Specific purpose | Too generic | Missing |
| Tool restrictions | Minimal needed set | Missing restrictions | Overly broad |
| Skills reference | Links to skills | No skill usage | Broken references |

#### Skills Quality Criteria

| Criterion | ✅ Good | ⚠️ Improve | ❌ Problem |
|-----------|---------|------------|------------|
| Location | name/SKILL.md structure | Flat file | Wrong location |
| YAML frontmatter | name, description | Missing fields | Invalid |
| Size | Under 500 lines | 500-1000 lines | Over 1000 lines |
| References | Large content in references/ | Everything in SKILL.md | Missing needed refs |
| Trigger conditions | Clear "when to use" | Vague triggers | No triggers |

#### Settings Quality Criteria

| Criterion | ✅ Good | ⚠️ Improve | ❌ Problem |
|-----------|---------|------------|------------|
| JSON validity | Valid JSON | - | Parse errors |
| Hooks | Defined and documented | Undocumented | Invalid format |
| Permissions | Explicit allow/deny | Implicit defaults | Overly permissive |
| Local settings | Gitignored properly | Not gitignored | Secrets exposed |

### Step 3: Check Cross-References

Verify integrity:
- Commands referencing agents → agents exist
- Agents referencing skills → skills exist
- Skills referencing other files → files exist

### Step 4: Detect Antipatterns

Common issues to flag:

1. **Duplicate functionality** — Multiple commands doing similar things
2. **Missing descriptions** — Components without clear purpose
3. **Hardcoded paths** — Paths that won't work in other projects
4. **Overly long files** — Skills over 500 lines, commands over 200 lines
5. **No tool restrictions** — Commands/agents with unlimited tool access
6. **Inconsistent naming** — Mixed naming conventions
7. **Missing error handling** — Commands without pre-flight checks
8. **Secrets in settings** — API keys or sensitive data in versioned files

### Step 5: Resource Usage Analysis

Build dependency graph and find unused components:

#### 5.1 Build Usage Graph

Extract references from all components:

1. **Commands → Agents**: Parse command bodies for agent references
   - Look for Task tool calls with agent names
   - Pattern: `acc-*-agent`, `acc-*-auditor`, `acc-*-generator`, `acc-*-expert`, `acc-*-writer`, `acc-*-designer`

2. **Agents → Skills**: Parse agent frontmatter `skills:` field
   - Extract skill names from YAML list
   - Also check agent body for skill mentions

3. **Skills → Skills**: Parse skill bodies for cross-references
   - Look for skill name patterns in instructions

#### 5.2 Find Orphans

Compare discovered components against usage graph:

- **Orphaned skills** — Skills not referenced by any agent
- **Orphaned agents** — Agents not referenced by any command
- **Undocumented commands** — Commands not mentioned in README.md

#### 5.3 Resource Report Format

```
📊 Resource Usage Analysis
├── Active components: X/Y (Z%)
├── Orphaned skills: [list or "none"]
├── Orphaned agents: [list or "none"]
├── Undocumented commands: [list or "none"]
└── Circular references: [list or "none"]
```

### Step 6: Behavior Verification

Verify that component descriptions match actual behavior:

#### 6.1 Extract Declared Behavior

For each component, parse:
- `description` field — what it claims to do
- `argument-hint` — expected input format
- Key action verbs: generates, creates, audits, analyzes, validates, executes

#### 6.2 Extract Actual Behavior

Analyze component body:
- Tool usage patterns (Write = generates, Read/Grep = audits, Bash = executes)
- `$ARGUMENTS` handling — is it used if argument-hint is present?
- Output patterns — what the component actually produces

#### 6.3 Behavior Mapping Rules

| Description verb | Expected tools | Validation |
|------------------|----------------|------------|
| "generates", "creates", "writes" | Write, Edit | Must modify files |
| "audits", "analyzes", "checks" | Read, Grep, Glob | Must read files |
| "executes", "runs" | Bash | Must run commands |
| "validates" | Read, Grep | Must check criteria |

#### 6.4 Behavior Report Format

```
📋 Behavior Verification
├── ✅ acc-commit.md — description matches behavior
├── ⚠️ acc-foo.md — claims "generates" but no Write tool
├── ❌ acc-bar.md — argument-hint defined but $ARGUMENTS unused
└── Summary: X/Y components verified (Z%)
```

### Step 7: Context Awareness

Check alignment with project architecture and goals:

#### 7.1 Detect Project Context

Read project configuration files:
- `CLAUDE.md` (root) — global instructions
- `.claude/CLAUDE.md` — project-specific rules
- `README.md` — project purpose and tech stack
- `composer.json` — PHP dependencies (if exists)

#### 7.2 Identify Project Patterns

Look for mentions of:
- Architecture patterns: DDD, CQRS, Clean Architecture, Hexagonal, Event Sourcing
- Standards: PSR-1, PSR-4, PSR-12, etc.
- Frameworks: Symfony, Laravel, etc.
- Tech stack: PHP version, databases, queues

#### 7.3 Verify Alignment

Check if Claude configuration supports detected patterns:

| Project mentions | Required support |
|------------------|------------------|
| DDD | DDD audit command, DDD skills |
| CQRS | CQRS skills |
| PSR-* | PSR audit command, PSR skills |
| Event Sourcing | Event skills |
| PHP X.Y | Skills compatible with version |

#### 7.4 Context Report Format

```
🎯 Context Alignment
├── Project type: [detected patterns]
├── Tech stack: [detected technologies]
├── Pattern coverage:
│   ├── ✅ DDD — full support (audit + 13 skills)
│   ├── ✅ CQRS — full support (4 skills)
│   ├── ⚠️ Event Sourcing — partial (mentioned but no skills)
│   └── ❌ Laravel — not supported (no framework-specific skills)
└── Suggestions:
    └── 💡 Add Event Sourcing skills (mentioned in CLAUDE.md)
```

## Output Format

Generate a structured markdown report:

### 1. Overview

```
📁 .claude/ Audit Report
========================

📊 Summary
├── Commands:  X found (Y issues)
├── Agents:    X found (Y issues)
├── Skills:    X found (Y issues)
├── Settings:  X files (Y issues)
├── Resource usage: X% active
├── Behavior match: X%
├── Context alignment: X%
└── Total issues: X critical, Y warnings, Z suggestions
```

### 2. File Tree

Show discovered structure with status indicators:
```
.claude/
├── commands/
│   ├── ✅ acc-commit.md
│   ├── ⚠️ my-command.md (missing description)
│   └── ❌ broken.md (invalid YAML)
├── agents/
│   └── ✅ my-agent.md
├── skills/
│   └── ⚠️ my-skill/SKILL.md (too long: 800 lines)
└── ✅ settings.json
```

### 3. Detailed Analysis

For each file with issues:

```markdown
#### ⚠️ commands/my-command.md

**Issues:**
- Missing `description` in frontmatter
- No $ARGUMENTS validation
- Uses Bash without restriction

**Current:**
```yaml
---
allowed-tools: Bash
---
```

**Recommended:**
```yaml
---
description: Brief description of what this command does
allowed-tools: Bash, Read
argument-hint: <required-argument>
---

## Pre-flight Check
Validate $ARGUMENTS before proceeding...
```
```

### 4. Recommendations

Prioritized action items:

| Priority | File | Issue | Fix |
|----------|------|-------|-----|
| ❌ Critical | broken.md | Invalid YAML | Fix frontmatter syntax |
| ⚠️ High | my-command.md | No description | Add description field |
| 💡 Suggestion | settings.json | No hooks | Consider adding pre-commit hook |

### 5. Resource Usage

```
📊 Resource Usage Analysis
├── Active components: 81/84 (96%)
├── Orphaned skills:
│   └── acc-example-skill (not used by any agent)
├── Orphaned agents: none
├── Undocumented commands: none
└── Circular references: none
```

**Recommendation:**
- Remove orphaned skills or add them to relevant agents
- Document the purpose of undocumented commands

### 6. Behavior Verification

```
📋 Behavior Verification
├── Commands: 8/8 verified
│   ├── ✅ acc-commit.md — "generates commit" + Bash ✓
│   ├── ✅ acc-audit-ddd.md — "audits" + Read/Grep ✓
│   └── ...
├── Agents: 11/11 verified
└── Skills: 73/73 verified
```

**Mismatches found:**
| Component | Declared | Actual | Issue |
|-----------|----------|--------|-------|
| acc-foo.md | "generates files" | No Write tool | Missing tool capability |
| acc-bar.md | argument-hint: <path> | $ARGUMENTS unused | Argument not processed |

### 7. Context Alignment

```
🎯 Context Alignment
├── Project context detected:
│   ├── Architecture: DDD, CQRS, Clean Architecture
│   ├── Standards: PSR-1, PSR-4, PSR-12
│   ├── Tech: PHP 8.5, Redis, RabbitMQ
│   └── Principles: SOLID, GRASP
├── Pattern coverage:
│   ├── ✅ DDD — full (audit + 13 skills)
│   ├── ✅ CQRS — full (4 skills)
│   ├── ✅ PSR — full (audit + 11 skills)
│   ├── ✅ SOLID — full (knowledge + analyzer)
│   └── ✅ GRASP — full (knowledge skill)
└── Suggestions: none
```

**Gaps identified:**
| Context | Required | Available | Status |
|---------|----------|-----------|--------|
| Event Sourcing | skills/audit | knowledge only | ⚠️ Partial |
| Redis | cache skills | none | 💡 Consider |

### 8. Quick Fixes

Ready-to-apply fixes for common issues:

```markdown
**Fix: Add missing description to my-command.md**
Add this to the YAML frontmatter:
description: [Describe what this command does and when to use it]
```

## Missing Configuration

If `.claude/` folder is missing or empty, provide starter template:

```markdown
## Recommended Structure

Your project is missing Claude Code configuration. Here's a starter setup:

### 1. Create basic structure

```bash
mkdir -p .claude/commands .claude/agents .claude/skills
```

### 2. Create CLAUDE.md

```markdown
# CLAUDE.md

## Project Overview
[Describe your project]

## Architecture
[Key patterns and structures]

## Commands
- `make test` — run tests
- `make lint` — check code style
```

### 3. Create settings.json

```json
{
  "hooks": {
    "PreToolUse": []
  },
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

### 4. Add to .gitignore

```
.claude/settings.local.json
```
```

## Usage

```bash
/acc-audit-claude-code
```
