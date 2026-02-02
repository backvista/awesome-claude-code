---
description: Generate or rewrite documentation for a file/folder. Creates README, architecture docs, Mermaid diagrams. Use when you need to create or improve technical documentation.
allowed-tools: Read, Write, Edit, Glob, Grep, Task
model: opus
argument-hint: <path-to-document>
---

# Write Documentation

Generate high-quality technical documentation for a file, folder, or project.

## Target

Document: `$ARGUMENTS`

If no path provided, document the current working directory.

## Pre-flight Check

1. **Verify the path exists:**
   - If `$ARGUMENTS` is empty, ask user what they want to document
   - If path doesn't exist, report error and stop

2. **Determine documentation type:**
   - File → API documentation, code examples
   - Directory → README, architecture docs
   - Project root → Full documentation suite

## Documentation Flow

```
/acc-write-documentation <path>
    │
    ├─ Pre-flight: Validate path exists
    │
    ├─ Phase 1: Analyze project scope
    │   ├─ Read composer.json (if exists)
    │   ├─ Identify project type (library/app/API)
    │   └─ Determine audience
    │
    ├─ Phase 2: Task → acc-documentation-writer
    │   └─ Generate appropriate documentation
    │
    ├─ Phase 3: Task → acc-diagram-designer (if architecture docs)
    │   └─ Create Mermaid diagrams
    │
    └─ Output: Generated documentation files
```

## Instructions

Use the `acc-documentation-writer` agent to create documentation:

### For Project Root (default)

Generate complete documentation suite:

1. **README.md** — Project overview, installation, quick start
2. **docs/getting-started.md** — Detailed tutorial
3. **docs/architecture.md** — System architecture (if complex)

### For Directory

Generate contextual documentation:

| Directory Type | Output |
|----------------|--------|
| `src/` | Architecture overview + API index |
| `src/Domain/` | Domain model documentation |
| `src/Api/` | API endpoint documentation |
| `docs/` | Improve existing docs |

### For File

Generate specific documentation:

| File Type | Output |
|-----------|--------|
| Class file | Class documentation with examples |
| Interface | API documentation |
| Config file | Configuration reference |

## Diagram Generation

For architecture documentation, invoke the diagram designer:

```
Task tool with subagent_type="acc-diagram-designer"
prompt: "Create diagrams for {target}. Include:
- System context (if project)
- Layer diagram (if DDD/Clean Architecture)
- Component interactions (if multiple services)"
```

## Expected Output

### For README.md

```markdown
# {Project Name}

{badges}

{one-line description}

## Features
{bullet list with benefits}

## Installation
{composer/setup commands}

## Quick Start
{minimal working example}

## Documentation
{links to docs}

## Contributing
{contributing link}

## License
{license}
```

### For Architecture Documentation

```markdown
# Architecture

## Overview
{high-level description}

## System Context
{C4 context diagram - Mermaid}

## Layers
{layer diagram - Mermaid}

## Components
{component descriptions}

## Technology Stack
{technology table}
```

### For API Documentation

```markdown
# API Reference

## {ClassName}

### Overview
{class purpose}

### Methods

#### method(params): ReturnType
{description}

**Parameters:**
| Name | Type | Description |
|------|------|-------------|

**Returns:** {description}

**Example:**
```php
// usage example
```
```

## Documentation Quality Checklist

Generated documentation must have:

- [ ] Clear project description
- [ ] Installation instructions (if applicable)
- [ ] Working code examples
- [ ] Appropriate diagrams (for architecture)
- [ ] Links to related documentation
- [ ] Consistent formatting

## Usage Examples

```bash
# Document entire project
/acc-write-documentation

# Document specific directory
/acc-write-documentation src/Domain/Order

# Document specific file
/acc-write-documentation src/Service/PaymentService.php

# Document API
/acc-write-documentation src/Api/
```

## Follow-up

After generating documentation, suggest:

1. **Review generated files** for accuracy
2. **Run `/acc-audit-documentation`** for quality check
3. **Add/update diagrams** if needed
