# Changelog

Все notable изменения этого проекта будут задокументированы в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
и этот проект придерживается [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.10.1] - 2026-02-11

### Changed
- Требование к версии PHP снижено с 8.5 до 8.2 в composer.json, Dockerfile и всех описаниях компонентов
- Заменена функция `array_all()` (PHP 8.4) на цикл foreach в референсе information-expert навыка acc-grasp-knowledge

---

## [2.10.0] - 2026-02-09

### Added
- Директория `.claude/rules/` с 3 условными правилами: `component-creation.md`, `versioning.md`, `troubleshooting.md` — загружаются только при работе с соответствующими файлами, экономя контекст
- Агент `acc-cqrs-auditor` — выделенный аудитор паттернов CQRS/ES/EDA (выделен из `acc-behavioral-auditor`)
- Навыки аудита порождающих паттернов (+3): `acc-check-singleton-antipattern` (обнаружение антипаттерна Singleton), `acc-check-abstract-factory` (аудит Abstract Factory), `acc-create-prototype` (генератор паттерна Prototype)
- Навыки аудита паттернов стабильности (+3): `acc-check-timeout-strategy` (аудит конфигурации таймаутов), `acc-check-cascading-failures` (обнаружение каскадных сбоев), `acc-check-fallback-strategy` (аудит fallback/graceful degradation)
- Навыки аудита DDD (+3): `acc-check-aggregate-consistency` (аудит правил агрегата), `acc-check-cqrs-alignment` (соответствие CQRS/ES), `acc-check-context-communication` (паттерны Context Map)
- Навыки аудита документации (+3): `acc-check-doc-links` (валидация ссылок), `acc-check-doc-examples` (проверка примеров кода), `acc-check-version-consistency` (аудит синхронизации версий)
- Навыки security-ревьюера (+6): `acc-check-insecure-design` (A04:2021), `acc-check-logging-failures` (A09:2021), `acc-check-secure-headers` (CSP/HSTS/X-Frame), `acc-check-cors-security` (неправильная конфигурация CORS), `acc-check-mass-assignment` (mass assignment), `acc-check-type-juggling` (PHP type juggling)
- Навыки performance-ревьюера (+3): `acc-check-index-usage` (отсутствующие индексы БД), `acc-check-async-patterns` (синхронные операции, которые должны быть асинхронными), `acc-check-file-io` (паттерны file I/O)

### Changed

#### Система аудита
- Все 11 команд аудита обновлены до `model: opus` (было sonnet для psr, test, security, performance)
- Унифицированная система серьезности 🔴🟠🟡🟢 во всех 11 командах аудита (было 5 разных наборов иконок)
- Все 11 команд аудита теперь поддерживают `level:quick`, `level:standard`, `level:deep` через мета-инструкции
- Все 11 команд аудита теперь имеют таблицы Meta-Instructions Guide (было 2/11)
- Все 11 команд аудита теперь имеют Pre-flight проверки (было 8/11)
- `acc-audit-psr` переписана: 89 → 220 строк с Pre-flight Check, Audit Levels, Severity, Meta-Instructions Guide, полным шаблоном Expected Output
- `acc-audit-test` переписана: 137 → 230 строк с Pre-flight Check, Audit Levels, Severity, Meta-Instructions Guide, полным шаблоном Expected Output
- Команды `acc-audit-psr` и `acc-audit-test` расширили `allowed-tools` с `Task` до `Read, Grep, Glob, Bash, Task`

