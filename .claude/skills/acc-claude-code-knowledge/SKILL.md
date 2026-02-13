---
name: acc-claude-code-knowledge
description: Исчерпывающая база знаний по форматам, паттернам и конфигурации Claude Code. Используется при создании, улучшении или аудите команд, агентов, навыков, хуков, памяти, плагинов и настроек.
---

# База знаний Claude Code

## Обзор типов компонентов

| Тип | Путь | Вызов | Стоимость контекста |
|------|------|------------|--------------|
| Command | `.claude/commands/name.md` | `/name args` | Загружается при вызове |
| Agent | `.claude/agents/name.md` | `Task(subagent_type)` | Загружается в контекст субагента |
| Skill | `.claude/skills/name/SKILL.md` | Авто или `/name` | Загружается по совпадению description |
| Hook | `.claude/settings.json` | Автоматически по событию | Нулевая (shell-скрипт) |
| Rules | `.claude/rules/*.md` | Загружается всегда | Всегда в system prompt |
| Memory | `CLAUDE.md` (различные уровни) | Загружается всегда | Всегда в system prompt |

---

## Команды (Commands)

**Путь:** `.claude/commands/name.md`
**Вызов:** `/name` или `/name arguments`

```yaml
---
description: Required. What the command does.
allowed-tools: Optional. Restrict tools (comma-separated).
model: Optional. opus/sonnet/haiku — or alias from settings.
argument-hint: Optional. Hint shown in autocomplete.
---

Command instructions here.

Use $ARGUMENTS for full argument string.
Use $ARGUMENTS[0], $ARGUMENTS[1] for positional args.
Use $1, $2 as shorthand for $ARGUMENTS[N].
Use ${CLAUDE_SESSION_ID} for session identifier.
```

**Ключевые правила:**
- Эквивалент `.claude/skills/name/SKILL.md` с `user-invocable: true`
- Команды в подкаталогах: `.claude/commands/sub/name.md` → `/sub/name`
- Бюджет: `SLASH_COMMAND_TOOL_CHAR_BUDGET` (по умолчанию 15000 символов)

---

## Агенты (Subagents)

**Путь:** `.claude/agents/name.md`
**Вызов:** инструмент `Task` с `subagent_type="name"`

```yaml
---
name: agent-name            # required, matches filename without .md
description: Required. When to use. "PROACTIVELY" for auto-invoke.
tools: Optional. All by default. Comma-separated.
disallowedTools: Optional. Denylist complement to tools.
model: Optional. opus | sonnet | haiku | inherit
permissionMode: Optional. default | acceptEdits | plan | dontAsk | delegate | bypassPermissions
skills: Optional. Auto-load skills (comma-separated inline list).
hooks: Optional. Lifecycle hooks scoped to this agent.
memory: Optional. user | project | local — CLAUDE.md scope to load.
---

Agent system prompt here.
```

**Режимы разрешений:**
- `default` — спрашивать пользователя для каждого использования инструмента
- `acceptEdits` — автоматически разрешать редактирование файлов, спрашивать для остального
- `plan` — только чтение и исследование, без записи
- `dontAsk` — выполнять без вопросов, в пределах sandbox
- `delegate` — наследовать разрешения родителя
- `bypassPermissions` — пропускать все проверки разрешений (опасно)

**Встроенные типы субагентов:** Explore, Plan, general-purpose, Bash, statusline-setup, claude-code-guide

**Выполнение:** foreground (блокирует) или background (`run_in_background: true`). Возобновление по ID агента.

**Приоритет:** CLI-флаг `--agents` > проектные `.claude/agents/` > пользовательские `~/.claude/agents/` > плагинные агенты

---

## Навыки (Skills)

**Путь:** `.claude/skills/name/SKILL.md`
**Вызов:** `/name` (если user-invocable) или автозагрузка агентом/по совпадению description

```yaml
---
name: skill-name            # lowercase, hyphens, max 64 chars
description: Required. What and when. Max 1024 chars.
allowed-tools: Optional. Restrict tools.
model: Optional. Model override when skill is active.
context: Optional. "fork" for isolated subagent execution.
agent: Optional. Which subagent type to run in (Explore, Plan, etc).
hooks: Optional. Lifecycle hooks scoped to this skill.
disable-model-invocation: true   # only user can invoke
user-invocable: false            # only Claude can invoke
---

Skill instructions here.

Use $ARGUMENTS, $ARGUMENTS[N], $N for user input.
Use !`command` for dynamic context injection (shell output inserted).
```

