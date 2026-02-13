---
name: acc-check-doc-links
description: Проверяет ссылки в документации. Обнаруживает битые относительные ссылки, отсутствующие якоря, некорректные URL и потерянные файлы документации.
---

# Проверка ссылок в документации

Анализ файлов документации на предмет битых ссылок, отсутствующих целей и проблем навигации.

## Паттерны обнаружения

### 1. Битые относительные ссылки

```markdown
<!-- BROKEN: Target file doesn't exist -->
See [installation guide](docs/install.md)
<!-- File docs/install.md not found -->

<!-- BROKEN: Wrong path depth -->
See [API docs](../docs/api.md)
<!-- Should be ./docs/api.md -->

<!-- BROKEN: Case mismatch -->
See [README](readme.md)
<!-- Actual file is README.md -->
```

### 2. Битые якорные ссылки

```markdown
<!-- BROKEN: Anchor target doesn't exist in file -->
See [Configuration](#configuration)
<!-- No ## Configuration heading found -->

<!-- BROKEN: Anchor in another file -->
See [API Authentication](docs/api.md#auth)
<!-- docs/api.md exists but has no ## Auth heading -->

<!-- BROKEN: Wrong anchor format -->
See [Setup](#set-up)
<!-- Heading is "## Set Up" → anchor should be #set-up -->
```

### 3. Некорректные URL

```markdown
<!-- MALFORMED: Missing protocol -->
See [docs](www.example.com/docs)

<!-- MALFORMED: Space in URL -->
See [guide](docs/getting started.md)

<!-- MALFORMED: Unencoded special characters -->
See [API](docs/api?version=2&format=json)
```

### 4. Потерянная документация

```markdown
<!-- File exists but no other doc links to it -->
docs/deprecated-api.md    <!-- Not linked from any other .md file -->
docs/internal-notes.md    <!-- Not in any navigation/TOC -->
```

## Grep-паттерны

```bash
# All markdown links (relative)
Grep: "\]\([^http][^:][^/][^)]+\)" --glob "**/*.md"

# All markdown links (absolute)
Grep: "\]\(https?://[^)]+\)" --glob "**/*.md"

# Anchor links
Grep: "\]\(#[^)]+\)" --glob "**/*.md"

# Cross-file anchor links
Grep: "\]\([^)]+\.md#[^)]+\)" --glob "**/*.md"

# Image references
Grep: "!\[[^\]]*\]\([^)]+\)" --glob "**/*.md"

# HTML links in markdown
Grep: "href=\"[^\"]+\"" --glob "**/*.md"
```

## Процесс проверки

### Шаг 1: Извлечение всех ссылок

```bash
# Find all relative links
Grep: "\]\(([^http][^)]+)\)" --glob "**/*.md"

# Find all anchor links
Grep: "\]\((#[^)]+)\)" --glob "**/*.md"
```

### Шаг 2: Проверка существования целей

For each relative link `[text](path)`:
1. Resolve path relative to the source file's directory
2. Check if target file exists using `Glob`
3. If link has `#anchor`, verify heading exists in target

### Шаг 3: Проверка целей якорей

For each anchor link `[text](#heading)`:
1. Convert heading to anchor: lowercase, replace spaces with `-`, remove special chars
2. Search for matching heading in the file
3. Report if no match found

### Шаг 4: Поиск потерянной документации

```bash
# List all .md files
Glob: **/*.md

# For each file, check if it's referenced by any other .md
Grep: "filename.md" --glob "**/*.md"
# If referenced by 0 files and not README/CHANGELOG → orphaned
```

## Классификация по степени важности

| Паттерн | Важность |
|---------|----------|
| Битая ссылка на критическую документацию (README, install) | 🔴 Критическая |
| Битая относительная ссылка | 🟠 Высокая |
| Битая якорная ссылка | 🟡 Средняя |
| Некорректный URL | 🟡 Средняя |
| Потерянная документация | 🟡 Средняя |

## Формат вывода

```markdown
### Проверка ссылок: [Описание]

**Важность:** 🔴/🟠/🟡
**Источник:** `file.md:line`
**Ссылка:** `[text](target)`
**Тип:** Relative/Anchor/External/Image

**Проблема:**
[Описание — цель не найдена, якорь отсутствует и т.д.]

**Исправление:**
- Правильный путь: `[text](correct/path.md)`
- Или удалить битую ссылку
```

## Формат сводного отчета

```markdown
## Сводка проверки ссылок

| Метрика | Количество |
|--------|-------|
| Всего проверено ссылок | X |
| Корректных ссылок | X |
| Битых относительных ссылок | X |
| Битых якорей | X |
| Некорректных URL | X |
| Потерянных файлов | X |

### Битые ссылки

| Источник | Ссылка | Проблема |
|--------|------|-------|
| `README.md:45` | `[guide](docs/guide.md)` | Файл не найден |
| `docs/api.md:12` | `[auth](#authentication)` | Якорь не найден |
```