#### Агенты
- `acc-behavioral-auditor` разделён: CQRS/ES/EDA → новый `acc-cqrs-auditor` (8 навыков), GoF behavioral остаётся (11 навыков, было 17+458 строк)
- `acc-docker-production-agent` уменьшен: 410 → ~200 строк, встроенные шаблоны извлечены в референсы навыков
- `acc-find-sql-injection` объединён с `acc-check-sql-injection` (>70% совпадения содержимого), `acc-bug-hunter` обновлён
- Координаторы `acc-pattern-auditor` и `acc-architecture-auditor` обновили таблицы делегирования для разделения CQRS
- `acc-creational-auditor` расширен: 3 → 6 навыков, добавлены фазы Abstract Factory, антипаттерна Singleton, Prototype
- `acc-stability-auditor` расширен: 5 → 8 навыков, добавлены фазы Timeout, Cascading Failures, Fallback
- `acc-ddd-auditor` расширен: 5 → 8 навыков, добавлены фазы Aggregate Consistency, CQRS Alignment, Context Communication
- `acc-documentation-auditor` расширен: 3 → 6 навыков, добавлены валидация ссылок, проверка примеров, согласованность версий
- `acc-security-reviewer` расширен: 14 → 20 навыков, добавлены OWASP A04 Insecure Design, A09 Logging Failures, Secure Headers, CORS, Mass Assignment, Type Juggling
- `acc-performance-reviewer` расширен: 10 → 13 навыков, добавлены Index Usage, Async Patterns, File I/O
- Координатор `acc-pattern-auditor` обновил таблицу делегирования (stability 5→8, creational 3→6)

#### Отслеживание прогресса
- 5 агентов-специалистов (`acc-security-reviewer`, `acc-performance-reviewer`, `acc-psr-auditor`, `acc-test-auditor`, `acc-documentation-auditor`) обновлены с отслеживанием прогресса TaskCreate/TaskUpdate (3 фазы: Scan → Analyze → Report)
- 6 суб-аудиторов (`acc-behavioral-auditor`, `acc-cqrs-auditor`, `acc-creational-auditor`, `acc-gof-structural-auditor`, `acc-structural-auditor`, `acc-integration-auditor`, `acc-stability-auditor`) обновлены с отслеживанием прогресса TaskCreate/TaskUpdate

#### Навыки и CLAUDE.md
- 10 навыков-анализаторов расширены руководством "When This Is Acceptable" по ложным срабатываниям: `acc-check-method-length`, `acc-check-class-length`, `acc-detect-n-plus-one`, `acc-analyze-solid-violations`, `acc-detect-code-smells`, `acc-check-input-validation`, `acc-check-sql-injection`, `acc-detect-memory-issues`, `acc-check-caching-strategy`, `acc-check-output-encoding`
- `CLAUDE.md` сокращён с 147 до ~80 строк — секции о создании компонентов, версионировании и устранении неполадок извлечены в условные правила
- Обновлено количество компонентов: 26 команд, 57 агентов, 242 навыка
---

## [2.9.0] - 2026-02-08

### Added
- Команда `/acc-explain` — объяснение кода с 5 режимами (quick, deep, onboarding, business, qa), принимает файлы, директории, HTTP-маршруты, консольные команды
- Агенты Explain (4): explain-coordinator, codebase-navigator, business-logic-analyst, data-flow-analyst
- Навыки Explain (12): сканирование кодовой базы, разрешение точек входа, обнаружение архитектуры, извлечение бизнес-правил/процессов/домена, конечные автоматы, трассировка жизненного цикла запроса, преобразование данных, асинхронные потоки, шаблоны вывода
- Структурные паттерны GoF (6): Adapter, Facade, Proxy, Composite, Bridge, Flyweight — аудитор + генератор, 6 навыков с шаблонами/примерами
- Поведенческие паттерны GoF (4): Template Method, Visitor, Iterator, Memento — 4 навыка с шаблонами/примерами

### Changed
- `acc-behavioral-generator/auditor` расширены 4 новыми поведенческими паттернами GoF
- Координаторы `acc-pattern-generator/auditor` теперь делегируют 5 суб-агентам (добавлен `acc-gof-structural-*`)
- `/acc-generate-patterns` поддерживает 26 паттернов (было 16), `/acc-audit-patterns` аудирует категорию структурных GoF
- `docs/mcp.md` расширен 6 конфигурациями MCP-серверов: Redis, RabbitMQ, Elasticsearch, Kafka, GitHub, Docker Hub
- Обновлено количество компонентов: 26 команд, 56 агентов, 222 навыка