**Структура каталога:**
```
skill-name/
├── SKILL.md        # required, max 500 lines
├── references/     # large content extracted here
├── scripts/        # executable code
└── assets/         # templates, resources
```

**Матрица управления вызовом:**

| `disable-model-invocation` | `user-invocable` | Кто может вызвать |
|---------------------------|------------------|----------------|
| false (default) | true (default) | И пользователь, и Claude |
| true | true | Только пользователь (через `/name`) |
| false | false | Только Claude (автозагрузка) |
| true | false | Никто (отключено) |

---

## Хуки (Hooks)

**Путь:** `.claude/settings.json` (или поле `hooks:` в frontmatter агента/навыка)

### События хуков (12)

| Событие | Когда | Matcher | Может блокировать |
|-------|------|---------|-----------|
| `PreToolUse` | Перед выполнением инструмента | Имя инструмента | Да |
| `PostToolUse` | После выполнения инструмента | Имя инструмента | Нет |
| `Notification` | При уведомлении | — | Нет |
| `Stop` | Агент останавливается | — | Нет |
| `SubagentStop` | Субагент завершил работу | Имя агента | Нет |
| `PreCompact` | Перед сжатием контекста | — | Нет |
| `PostCompact` | После сжатия контекста | — | Нет |
| `ToolError` | Ошибка выполнения инструмента | Имя инструмента | Нет |
| `PreUserInput` | Перед обработкой сообщения пользователя | — | Нет |
| `PostUserInput` | После обработки сообщения пользователя | — | Нет |
| `SessionStart` | Начало сессии | — | Нет |
| `SessionEnd` | Конец сессии | — | Нет |

### Типы хуков (3)

```json
{"type": "command", "command": "./script.sh"}
{"type": "prompt", "prompt": "Check if output is safe"}
{"type": "agent", "agent": "validator-agent"}
```

### Коды выхода

| Код | Поведение |
|------|----------|
| 0 | Разрешить (продолжить) |
| 2 | Заблокировать (запретить использование инструмента, только PreToolUse) |
| Другой | Записать предупреждение, продолжить |

