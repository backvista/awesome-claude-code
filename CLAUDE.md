# CLAUDE.md

Этот файл предоставляет руководство для Claude Code (claude.ai/code) при работе с кодом в этом репозитории.

## Обзор проекта

Composer-плагин (тип `composer-plugin`), предоставляющий расширения Claude Code для PHP-разработки с паттернами DDD, CQRS и Clean Architecture. Устанавливается через `composer require backvista/awesome-claude-code`. Плагин автоматически копирует компоненты `.claude/` (команды, агенты, навыки) в целевой проект при install/update, никогда не перезаписывая существующие файлы.

## Команды

```bash
make help                   # Показать все доступные make-цели (по умолчанию)
make validate-claude        # Валидация структуры .claude/ — запускать перед каждым коммитом
make list-commands          # Список всех slash-команд
make list-agents            # Список всех агентов
make list-skills            # Список всех навыков
make test                   # Установка в Docker-тестовом окружении (tests/)
make test-clear             # Очистка тестового окружения
make changelog              # Показать последние git-коммиты для changelog
make release                # Запуск validate-claude, затем вывод инструкций по релизу
./bin/acc upgrade                        # Принудительное обновление компонентов (создаёт резервную копию)
./bin/acc upgrade --no-backup            # Обновление без резервной копии
./bin/acc upgrade --component=commands   # Обновление только commands|agents|skills
```

**Тестирование**: `make test` выполняет `docker compose run --rm php composer install` в директории `tests/`, что запускает Composer-плагин и копирует компоненты в `tests/.claude/`. Используйте `make test-clear` для сброса.

## Архитектура

```
.claude/
├── commands/     # Slash-команды (26) — вызываемые пользователем через /acc-*
├── agents/       # Субагенты (57) — вызываемые через Task tool с subagent_type
├── skills/       # Навыки (242) — базы знаний, генераторы, анализаторы
└── settings.json # Хуки и список разрешений (НЕ копируется плагином)

src/
└── ComposerPlugin.php  # Единственный PHP-файл — подписывается на POST_PACKAGE_INSTALL/UPDATE

bin/acc                 # CLI-инструмент для принудительного обновления компонентов
docs/                   # commands.md, agents.md, skills.md, hooks.md, component-flow.md, mcp.md, quick-reference.md
tests/                  # Docker-тестовое окружение (Dockerfile + docker-compose.yml + composer.json)
```

### Поток выполнения

```
User → /acc-command → Coordinator Agent (opus) → Specialized Agents (sonnet, параллельно через Task) → Skills → Output
```

**Три типа компонентов со строгой цепочкой интеграции:**

1. **Skill** предоставляет знания или генерирует код (`.claude/skills/name/SKILL.md`, опционально подпапка `references/`)
2. **Agent** ссылается на навыки через frontmatter `skills:`, выполняет анализ/генерацию
3. **Command** делегирует агентам через инструмент `Task` с `subagent_type="agent-name"`

### Категории агентов

- **Координаторы** (6): оркестрируют многоагентные workflow через делегирование Task, используют `model: opus`, имеют `TaskCreate/TaskUpdate` для отслеживания прогресса — `bug-fix-coordinator`, `ci-coordinator`, `code-review-coordinator`, `docker-coordinator`, `explain-coordinator`, `refactor-coordinator`
- **Аудиторы-координаторы** (3): аудит через делегирование суб-агентам, используют `model: opus` — `architecture-auditor`, `pattern-auditor`, `ddd-auditor`
- **Специалисты** (47): выполняют сфокусированные задачи, используют `model: sonnet` — аудиторы, генераторы, ревьюеры, CI/Docker/Explainer агенты

### Composer-плагин

`src/ComposerPlugin.php` — единственный PHP-файл исходного кода. Копирует `.claude/{commands,agents,skills}` из vendor в корень проекта. Пропускает существующие файлы (выводит "Skipping (exists)"). Файлы НЕ копируются: `settings.json`, `settings.local.json` — они специфичны для проекта.

## Ключевые правила

- **Префикс `acc-`** на всех компонентах для избежания конфликтов имён с другими расширениями
- **Разделитель `--`** в командах для мета-инструкций: `/acc-audit-ddd ./src -- focus on aggregates`
- **После любого изменения**: запустите `make validate-claude`, обновите соответствующий файл `docs/*.md` и `CHANGELOG.md`
- **Количество компонентов** появляется в 6 местах — держите все в синхронизации: `README.md` (таблица Documentation), `docs/quick-reference.md` (Statistics + дерево файлов), `composer.json` (description), `llms.txt` (Quick Facts + Project Structure + Skills by Category), `CHANGELOG.md`, `CLAUDE.md` (секция Architecture)
- **Переименование файлов**: всегда используйте `git mv` вместо удаления + создания для сохранения истории git
- **CI/CD `acc-docker-agent`** (для CI-конвейеров) отдельный от Docker Expert System агентов (`acc-docker-coordinator`, `acc-docker-*-agent`) — не объединяйте их
- **`settings.json`** специфичен для проекта (НЕ копируется плагином). Содержит: PostToolUse hook (`php -l` на `.php` файлах после Write), список разрешений (make, git read-only, composer validate, WebSearch)
- **Каждый навык должен быть упомянут** как минимум в frontmatter `skills:` одного агента — осиротевшие навыки вызывают сбои аудита

## Условные правила

`.claude/rules/` содержит контекстно-специфичные правила, загружаемые только при работе с соответствующими файлами:

- `component-creation.md` — спецификации frontmatter команд/агентов/навыков (загружается для редактирования `.claude/`)
- `versioning.md` — workflow версионирования и таблица файлов документации (загружается для CHANGELOG, README, docs/)
- `troubleshooting.md` — диагностическая таблица для распространённых проблем (загружается для `.claude/`, `src/`, Makefile)