---

## [2.8.0] - 2026-02-07

### Added
- Docker Expert System для PHP (2 команды + 1 координатор + 7 агентов + 42 навыка)
- Расширен `acc-claude-code-knowledge` с ~45% до ~95% покрытия с 6 референсными файлами:
  - `hooks-reference.md` — все 12 событий хуков, 3 типа, матчеры, I/O, коды выхода
  - `skills-advanced.md` — context:fork, agent, hooks, model, управление вызовами
  - `subagents-advanced.md` — memory, hooks, disallowedTools, background, resume
  - `memory-and-rules.md` — иерархия CLAUDE.md, rules/, @imports, paths frontmatter
  - `plugins-reference.md` — структура плагина, манифест, marketplace, миграция
  - `settings-and-permissions.md` — полная схема settings, sandbox, разрешения, переменные окружения
- Новые секции SKILL.md: Memory, Plugins, Permissions, MCP, Settings, Decision Framework, Context Costs
- Задокументированы новые поля агентов: `disallowedTools`, `hooks`, `memory`, `permissionMode` (6 режимов)
- Задокументированы новые поля навыков: `context`, `agent`, `hooks`, `model`, инъекция `!`command``
- Создание плагинов и правил в `/acc-generate-claude-component`
- Комплексный аудит memory/rules, плагинов и хуков в `/acc-audit-claude-components`

### Changed
- Агент `acc-claude-code-expert` обновлён знаниями Memory, Plugins, Permissions, Rules
- `/acc-generate-claude-component` расширена с 4 до 6 типов компонентов (+ rule, plugin)
- `/acc-audit-claude-components` улучшена критериями качества memory/rules, плагинов, хуков, разрешений
- Команда `/acc-audit-docker` - аудит конфигурации Docker (Dockerfile, Compose, безопасность, производительность)
- Команда `/acc-generate-docker` - генерация Docker-компонентов (dockerfile, compose, nginx, entrypoint, makefile, env, healthcheck, full)
- Агент `acc-docker-coordinator` - оркестрирует операции аудита и генерации Docker
- Docker-специалисты (7): architect, image-builder, compose, performance, security, debugger, production
- Навыки знаний Docker (12): core, multistage, base-images, php-extensions, compose, networking, security, buildkit, production, troubleshooting, orchestration, scanning
- Навыки анализа Docker (12): build-errors, runtime-errors, image-size, security, secrets, user-permissions, compose-config, production-readiness, antipatterns, layer-efficiency, php-config, healthcheck
- Навыки создания Docker (12): dockerfile-production, dockerfile-dev, dockerignore, compose-dev, compose-production, php-config, healthcheck, entrypoint, nginx-config, makefile, env-template, supervisor-config
- Навыки оптимизации Docker (6): build-time, image-size, php-fpm, compose-resources, opcache, startup
- Обновлено количество компонентов: 25 команд, 50 агентов, 200 навыков

### Changed
- Переименовано `/acc-write-test` → `/acc-generate-test` для согласованного глагола `generate-` во всех командах генерации
- Переименовано `/acc-write-documentation` → `/acc-generate-documentation`
- Переименовано `/acc-write-claude-component` → `/acc-generate-claude-component`

---

## [2.7.0] - 2026-02-06