### Конфигурация хуков

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {"type": "command", "command": "php -l $CLAUDE_FILE_PATH", "async": false}
        ]
      }
    ]
  }
}
```

**Паттерны matcher:** точное имя, `|` ИЛИ, regex. MCP-инструменты: `mcp__server__tool`.

Подробный справочник по хукам см. [references/hooks-reference.md](references/hooks-reference.md).

---

## Память и CLAUDE.md

### Иерархия (сверху вниз, выше = выше приоритет)

| Уровень | Расположение | Область действия |
|-------|----------|-------|
| Managed | Системные каталоги (enterprise) | Вся организация |
| User | `~/.claude/CLAUDE.md` | Все проекты пользователя |
| User rules | `~/.claude/rules/*.md` | Все проекты пользователя |
| Project | `CLAUDE.md` (корень проекта) | Текущий проект |
| Project rules | `.claude/rules/*.md` | Текущий проект |
| Local | `CLAUDE.local.md` (корень проекта, auto-gitignored) | Только эта машина |
| Nested | `src/CLAUDE.md`, `tests/CLAUDE.md` | Контекст подкаталога |

### Файлы правил

`.claude/rules/*.md` — модульные правила, всегда загружаются в system prompt.

**Правила по путям** через frontmatter `paths`:
```yaml
---
paths:
  - src/Domain/**
  - src/Application/**
---
These rules apply only when working with files matching the glob patterns above.
```

### Синтаксис импорта

```markdown
@path/to/file.md      # relative to current file
@/absolute/path.md    # absolute path
@~/user/path.md       # home directory
```

Лимит рекурсии импорта: максимум 5 переходов.

### Команды

- `/memory` — просмотр и редактирование файлов памяти
- `/init` — генерация начального CLAUDE.md на основе анализа проекта

Полный справочник см. [references/memory-and-rules.md](references/memory-and-rules.md).

---

## Плагины

**Путь:** `.claude-plugin/plugin.json` (корень плагина)

```json
{
  "name": "my-plugin",
  "description": "What this plugin provides",
  "version": "1.0.0",
  "author": "Name",
  "repository": "https://github.com/user/repo"
}
```

**Структура плагина:**
```
.claude-plugin/
├── plugin.json         # manifest (required)
├── commands/           # namespaced as /plugin:command
├── agents/             # available as subagent_type
├── skills/             # namespaced as /plugin:skill
├── hooks/hooks.json    # plugin-scoped hooks
├── .mcp.json           # MCP server config
└── .lsp.json           # LSP server config
```

**Вызов с пространством имён:** `/plugin-name:skill-name`

**Источники установки:** GitHub, Git URL, NPM, локальный путь, каталог.

Полный справочник см. [references/plugins-reference.md](references/plugins-reference.md).

---

## Разрешения

### Синтаксис правил

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep"],
    "deny": ["Bash(rm *)"],
    "ask": ["Write", "Edit"]
  }
}
```

**Паттерны спецификаторов:**

| Паттерн | Пример | Совпадает с |
|---------|---------|---------|
| `Tool` | `Read` | Все вызовы Read |
| `Tool(literal)` | `Bash(npm test)` | Точная команда |
| `Tool(glob)` | `Read(src/**)` | Gitignore-style glob |
| `Tool(domain:)` | `WebFetch(domain:api.example.com)` | Фильтр по домену |
| `mcp__server__tool` | `mcp__github__create_issue` | MCP-инструмент |
| `Task(agent)` | `Task(acc-ddd-auditor)` | Конкретный субагент |

**Порядок вычисления:** deny → ask → allow (deny побеждает allow)

Полный справочник см. [references/settings-and-permissions.md](references/settings-and-permissions.md).

---

## MCP (Model Context Protocol)

**Конфигурация:** `.mcp.json` (корень проекта) или в `settings.json`

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-name"],
      "env": {"API_KEY": "..."}
    }
  }
}
```

**Именование инструментов:** `mcp__servername__toolname`

**Иерархия области действия:** проектный `.mcp.json` > пользовательские настройки > плагинный `.mcp.json`

**Разрешения:** `enableAllProjectMcpServers`, `allowedMcpServers`, `deniedMcpServers` в настройках.

---

## Настройки

**Иерархия:** managed > CLI-аргументы > local > project > user

| Уровень | Расположение |
|-------|----------|
| User | `~/.claude/settings.json` |
| Project | `.claude/settings.json` |
| Local | `.claude/settings.local.json` (gitignored) |
| Managed | Системные каталоги enterprise |

**Ключевые области настроек:** разрешения, хуки, sandbox, MCP, конфигурация модели, управление контекстом, атрибуция.

Полная схема настроек см. [references/settings-and-permissions.md](references/settings-and-permissions.md).

---

## Фреймворк принятия решений

Какой тип компонента использовать:

| Цель | Лучший компонент | Причина |
|------|---------------|--------|
| Переиспользуемый промпт | **Command** | Пользователь вызывает, низкая стоимость контекста |
| Сложный анализ в изоляции | **Agent** | Отдельное контекстное окно |
| База знаний / шаблоны | **Skill** | Автозагрузка, общий для агентов |
| Автотриггер по событиям | **Hook** | Нулевая стоимость контекста, shell-выполнение |
| Инструкции для всего проекта | **CLAUDE.md** | Всегда в контексте |
| Правила для конкретных путей | **Rules** (`.claude/rules/`) | Условная загрузка |
| Распространяемое расширение | **Plugin** | С пространством имён, устанавливаемый |
| Интеграция внешних инструментов | **MCP** | Стандартизированный протокол |

### Учёт стоимости контекста

| Компонент | Влияние на бюджет контекста |
|-----------|---------------------|
| CLAUDE.md + rules | Загружаются всегда (~500 строк рекомендуемый максимум) |
| Skills (автозагрузка) | Загружаются при совпадении description (~15K символов бюджет) |
| Skills (по агенту) | Загружаются в контекстное окно агента |
| Agents | Отдельное контекстное окно (без стоимости для родителя) |
| Hooks (тип command) | Нулевая стоимость контекста (shell-выполнение) |
| Hooks (тип prompt/agent) | Используют контекст для LLM-оценки |
| MCP tools | Описания инструментов всегда в контексте |
| Plugins | Компоненты загружаются по правилам их типа |

---

## Паттерны

### Параллельные агенты
```
Run in parallel:
1. Task: researcher — study architecture
2. Task: security-scanner — check security
3. Task: performance-analyzer — check performance

Wait for all and combine results.
```

### Прогрессивное раскрытие
```
SKILL.md — brief instructions (max 500 lines)
references/ — details loaded when needed
scripts/ — execute without reading into context
```

### Цепочка агентов
```
1. researcher → studies the task
2. planner → creates plan based on research
3. implementer → implements the plan
4. reviewer → reviews implementation
```

### Команды агентов (паттерн координатора)
```
coordinator (opus) → delegates via Task tool
├── auditor-1 (sonnet, parallel)
├── auditor-2 (sonnet, parallel)
└── generator (sonnet, sequential after audit)

Coordinator uses TaskCreate/TaskUpdate for progress tracking.
```

### Распространение плагинов
```
Package as .claude-plugin/ → publish to GitHub/NPM
Users install: enabledPlugins in settings
Skills namespaced: /plugin-name:skill-name
```

---

## Чек-листы валидации

### Команды
- [ ] `description` заполнено и конкретно
- [ ] Путь: `.claude/commands/*.md`
- [ ] `$ARGUMENTS` используется, если определён `argument-hint`
- [ ] `model` выбрана осознанно (opus для сложных, haiku для быстрых)
- [ ] Инструкции ясные и пошаговые

### Агенты
- [ ] `name` и `description` заполнены
- [ ] `name` совпадает с именем файла (без `.md`)
- [ ] `tools` минимально необходимые
- [ ] `disallowedTools` используется, если нужны почти все инструменты кроме нескольких
- [ ] `model` выбрана осознанно
- [ ] `permissionMode` соответствует задаче
- [ ] `skills:` — это inline-список через запятую (не YAML-массив)
- [ ] Координаторы имеют `TaskCreate, TaskUpdate` в tools
- [ ] Координаторы имеют `acc-task-progress-knowledge` в skills

### Навыки
- [ ] `name` в нижнем регистре через дефисы, совпадает с именем каталога
- [ ] `description` < 1024 символов, объясняет «когда использовать»
- [ ] `SKILL.md` < 500 строк
- [ ] Большой контент вынесен в `references/`
- [ ] `context: fork` если нужно изолированное выполнение
- [ ] Путь: `.claude/skills/name/SKILL.md`

### Хуки
- [ ] JSON валидный
- [ ] Имя события — одно из 12 допустимых
- [ ] `matcher` — корректное имя инструмента/агента или паттерн
- [ ] Скрипт `command` существует и исполняемый
- [ ] Коды выхода обрабатываются правильно (0=разрешить, 2=заблокировать)
- [ ] `async: true` только для неблокирующих операций

### Память/Правила
- [ ] `CLAUDE.md` < 500 строк (рекомендуется)
- [ ] `.claude/rules/*.md` для модульных правил
- [ ] `CLAUDE.local.md` в `.gitignore`
- [ ] `@imports` резолвятся (максимум 5 переходов)
- [ ] `paths` во frontmatter используют валидные glob-паттерны

### Настройки
- [ ] Валидный JSON в `settings.json`
- [ ] Правила разрешений следуют порядку deny → ask → allow
- [ ] `settings.local.json` в gitignore
- [ ] Sandbox настроен, если автоматически разрешён Bash
- [ ] MCP-серверы явно разрешены/запрещены

---

## Справочные файлы

Детальная документация по конкретным областям:

- [Hooks Reference](references/hooks-reference.md) — все 12 событий, 3 типа, matchers, I/O, коды выхода
- [Skills Advanced](references/skills-advanced.md) — context:fork, agent, hooks, model, управление вызовом
- [Subagents Advanced](references/subagents-advanced.md) — memory, hooks, disallowedTools, background, resume
- [Memory and Rules](references/memory-and-rules.md) — иерархия CLAUDE.md, rules/, @imports, paths
- [Plugins Reference](references/plugins-reference.md) — структура плагинов, manifest, marketplace, миграция
- [Settings and Permissions](references/settings-and-permissions.md) — полная схема, sandbox, разрешения, переменные окружения