### Added
- Команда `/acc-generate-ddd` - прямая генерация DDD-компонентов (13 компонентов)
- Команда `/acc-generate-psr` - прямая генерация PSR-компонентов (11 PSR-реализаций)
- Команда `/acc-generate-patterns` - прямая генерация паттернов проектирования (16 паттернов)
- Команда `/acc-audit-security` - отдельный аудит безопасности (OWASP Top 10)
- Команда `/acc-audit-performance` - отдельный аудит производительности
- Команда `/acc-audit-patterns` - аудит паттернов проектирования
- Команда `/acc-refactor` - управляемый рабочий процесс рефакторинга
- Команды CI/CD (4): `/acc-ci-setup`, `/acc-ci-fix`, `/acc-ci-optimize`, `/acc-audit-ci`
- Агенты CI/CD (10): ci-coordinator, pipeline-architect, ci-debugger, ci-fixer, pipeline-optimizer, ci-security-agent, docker-agent, deployment-agent, static-analysis-agent, test-pipeline-agent
- Навыки CI/CD (18): знания (3), генераторы конфигураций (6), docker (2), deployment (2), анализаторы (4), генератор исправлений (1)
- Навык `acc-task-progress-knowledge` - руководство по паттерну TaskCreate для отслеживания прогресса координатора
- Отслеживание прогресса (TaskCreate/TaskUpdate) в 7 агентах-координаторах для видимости пользователя
- Руководство TaskCreate в проектном CLAUDE.md и глобальном ~/.claude/CLAUDE.md
- Проверка отслеживания прогресса координатора в `/acc-audit-claude-components`
- Руководство по созданию координаторов в `/acc-generate-claude-component`
- Обновлено количество компонентов: 23 команды, 42 агента, 158 навыков

---

## [2.6.0] - 2026-02-05

### Added
- CLI-инструмент `bin/acc` для управления Claude-компонентами (`acc upgrade`)
- Команда `/acc-bug-fix` - автоматическая диагностика багов, генерация исправлений и тестирование
- Агент `acc-bug-fix-coordinator` - оркестрирует процесс диагностика → исправление → тест
- Агент `acc-bug-fixer` - генерирует безопасные, минимальные исправления багов (11 навыков)
- Навыки исправления багов (5): знания, поиск первопричины, анализатор воздействия, генератор исправлений, предотвращение регрессий
- Навыки безопасности (5): SSRF, command injection, deserialization, XXE, path traversal (OWASP 10/10)
- Навыки производительности (2): connection-pool, serialization

### Changed
- `acc-security-reviewer`: 9 → 14 навыков (полный OWASP Top 10)
- `acc-performance-reviewer`: 8 → 10 навыков

## [2.5.0] - 2026-02-04

### Added
- Команда `/acc-code-review` - многоуровневое ревью кода с анализом git diff
- Агенты ревью (6): code-review-coordinator, bug-hunter, security-reviewer, performance-reviewer, readability-reviewer, testability-reviewer
- Навыки обнаружения багов (9): logic-errors, null-pointer, boundary, race-conditions, resource-leaks, exception, type, sql-injection, infinite-loops
- Навыки ревью безопасности (9): input-validation, output-encoding, authentication, authorization, sensitive-data, csrf, crypto, dependencies, sql-injection
- Навыки производительности (8): n-plus-one, query-efficiency, memory, caching, loops, lazy-loading, batch-processing, complexity
- Навыки читаемости (9): naming, code-style, method-length, class-length, nesting, comments, magic-values, consistency, simplification
- Навыки тестируемости (5): dependency-injection, pure-functions, side-effects, test-quality, testability-improvements

## [2.4.0] - 2026-02-03

### Added
- `/acc-generate-test` - генерация тестов для PHP-файла/папки
- `/acc-audit-test` - аудит качества тестов
- `/acc-generate-documentation` - генерация документации
- `/acc-audit-documentation` - аудит качества документации
- Агенты-аудиторы (6): structural, behavioral, integration, stability, creational, psr
- Агенты-генераторы (4): stability, behavioral, creational, integration
- Агенты тестирования (2): test-auditor, test-generator
- Агенты документирования (3): documentation-writer, documentation-auditor, diagram-designer
- Навыки знаний (4): testing, documentation, diagram, documentation-qa
- Навыки-анализаторы (8): test-coverage, test-smells, code-smells, bounded-contexts, immutability, leaky-abstractions, encapsulation, coupling-cohesion
- Навыки-генераторы (5): unit-test, integration-test, test-builder, mock-repository, test-double
- Навыки-шаблоны (9): readme, architecture-doc, adr, api-doc, getting-started, troubleshooting, code-examples, mermaid, changelog
- Хуки (10): auto-format, strict-types, protect-vendor, syntax-check, auto-tests, final-domain, file-size, no-direct-commits, protect-migrations, test-without-source
- Поддержка мета-инструкций через разделитель `--` для всех команд

### Changed
- Декомпозиция `acc-architecture-auditor` в паттерн координатора (делегирует 3 аудиторам)
- Рефакторинг `acc-pattern-auditor` и `acc-pattern-generator` в паттерны координаторов
- Переименовано `/acc-claude-code` → `/acc-generate-claude-component`

## [2.3.0] - 2026-02-02

### Added
- Команда `/acc-audit-psr` - аудит соответствия PSR
- Агент `acc-psr-generator` (11 навыков)
- Навыки знаний (6): SOLID, GRASP, PSR coding style, PSR autoloading, PSR overview, ADR
- Навык-анализатор: SOLID violations
- Навыки-генераторы PSR (13): PSR-3, 6, 7, 11, 13, 14, 15, 16, 17, 18, 20, action, responder
- Утилитарные навыки (2): DI container, mediator

## [2.2.0] - 2026-01-31

### Added
- Команда `/acc-audit-claude-code`
- Агенты (3): architecture-generator, pattern-auditor, pattern-generator
- Навыки знаний (3): outbox-pattern, saga-pattern, stability-patterns
- Навыки-генераторы (20): dto, specification, factory, domain-service, outbox, saga, circuit-breaker, retry, rate-limiter, bulkhead, strategy, state, decorator, chain-of-responsibility, builder, null-object, object-pool, anti-corruption-layer, read-model, policy

### Changed
- Рефакторинг 22 навыков для использования структуры папок `references/`

## [2.1.0] - 2026-01-30

### Added
- Команда `/acc-audit-architecture` - многопаттерновый аудит архитектуры
- Команда `/acc-audit-ddd` - анализ соответствия DDD
- Агенты (3): architecture-auditor, ddd-auditor, ddd-generator
- Навыки знаний (7): DDD, CQRS, Clean Architecture, Hexagonal, Layered, Event Sourcing, EDA
- Навыки-генераторы (8): value-object, entity, aggregate, domain-event, repository, command, query, use-case

## [2.0.0] - 2026-01-29

### Added
- Composer-плагин для автоматического копирования Claude Code-компонентов
- Команда `/acc-generate-claude-component` - интерактивный мастер
- Команда `/acc-commit` - автогенерация commit-сообщения
- Агент `acc-claude-code-expert`
- Навык `acc-claude-code-knowledge`

## [1.0.0] - 2026-01-28

### Added
- Первоначальный релиз
- Структура проекта и настройка Composer-пакета

[Unreleased]: https://github.com/backvista/awesome-claude-code/compare/v2.10.0...HEAD
[2.10.0]: https://github.com/backvista/awesome-claude-code/compare/v2.9.0...v2.10.0
[2.9.0]: https://github.com/backvista/awesome-claude-code/compare/v2.8.0...v2.9.0
[2.8.0]: https://github.com/backvista/awesome-claude-code/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/backvista/awesome-claude-code/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/backvista/awesome-claude-code/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/backvista/awesome-claude-code/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/backvista/awesome-claude-code/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/backvista/awesome-claude-code/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/backvista/awesome-claude-code/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/backvista/awesome-claude-code/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/backvista/awesome-claude-code/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/backvista/awesome-claude-code/releases/tag/v1.0.0
