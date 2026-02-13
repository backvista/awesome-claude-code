# Агенты

Субагенты для специализированных задач. Агенты -- это автономные работники, выполняющие сложные многоступенчатые операции.

## Обзор

### Координаторы (0-3 навыка, делегируют через Task tool)

| Агент | Назначение | Вызывается из |
|-------|---------|------------|
| `acc-architecture-auditor` | Координатор аудита архитектуры | `/acc-audit-architecture` |
| `acc-pattern-auditor` | Координатор аудита паттернов проектирования | `/acc-audit-patterns`, `acc-architecture-auditor` (Task) |
| `acc-pattern-generator` | Координатор генерации паттернов проектирования | `/acc-generate-patterns`, `acc-architecture-auditor` (Task) |
| `acc-code-review-coordinator` | Координатор code review (3 уровня) | `/acc-code-review` |
| `acc-bug-fix-coordinator` | Координатор исправления багов (диагностика → фикс → тест) | `/acc-bug-fix` |
| `acc-refactor-coordinator` | Координатор рефакторинга (анализ → приоритизация → исправление) | `/acc-refactor` |
| `acc-ci-coordinator` | Координатор CI/CD (настройка, отладка, оптимизация, аудит) | `/acc-ci-*`, `/acc-audit-ci` |
| `acc-docker-coordinator` | Координатор экспертной системы Docker (аудит, генерация) | `/acc-audit-docker`, `/acc-generate-docker` |
| `acc-explain-coordinator` | Координатор объяснения кода (5 режимов) | `/acc-explain` |

### Аудиторы (3-12 навыков)

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-structural-auditor` | Анализ структурных паттернов | 13 | `acc-architecture-auditor` (Task) |
| `acc-behavioral-auditor` | Анализ поведенческих паттернов GoF | 11 | `acc-pattern-auditor` (Task) |
| `acc-cqrs-auditor` | Анализ паттернов CQRS/ES/EDA | 8 | `acc-architecture-auditor`, `acc-pattern-auditor` (Task) |
| `acc-gof-structural-auditor` | Анализ структурных паттернов GoF | 7 | `acc-pattern-auditor` (Task) |
| `acc-integration-auditor` | Анализ интеграционных паттернов | 13 | `acc-architecture-auditor`, `acc-pattern-auditor` (Task) |
| `acc-stability-auditor` | Анализ паттернов стабильности | 9 | `acc-pattern-auditor` (Task) |
| `acc-creational-auditor` | Анализ порождающих паттернов | 7 | `acc-pattern-auditor` (Task) |
| `acc-ddd-auditor` | Анализ соответствия DDD | 8 | `/acc-audit-ddd` |
| `acc-psr-auditor` | Анализ соответствия PSR | 3 | `/acc-audit-psr` |
| `acc-documentation-auditor` | Аудит качества документации | 6 | `/acc-audit-documentation` |
| `acc-test-auditor` | Анализ качества тестов | 3 | `/acc-audit-test` |

### Рецензенты (7-20 навыков, специалисты по code review)

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-bug-hunter` | Специалист по обнаружению багов | 9 | `acc-code-review-coordinator`, `acc-bug-fix-coordinator` (Task) |
| `acc-security-reviewer` | Специалист по ревью безопасности | 21 | `/acc-audit-security`, `acc-code-review-coordinator` (Task) |
| `acc-performance-reviewer` | Специалист по ревью производительности | 13 | `/acc-audit-performance`, `acc-code-review-coordinator` (Task) |
| `acc-readability-reviewer` | Специалист по ревью читаемости | 9 | `acc-code-review-coordinator`, `acc-refactor-coordinator` (Task) |
| `acc-testability-reviewer` | Специалист по ревью тестируемости | 7 | `acc-code-review-coordinator`, `acc-refactor-coordinator` (Task) |

### Специалисты по исправлению багов

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-bug-fixer` | Генератор исправлений багов | 11 | `acc-bug-fix-coordinator` (Task) |

### Генераторы (3-14 навыков)

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-architecture-generator` | Генерация архитектурных компонентов | 7 | `acc-architecture-auditor` (Task) |
| `acc-ddd-generator` | Генерация DDD-компонентов | 14 | `acc-ddd-auditor` (Task) |
| `acc-stability-generator` | Генерация паттернов стабильности | 5 | `acc-pattern-generator` (Task) |
| `acc-behavioral-generator` | Генерация поведенческих паттернов | 10 | `acc-pattern-generator` (Task) |
| `acc-gof-structural-generator` | Генерация структурных паттернов GoF | 6 | `acc-pattern-generator` (Task) |
| `acc-creational-generator` | Генерация порождающих паттернов | 3 | `acc-pattern-generator` (Task) |
| `acc-integration-generator` | Генерация интеграционных паттернов | 7 | `acc-pattern-generator` (Task) |
| `acc-psr-generator` | Генерация PSR-реализаций | 14 | `/acc-generate-psr`, `acc-psr-auditor` (Skill) |
| `acc-documentation-writer` | Генерация документации | 9 | `/acc-generate-documentation` |
| `acc-diagram-designer` | Создание Mermaid-диаграмм | 2 | `acc-documentation-writer` (Task) |
| `acc-test-generator` | Генерация PHP-тестов | 6 | `/acc-generate-test` |

### Специалисты CI/CD

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-pipeline-architect` | Проектирование и структура пайплайна | 4 | `acc-ci-coordinator` (Task) |
| `acc-static-analysis-agent` | Конфигурация PHPStan/Psalm/DEPTRAC | 9 | `acc-ci-coordinator` (Task) |
| `acc-test-pipeline-agent` | Настройка PHPUnit/покрытия | 5 | `acc-ci-coordinator` (Task) |
| `acc-ci-debugger` | Анализ логов и диагностика | 3 | `acc-ci-coordinator` (Task) |
| `acc-ci-fixer` | Генерация и применение исправлений | 6 | `acc-ci-coordinator`, `/acc-ci-fix` (Task) |
| `acc-pipeline-optimizer` | Кэширование и параллелизация | 7 | `acc-ci-coordinator` (Task) |
| `acc-ci-security-agent` | Секреты и сканирование зависимостей | 4 | `acc-ci-coordinator` (Task) |
| `acc-docker-agent` | Dockerfile и оптимизация слоев | 3 | `acc-ci-coordinator` (Task) |
| `acc-deployment-agent` | Конфигурация деплоя, blue-green, canary | 6 | `acc-ci-coordinator` (Task) |

### Специалисты Docker

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-docker-architect-agent` | Архитектура Dockerfile, multi-stage сборки | 5 | `acc-docker-coordinator` (Task) |
| `acc-docker-image-builder` | Базовые образы, PHP-расширения | 5 | `acc-docker-coordinator` (Task) |
| `acc-docker-compose-agent` | Конфигурация Compose, сервисы | 6 | `acc-docker-coordinator` (Task) |
| `acc-docker-performance-agent` | Оптимизация сборки/рантайма | 6 | `acc-docker-coordinator` (Task) |
| `acc-docker-security-agent` | Аудит безопасности, усиление защиты | 6 | `acc-docker-coordinator` (Task) |
| `acc-docker-debugger-agent` | Диагностика ошибок, устранение неполадок | 4 | `acc-docker-coordinator` (Task) |
| `acc-docker-production-agent` | Готовность к production, health checks | 6 | `acc-docker-coordinator` (Task) |

### Специалисты по объяснению кода

| Агент | Назначение | Навыки | Вызывается из |
|-------|---------|--------|------------|
| `acc-codebase-navigator` | Сканирование структуры кодовой базы и определение паттернов | 3 | `acc-explain-coordinator` (Task) |
| `acc-business-logic-analyst` | Извлечение бизнес-правил, процессов, доменных концепций | 4 | `acc-explain-coordinator` (Task) |
| `acc-data-flow-analyst` | Трассировка жизненного цикла запроса, трансформации данных, асинхронных потоков | 3 | `acc-explain-coordinator` (Task) |

### Эксперты

| Агент | Назначение | Вызывается из |
|-------|---------|------------|
| `acc-claude-code-expert` | Создание компонентов Claude Code | `/acc-generate-claude-component` |

## Как работают агенты

1. **Вызов**: Команды вызывают агентов через Task tool или прямую ссылку
2. **Загрузка навыков**: Агент загружает навыки из frontmatter `skills:`
3. **Выполнение**: Агент выполняет многоступенчатый анализ или генерацию
4. **Делегирование**: Агент может делегировать подзадачи другим агентам через Task tool

## Отслеживание прогресса (Координаторы)

Координаторы используют TaskCreate/TaskUpdate для видимости пользователю:

```
1. TaskCreate (все фазы заранее)
   ├── Фаза 1: "Analyze changes" — Анализ изменений...
   ├── Фаза 2: "Run reviewers" — Запуск рецензентов...
   └── Фаза 3: "Generate report" — Генерация отчета...

2. Выполнение с обновлениями статуса:
   ├── TaskUpdate(taskId, status: in_progress)
   ├── ... выполнение фазы ...
   └── TaskUpdate(taskId, status: completed)
```

**Координаторы с отслеживанием прогресса:**
- `acc-code-review-coordinator` -- 3 фазы
- `acc-bug-fix-coordinator` -- 3 фазы
- `acc-refactor-coordinator` -- 3 фазы
- `acc-architecture-auditor` -- 4 фазы
- `acc-ci-coordinator` -- 3 фазы
- `acc-ddd-auditor` -- 3 фазы
- `acc-pattern-auditor` -- 4 фазы
- `acc-explain-coordinator` -- 4 фазы
- `acc-docker-coordinator` -- 3 фазы

**Специализированные аудиторы с отслеживанием прогресса:**
- `acc-security-reviewer` -- 3 фазы (Сканирование → Анализ → Отчет)
- `acc-performance-reviewer` -- 3 фазы (Сканирование → Анализ → Отчет)
- `acc-psr-auditor` -- 3 фазы (Сканирование → Анализ → Отчет)
- `acc-test-auditor` -- 3 фазы (Сканирование → Анализ → Отчет)
- `acc-documentation-auditor` -- 3 фазы (Сканирование → Анализ → Отчет)

См. навык `acc-task-progress-knowledge` для руководства.

---

## `acc-claude-code-expert`

**Путь:** `agents/acc-claude-code-expert.md`

Эксперт по созданию команд, агентов и навыков Claude Code.

**Конфигурация:**
```yaml
name: acc-claude-code-expert
tools: Read, Write, Edit, Bash, Grep, Glob
model: opus
skills: acc-claude-code-knowledge
```

---

## `acc-architecture-auditor`

**Путь:** `agents/acc-architecture-auditor.md`

Координатор аудита архитектуры. Оркестрирует три специализированных аудитора для комплексных проверок.

**Конфигурация:**
```yaml
name: acc-architecture-auditor
tools: Read, Grep, Glob, Task
model: opus
# Без навыков — делегирует специализированным аудиторам
```

**Рабочий процесс:**
1. Обнаружение паттернов (Glob/Grep для структурных, поведенческих, интеграционных паттернов)
2. Параллельное делегирование Task 3 аудиторам
3. Кросс-паттерный анализ (выявление конфликтов между паттернами)
4. Агрегация отчета (единый markdown-отчет)

---

## `acc-structural-auditor`

**Путь:** `agents/acc-structural-auditor.md`

Аудитор структурной архитектуры для DDD, Clean Architecture, Hexagonal, Layered, SOLID, GRASP.

**Конфигурация:**
```yaml
name: acc-structural-auditor
tools: Read, Grep, Glob
model: sonnet
skills: acc-ddd-knowledge, acc-clean-arch-knowledge, acc-hexagonal-knowledge,
        acc-layer-arch-knowledge, acc-solid-knowledge, acc-grasp-knowledge,
        acc-analyze-solid-violations, acc-detect-code-smells, acc-check-bounded-contexts,
        acc-check-immutability, acc-check-leaky-abstractions, acc-check-encapsulation
```

**Навыки:** 12 (6 знания + 6 анализаторов)

---

## `acc-behavioral-auditor`

**Путь:** `agents/acc-behavioral-auditor.md`

Аудитор поведенческих паттернов для CQRS, Event Sourcing, EDA и GoF поведенческих паттернов (Strategy, State, Chain of Responsibility, Decorator, Null Object, Template Method, Visitor, Iterator, Memento).

**Конфигурация:**
```yaml
name: acc-behavioral-auditor
tools: Read, Grep, Glob
model: sonnet
skills: acc-cqrs-knowledge, acc-event-sourcing-knowledge, acc-eda-knowledge,
        acc-create-command, acc-create-query, acc-create-domain-event,
        acc-create-read-model, acc-create-strategy, acc-create-state,
        acc-create-chain-of-responsibility, acc-create-decorator,
        acc-create-null-object, acc-check-immutability,
        acc-create-template-method, acc-create-visitor,
        acc-create-iterator, acc-create-memento
```

**Навыки:** 17 (3 знания + 14 генераторов/анализаторов)

---

## `acc-integration-auditor`

**Путь:** `agents/acc-integration-auditor.md`

Аудитор интеграционных паттернов для Outbox, Saga, Stability и ADR.

**Конфигурация:**
```yaml
name: acc-integration-auditor
tools: Read, Grep, Glob
model: sonnet
skills: acc-outbox-pattern-knowledge, acc-saga-pattern-knowledge,
        acc-stability-patterns-knowledge, acc-adr-knowledge,
        acc-create-outbox-pattern, acc-create-saga-pattern,
        acc-create-circuit-breaker, acc-create-retry-pattern,
        acc-create-rate-limiter, acc-create-bulkhead,
        acc-create-action, acc-create-responder
```

**Навыки:** 12 (4 знания + 8 генераторов)

---

## `acc-stability-auditor`

**Путь:** `agents/acc-stability-auditor.md`

Аудитор паттернов стабильности для Circuit Breaker, Retry, Rate Limiter и Bulkhead.

**Конфигурация:**
```yaml
name: acc-stability-auditor
tools: Read, Grep, Glob
model: sonnet
skills: acc-stability-patterns-knowledge, acc-create-circuit-breaker,
        acc-create-retry-pattern, acc-create-rate-limiter, acc-create-bulkhead
```

**Навыки:** 5 (1 знания + 4 генератора)

---

## `acc-gof-structural-auditor`

**Путь:** `agents/acc-gof-structural-auditor.md`

Аудитор структурных паттернов GoF для Adapter, Facade, Proxy, Composite, Bridge и Flyweight.

**Конфигурация:**
```yaml
name: acc-gof-structural-auditor
tools: Read, Grep, Glob
model: sonnet
skills: acc-create-adapter, acc-create-facade, acc-create-proxy,
        acc-create-composite, acc-create-bridge, acc-create-flyweight
```

**Навыки:** 6 (генераторы)

---

## `acc-gof-structural-generator`

**Путь:** `agents/acc-gof-structural-generator.md`

Генерирует структурные паттерны GoF (Adapter, Facade, Proxy, Composite, Bridge, Flyweight).

**Конфигурация:**
```yaml
name: acc-gof-structural-generator
tools: Read, Write, Glob, Grep, Edit
model: sonnet
skills: acc-create-adapter, acc-create-facade, acc-create-proxy,
        acc-create-composite, acc-create-bridge, acc-create-flyweight
```

**Навыки:** 6

---

## `acc-creational-auditor`

**Путь:** `agents/acc-creational-auditor.md`

Аудитор порождающих паттернов для Builder, Object Pool и Factory.

**Конфигурация:**
```yaml
name: acc-creational-auditor
tools: Read, Grep, Glob
model: sonnet
skills: acc-create-builder, acc-create-object-pool, acc-create-factory
```

**Навыки:** 3 (только генераторы)

---

## `acc-ddd-auditor`

**Путь:** `agents/acc-ddd-auditor.md`

Специализированный аудитор соответствия DDD.

**Конфигурация:**
```yaml
name: acc-ddd-auditor
tools: Read, Grep, Glob, Bash, Task
model: opus
skills: acc-ddd-knowledge, acc-solid-knowledge, acc-grasp-knowledge
```

**Навыки:** 3 (только знания, генерация делегируется `acc-ddd-generator` через Task)

---

## `acc-ddd-generator`

**Путь:** `agents/acc-ddd-generator.md`

Создает DDD и архитектурные компоненты.

**Конфигурация:**
```yaml
name: acc-ddd-generator
tools: Read, Write, Glob, Grep
model: opus
skills: acc-ddd-knowledge, acc-create-value-object, acc-create-entity,
        acc-create-aggregate, acc-create-domain-event, acc-create-repository,
        acc-create-command, acc-create-query, acc-create-use-case,
        acc-create-domain-service, acc-create-factory, acc-create-specification,
        acc-create-dto, acc-create-anti-corruption-layer
```

---

## `acc-pattern-auditor`

**Путь:** `agents/acc-pattern-auditor.md`

Координатор аудита паттернов проектирования. Оркестрирует аудиторы стабильности, поведенческих, порождающих и интеграционных паттернов.

**Конфигурация:**
```yaml
name: acc-pattern-auditor
tools: Read, Grep, Glob, Task
model: opus
skills: acc-solid-knowledge, acc-grasp-knowledge
```

**Навыки:** 2 (только знания, делегирует 5 специализированным аудиторам через Task)

**Делегирование:**
- `acc-stability-auditor` -- Circuit Breaker, Retry, Rate Limiter, Bulkhead
- `acc-behavioral-auditor` -- Strategy, State, Chain, Decorator, Null Object, Template Method, Visitor, Iterator, Memento
- `acc-gof-structural-auditor` -- Adapter, Facade, Proxy, Composite, Bridge, Flyweight
- `acc-creational-auditor` -- Builder, Object Pool, Factory
- `acc-integration-auditor` -- Outbox, Saga, ADR

---

## `acc-pattern-generator`

**Путь:** `agents/acc-pattern-generator.md`

Координатор генерации паттернов проектирования. Оркестрирует генераторы стабильности, поведенческих, структурных GoF, порождающих и интеграционных паттернов.

**Конфигурация:**
```yaml
name: acc-pattern-generator
tools: Read, Write, Glob, Grep, Edit, Task
model: opus
skills: acc-adr-knowledge
```

**Навыки:** 1 (делегирует 5 специализированным генераторам через Task)

**Делегирование:**
- `acc-stability-generator` -- Circuit Breaker, Retry, Rate Limiter, Bulkhead
- `acc-behavioral-generator` -- Strategy, State, Chain, Decorator, Null Object, Template Method, Visitor, Iterator, Memento
- `acc-gof-structural-generator` -- Adapter, Facade, Proxy, Composite, Bridge, Flyweight
- `acc-creational-generator` -- Builder, Object Pool, Factory
- `acc-integration-generator` -- Outbox, Saga, Action, Responder

---

## `acc-stability-generator`

**Путь:** `agents/acc-stability-generator.md`

Генерирует паттерны стабильности (Circuit Breaker, Retry, Rate Limiter, Bulkhead).

**Конфигурация:**
```yaml
name: acc-stability-generator
tools: Read, Write, Glob, Grep, Edit
model: sonnet
skills: acc-stability-patterns-knowledge, acc-create-circuit-breaker,
        acc-create-retry-pattern, acc-create-rate-limiter, acc-create-bulkhead
```

**Навыки:** 5

---

## `acc-behavioral-generator`

**Путь:** `agents/acc-behavioral-generator.md`

Генерирует поведенческие паттерны (Strategy, State, Chain of Responsibility, Decorator, Null Object, Template Method, Visitor, Iterator, Memento).

**Конфигурация:**
```yaml
name: acc-behavioral-generator
tools: Read, Write, Glob, Grep, Edit
model: sonnet
skills: acc-create-strategy, acc-create-state, acc-create-chain-of-responsibility,
        acc-create-decorator, acc-create-null-object, acc-create-policy,
        acc-create-template-method, acc-create-visitor,
        acc-create-iterator, acc-create-memento
```

**Навыки:** 10

---

## `acc-creational-generator`

**Путь:** `agents/acc-creational-generator.md`

Генерирует порождающие паттерны (Builder, Object Pool, Factory).

**Конфигурация:**
```yaml
name: acc-creational-generator
tools: Read, Write, Glob, Grep, Edit
model: sonnet
skills: acc-create-builder, acc-create-object-pool, acc-create-factory
```

**Навыки:** 3

---

## `acc-integration-generator`

**Путь:** `agents/acc-integration-generator.md`

Генерирует интеграционные паттерны (Outbox, Saga, Action, Responder).

**Конфигурация:**
```yaml
name: acc-integration-generator
tools: Read, Write, Glob, Grep, Edit
model: sonnet
skills: acc-outbox-pattern-knowledge, acc-saga-pattern-knowledge, acc-adr-knowledge,
        acc-create-outbox-pattern, acc-create-saga-pattern,
        acc-create-action, acc-create-responder
```

**Навыки:** 7

---

## `acc-architecture-generator`

**Путь:** `agents/acc-architecture-generator.md`

Мета-генератор, координирующий генерацию DDD и интеграционных паттернов для bounded contexts и сложных структур.

**Конфигурация:**
```yaml
name: acc-architecture-generator
tools: Read, Write, Glob, Grep, Edit, Task
model: opus
skills: acc-ddd-knowledge, acc-cqrs-knowledge, acc-clean-arch-knowledge,
        acc-eda-knowledge, acc-outbox-pattern-knowledge, acc-saga-pattern-knowledge,
        acc-stability-patterns-knowledge
```

**Возможности:**
- Прямая генерация: Value Objects, Entities, Aggregates, Commands, Queries, DTOs
- Делегированная генерация: Сложные DDD-структуры через `acc-ddd-generator`, Outbox/Saga через `acc-pattern-generator`
- Создание каркаса bounded context
- Настройка CQRS + Event Sourcing
- Полные вертикальные слайсы функциональности

---

## `acc-psr-auditor`

**Путь:** `agents/acc-psr-auditor.md`

Аудитор соответствия PSR для PHP-проектов. Анализирует стандарты кодирования и реализации интерфейсов.

**Конфигурация:**
```yaml
name: acc-psr-auditor
tools: Read, Bash, Grep, Glob
model: opus
skills: acc-psr-coding-style-knowledge, acc-psr-autoloading-knowledge, acc-psr-overview-knowledge
```

**Фазы анализа:**
1. Обнаружение структуры проекта
2. Анализ стиля кодирования PSR-1/PSR-12
3. Проверка автозагрузки PSR-4
4. Обнаружение PSR-интерфейсов
5. Генерация отчета с рекомендациями навыков

---

## `acc-psr-generator`

**Путь:** `agents/acc-psr-generator.md`

Создает PSR-совместимые PHP-компоненты.

**Конфигурация:**
```yaml
name: acc-psr-generator
tools: Read, Write, Glob, Grep, Edit
model: sonnet
skills: acc-psr-overview-knowledge, acc-psr-coding-style-knowledge, acc-psr-autoloading-knowledge,
        acc-create-psr3-logger, acc-create-psr6-cache, acc-create-psr7-http-message,
        acc-create-psr11-container, acc-create-psr13-link, acc-create-psr14-event-dispatcher,
        acc-create-psr15-middleware, acc-create-psr16-simple-cache, acc-create-psr17-http-factory,
        acc-create-psr18-http-client, acc-create-psr20-clock
```

---

## `acc-documentation-writer`

**Путь:** `agents/acc-documentation-writer.md`

Автор технической документации для PHP-проектов.

**Конфигурация:**
```yaml
name: acc-documentation-writer
tools: Read, Write, Edit, Glob, Grep
model: opus
skills: acc-documentation-knowledge, acc-readme-template, acc-architecture-doc-template,
        acc-adr-template, acc-api-doc-template, acc-getting-started-template,
        acc-troubleshooting-template, acc-code-examples-template, acc-changelog-template
```

---

## `acc-documentation-auditor`

**Путь:** `agents/acc-documentation-auditor.md`

Аудитор качества документации.

**Конфигурация:**
```yaml
name: acc-documentation-auditor
tools: Read, Glob, Grep, Bash
model: opus
skills: acc-documentation-qa-knowledge, acc-documentation-knowledge, acc-claude-code-knowledge
```

---

## `acc-diagram-designer`

**Путь:** `agents/acc-diagram-designer.md`

Дизайнер диаграмм для технической документации.

**Конфигурация:**
```yaml
name: acc-diagram-designer
tools: Read, Write, Edit, Glob, Grep
model: opus
skills: acc-diagram-knowledge, acc-mermaid-template
```

---

## `acc-test-auditor`

**Путь:** `agents/acc-test-auditor.md`

Аудитор качества тестов для PHP-проектов.

**Конфигурация:**
```yaml
name: acc-test-auditor
tools: Read, Bash, Grep, Glob
model: opus
skills: acc-testing-knowledge, acc-analyze-test-coverage, acc-detect-test-smells
```

**Фазы анализа:**
1. Обнаружение проекта (фреймворк, PHPUnit/Pest)
2. Анализ покрытия (непротестированные классы, методы, ветки)
3. Обнаружение тестовых антипаттернов (15 видов)
4. Метрики качества (именование, изоляция)
5. Генерация отчета с рекомендациями навыков

---

## `acc-test-generator`

**Путь:** `agents/acc-test-generator.md`

Генератор тестов для DDD/CQRS PHP-проектов.

**Конфигурация:**
```yaml
name: acc-test-generator
tools: Read, Write, Glob, Grep
model: opus
skills: acc-testing-knowledge, acc-create-unit-test, acc-create-integration-test,
        acc-create-test-builder, acc-create-mock-repository, acc-create-test-double
```

**Процесс генерации:**
1. Анализ исходного кода (тип класса, зависимости)
2. Классификация типа теста (модульный/интеграционный)
3. Подготовка инфраструктуры (builders, fakes)
4. Генерация тестов с использованием соответствующего навыка
5. Проверка соответствия правилам качества

---

---

## `acc-code-review-coordinator`

**Путь:** `agents/acc-code-review-coordinator.md`

Координатор code review, оркестрирующий многоуровневые ревью (low/medium/high) с анализом git diff.

**Конфигурация:**
```yaml
name: acc-code-review-coordinator
tools: Read, Grep, Glob, Bash, Task
model: opus
skills: acc-analyze-solid-violations, acc-detect-code-smells, acc-check-encapsulation
```

**Уровни ревью:**
- **LOW**: PSR + Тесты + Инкапсуляция + Code Smells
- **MEDIUM**: LOW + Баги + Читаемость + SOLID
- **HIGH**: MEDIUM + Безопасность + Производительность + Тестируемость + DDD + Архитектура

---

## `acc-bug-hunter`

**Путь:** `agents/acc-bug-hunter.md`

Специалист по обнаружению багов для code review.

**Конфигурация:**
```yaml
name: acc-bug-hunter
tools: Read, Grep, Glob
model: sonnet
skills: acc-find-logic-errors, acc-find-null-pointer-issues, acc-find-boundary-issues,
        acc-find-race-conditions, acc-find-resource-leaks, acc-find-exception-issues,
        acc-find-type-issues, acc-check-sql-injection, acc-find-infinite-loops
```

**Навыки:** 9 (обнаружение багов)

---

## `acc-security-reviewer`

**Путь:** `agents/acc-security-reviewer.md`

Специалист по ревью безопасности для уязвимостей OWASP Top 10.

**Конфигурация:**
```yaml
name: acc-security-reviewer
tools: Read, Grep, Glob
model: sonnet
skills: acc-check-input-validation, acc-check-output-encoding, acc-check-authentication,
        acc-check-authorization, acc-check-sensitive-data, acc-check-csrf-protection,
        acc-check-crypto-usage, acc-check-dependency-vulnerabilities, acc-check-sql-injection
```

**Навыки:** 9 (проверки безопасности)

---

## `acc-performance-reviewer`

**Путь:** `agents/acc-performance-reviewer.md`

Специалист по ревью производительности для проблем эффективности.

**Конфигурация:**
```yaml
name: acc-performance-reviewer
tools: Read, Grep, Glob
model: sonnet
skills: acc-detect-n-plus-one, acc-check-query-efficiency, acc-detect-memory-issues,
        acc-check-caching-strategy, acc-detect-unnecessary-loops, acc-check-lazy-loading,
        acc-check-batch-processing, acc-estimate-complexity
```

**Навыки:** 8 (проверки производительности)

---

## `acc-readability-reviewer`

**Путь:** `agents/acc-readability-reviewer.md`

Специалист по ревью читаемости для качества кода.

**Конфигурация:**
```yaml
name: acc-readability-reviewer
tools: Read, Grep, Glob
model: sonnet
skills: acc-check-naming, acc-check-code-style, acc-check-method-length,
        acc-check-class-length, acc-check-nesting-depth, acc-check-comments,
        acc-check-magic-values, acc-check-consistency, acc-suggest-simplification
```

**Навыки:** 9 (проверки читаемости)

---

## `acc-testability-reviewer`

**Путь:** `agents/acc-testability-reviewer.md`

Специалист по ревью тестируемости для качества тестов.

**Конфигурация:**
```yaml
name: acc-testability-reviewer
tools: Read, Grep, Glob
model: sonnet
skills: acc-check-dependency-injection, acc-check-pure-functions, acc-check-side-effects,
        acc-check-test-quality, acc-suggest-testability-improvements,
        acc-analyze-test-coverage, acc-detect-test-smells
```

**Навыки:** 7 (проверки тестируемости)

---

## `acc-bug-fix-coordinator`

**Путь:** `agents/acc-bug-fix-coordinator.md`

Координатор исправления багов, оркестрирующий диагностику, генерацию исправлений и регрессионное тестирование.

**Конфигурация:**
```yaml
name: acc-bug-fix-coordinator
tools: Task, Read, Grep, Glob, Edit, Write, Bash
model: opus
# Без навыков — делегирует специализированным агентам
```

**Рабочий процесс:**
1. Разбор ввода (текст, file:line, stack trace, лог-файл)
2. Task → `acc-bug-hunter` (диагностика категории бага)
3. Task → `acc-bug-fixer` (генерация минимального исправления)
4. Task → `acc-test-generator` (создание регрессионного теста)
5. Применение изменений и запуск тестов

**Мета-инструкции:**
- `-- focus on <area>` -- Приоритизировать конкретную область
- `-- skip tests` -- Не генерировать регрессионный тест
- `-- dry-run` -- Показать исправление без применения
- `-- verbose` -- Детальный вывод анализа

---

## `acc-bug-fixer`

**Путь:** `agents/acc-bug-fixer.md`

Специалист по исправлению багов, генерирующий безопасные минимальные исправления на основе диагностики от bug-hunter.

**Конфигурация:**
```yaml
name: acc-bug-fixer
tools: Read, Edit, Write, Grep, Glob
model: sonnet
skills: acc-bug-fix-knowledge, acc-bug-root-cause-finder, acc-bug-impact-analyzer,
        acc-generate-bug-fix, acc-bug-regression-preventer,
        acc-detect-code-smells, acc-detect-memory-issues, acc-analyze-solid-violations,
        acc-check-encapsulation, acc-check-side-effects, acc-check-immutability
```

**Навыки:** 11 (5 новых + 6 существующих)

**Возможности:**
- Анализ первопричины (5 Whys, дерево ошибок)
- Анализ влияния/радиуса поражения
- Шаблоны исправлений для 9 категорий багов
- Проверка качества (SOLID, code smells, инкапсуляция)
- Чек-лист предотвращения регрессий

---

## `acc-ci-coordinator`

**Путь:** `agents/acc-ci-coordinator.md`

Координатор CI/CD, оркестрирующий настройку пайплайна, исправление, оптимизацию и аудит.

**Конфигурация:**
```yaml
name: acc-ci-coordinator
tools: Read, Write, Edit, Grep, Glob, Bash, Task
model: opus
skills: acc-ci-pipeline-knowledge
```

**Операции:**
- **SETUP**: Создание нового CI-пайплайна с нуля
- **FIX**: Диагностика и исправление сбоев пайплайна с интерактивным подтверждением
- **OPTIMIZE**: Улучшение производительности пайплайна
- **AUDIT**: Комплексный аудит CI/CD

**Делегирование:**
- `acc-pipeline-architect` -- Структура workflow
- `acc-static-analysis-agent` -- Конфигурации PHPStan, Psalm, DEPTRAC
- `acc-test-pipeline-agent` -- Настройка PHPUnit, покрытия
- `acc-ci-debugger` -- Анализ логов, диагностика сбоев
- `acc-pipeline-optimizer` -- Кэширование, параллелизация
- `acc-ci-security-agent` -- Секреты, разрешения, зависимости
- `acc-docker-agent` -- Оптимизация Dockerfile
- `acc-deployment-agent` -- Стратегии деплоя

---

## `acc-pipeline-architect`

**Путь:** `agents/acc-pipeline-architect.md`

Специалист по проектированию пайплайнов для GitHub Actions и GitLab CI.

**Конфигурация:**
```yaml
name: acc-pipeline-architect
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-ci-pipeline-knowledge, acc-create-github-actions, acc-create-gitlab-ci, acc-detect-ci-antipatterns
```

**Навыки:** 4

---

## `acc-static-analysis-agent`

**Путь:** `agents/acc-static-analysis-agent.md`

Специалист по конфигурации статического анализа.

**Конфигурация:**
```yaml
name: acc-static-analysis-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-ci-tools-knowledge, acc-create-phpstan-config, acc-create-psalm-config,
        acc-create-deptrac-config, acc-create-rector-config, acc-psr-coding-style-knowledge,
        acc-check-code-style, acc-analyze-solid-violations, acc-detect-code-smells
```

**Навыки:** 9 (4 новых + 5 переиспользуемых)

---

## `acc-test-pipeline-agent`

**Путь:** `agents/acc-test-pipeline-agent.md`

Специалист по конфигурации тестового пайплайна.

**Конфигурация:**
```yaml
name: acc-test-pipeline-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-testing-knowledge, acc-analyze-test-coverage, acc-detect-test-smells,
        acc-check-test-quality, acc-ci-pipeline-knowledge
```

**Навыки:** 5 (4 переиспользуемых + 1 новый)

---

## `acc-ci-debugger`

**Путь:** `agents/acc-ci-debugger.md`

Специалист по анализу логов CI/CD и диагностике сбоев.

**Конфигурация:**
```yaml
name: acc-ci-debugger
tools: Read, Grep, Glob, Bash
model: sonnet
skills: acc-analyze-ci-logs, acc-ci-pipeline-knowledge, acc-ci-tools-knowledge
```

**Навыки:** 3

---

## `acc-ci-fixer`

**Путь:** `agents/acc-ci-fixer.md`

Специалист по генерации и применению исправлений CI. Создает минимальные безопасные исправления для проблем CI-конфигурации.

**Конфигурация:**
```yaml
name: acc-ci-fixer
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-generate-ci-fix, acc-ci-pipeline-knowledge, acc-ci-tools-knowledge,
        acc-create-github-actions, acc-create-gitlab-ci, acc-detect-ci-antipatterns
```

**Навыки:** 6 (1 новый + 5 переиспользуемых)

**Возможности:**
- Получает диагностику от `acc-ci-debugger`
- Выбирает подходящий паттерн исправления
- Генерирует минимальные безопасные изменения
- Применяет исправления к CI-конфигурации
- Предоставляет инструкции отката
- Поддерживает 10+ типов проблем (память, composer, тайм-ауты и др.)

---

## `acc-pipeline-optimizer`

**Путь:** `agents/acc-pipeline-optimizer.md`

Специалист по оптимизации производительности пайплайна.

**Конфигурация:**
```yaml
name: acc-pipeline-optimizer
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-ci-pipeline-knowledge, acc-estimate-pipeline-time, acc-detect-ci-antipatterns,
        acc-optimize-docker-layers, acc-analyze-ci-config, acc-detect-memory-issues,
        acc-check-caching-strategy
```

**Навыки:** 7 (2 переиспользуемых + 5 новых)

---

## `acc-ci-security-agent`

**Путь:** `agents/acc-ci-security-agent.md`

Специалист по безопасности CI/CD для секретов, разрешений и сканирования зависимостей.

**Конфигурация:**
```yaml
name: acc-ci-security-agent
tools: Read, Grep, Glob, Bash
model: sonnet
skills: acc-ci-pipeline-knowledge, acc-check-sensitive-data, acc-check-dependency-vulnerabilities,
        acc-check-crypto-usage
```

**Навыки:** 4 (3 переиспользуемых + 1 новый)

---

## `acc-docker-agent`

**Путь:** `agents/acc-docker-agent.md`

Специалист по конфигурации и оптимизации Docker.

**Конфигурация:**
```yaml
name: acc-docker-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-create-dockerfile-ci, acc-optimize-docker-layers, acc-ci-pipeline-knowledge
```

**Навыки:** 3

---

## `acc-deployment-agent`

**Путь:** `agents/acc-deployment-agent.md`

Специалист по конфигурации деплоя для стратегий blue-green, canary и rolling.

**Конфигурация:**
```yaml
name: acc-deployment-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-deployment-knowledge, acc-create-deploy-strategy, acc-create-feature-flags,
        acc-ci-pipeline-knowledge, acc-create-github-actions, acc-create-gitlab-ci
```

**Навыки:** 6

---

## `acc-docker-coordinator`

**Путь:** `agents/acc-docker-coordinator.md`

Координатор экспертной системы Docker. Оркестрирует аудит, генерацию и оптимизацию.

**Конфигурация:**
```yaml
name: acc-docker-coordinator
tools: Read, Grep, Glob, Bash, Task, TaskCreate, TaskUpdate
model: opus
skills: acc-docker-knowledge, acc-task-progress-knowledge
```

**Операции:**
- **AUDIT**: Комплексный аудит Docker-конфигурации
- **GENERATE**: Генерация Docker-компонентов

**Делегирование:**
- `acc-docker-architect-agent` -- Архитектура Dockerfile
- `acc-docker-image-builder` -- Базовые образы, расширения
- `acc-docker-compose-agent` -- Конфигурация Compose
- `acc-docker-performance-agent` -- Оптимизация производительности
- `acc-docker-security-agent` -- Аудит безопасности
- `acc-docker-debugger-agent` -- Диагностика ошибок
- `acc-docker-production-agent` -- Готовность к production

---

## `acc-docker-architect-agent`

**Путь:** `agents/acc-docker-architect-agent.md`

Специалист по архитектуре Dockerfile для multi-stage сборок, оптимизации слоев и функций BuildKit.

**Конфигурация:**
```yaml
name: acc-docker-architect-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-docker-knowledge, acc-docker-multistage-knowledge, acc-docker-buildkit-knowledge,
        acc-create-dockerfile-production, acc-create-dockerfile-dev
```

**Навыки:** 5

---

## `acc-docker-image-builder`

**Путь:** `agents/acc-docker-image-builder.md`

Специалист по выбору базовых образов и установке PHP-расширений.

**Конфигурация:**
```yaml
name: acc-docker-image-builder
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-docker-base-images-knowledge, acc-docker-php-extensions-knowledge,
        acc-create-dockerfile-production, acc-create-dockerfile-dev, acc-create-dockerignore
```

**Навыки:** 5

---

## `acc-docker-compose-agent`

**Путь:** `agents/acc-docker-compose-agent.md`

Специалист по конфигурации Docker Compose для PHP-стеков.

**Конфигурация:**
```yaml
name: acc-docker-compose-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-docker-compose-knowledge, acc-docker-networking-knowledge,
        acc-create-docker-compose-dev, acc-create-docker-compose-production,
        acc-check-docker-compose-config, acc-create-docker-env-template
```

**Навыки:** 6

---

## `acc-docker-performance-agent`

**Путь:** `agents/acc-docker-performance-agent.md`

Специалист по оптимизации производительности сборки и рантайма Docker.

**Конфигурация:**
```yaml
name: acc-docker-performance-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-optimize-docker-layers, acc-optimize-docker-build-time, acc-optimize-docker-image-size,
        acc-optimize-docker-php-fpm, acc-optimize-docker-opcache, acc-optimize-docker-startup
```

**Навыки:** 6

---

## `acc-docker-security-agent`

**Путь:** `agents/acc-docker-security-agent.md`

Специалист по аудиту безопасности и усилению защиты Docker.

**Конфигурация:**
```yaml
name: acc-docker-security-agent
tools: Read, Grep, Glob, Bash
model: sonnet
skills: acc-docker-security-knowledge, acc-docker-scanning-knowledge,
        acc-check-docker-security, acc-check-docker-secrets,
        acc-check-docker-user-permissions, acc-detect-docker-antipatterns
```

**Навыки:** 6

---

## `acc-docker-debugger-agent`

**Путь:** `agents/acc-docker-debugger-agent.md`

Специалист по диагностике ошибок Docker и устранению неполадок.

**Конфигурация:**
```yaml
name: acc-docker-debugger-agent
tools: Read, Grep, Glob, Bash
model: sonnet
skills: acc-docker-troubleshooting-knowledge, acc-analyze-docker-build-errors,
        acc-analyze-docker-runtime-errors, acc-analyze-docker-image-size
```

**Навыки:** 4

---

## `acc-docker-production-agent`

**Путь:** `agents/acc-docker-production-agent.md`

Специалист по готовности Docker к production для health checks, graceful shutdown и логирования.

**Конфигурация:**
```yaml
name: acc-docker-production-agent
tools: Read, Write, Edit, Grep, Glob
model: sonnet
skills: acc-docker-production-knowledge, acc-docker-orchestration-knowledge,
        acc-check-docker-production-readiness, acc-check-docker-healthcheck,
        acc-create-docker-healthcheck, acc-create-docker-entrypoint
```

**Навыки:** 6

---

## `acc-explain-coordinator`

**Путь:** `agents/acc-explain-coordinator.md`

Координатор объяснения кода. Оркестрирует навигацию по кодовой базе, извлечение бизнес-логики, трассировку потоков данных, визуализацию и предложения по документации. Поддерживает 5 режимов.

**Конфигурация:**
```yaml
name: acc-explain-coordinator
tools: Read, Grep, Glob, Bash, Task, TaskCreate, TaskUpdate
model: opus
skills: acc-explain-output-template, acc-task-progress-knowledge
```

**Рабочий процесс (4 фазы):**
1. **Навигация** -- Task → `acc-codebase-navigator` (сканирование структуры, точки входа, паттерны)
2. **Анализ** -- Task → `acc-business-logic-analyst` + `acc-data-flow-analyst` (+ аудиторы для deep/onboarding)
3. **Визуализация** -- Task → `acc-diagram-designer` + `acc-documentation-writer` (deep/onboarding/business)
4. **Представление** -- Агрегация результатов, форматирование вывода, предложение документации

**Режимы:** quick (файл), deep (модуль), onboarding (проект), business (нетехнический), qa (интерактивный)

---

## `acc-codebase-navigator`

**Путь:** `agents/acc-codebase-navigator.md`

Специалист по навигации по кодовой базе. Сканирует структуру директорий, определяет архитектурные слои, обнаруживает фреймворк и паттерны, находит точки входа.

**Конфигурация:**
```yaml
name: acc-codebase-navigator
tools: Read, Grep, Glob
model: sonnet
skills: acc-scan-codebase-structure, acc-identify-entry-points, acc-detect-architecture-pattern
```

**Навыки:** 3 (анализаторы)

---

## `acc-business-logic-analyst`

**Путь:** `agents/acc-business-logic-analyst.md`

Специалист по анализу бизнес-логики. Извлекает бизнес-правила, объясняет бизнес-процессы на естественном языке, строит карту доменных концепций и ubiquitous language, обнаруживает машины состояний.

**Конфигурация:**
```yaml
name: acc-business-logic-analyst
tools: Read, Grep, Glob
model: sonnet
skills: acc-extract-business-rules, acc-explain-business-process, acc-extract-domain-concepts, acc-extract-state-machine
```

**Навыки:** 4 (анализаторы)

---

## `acc-data-flow-analyst`

**Путь:** `agents/acc-data-flow-analyst.md`

Специалист по анализу потоков данных. Трассирует жизненный цикл запросов через все слои, строит карту трансформаций данных между DTO/Commands/Entities/Responses, определяет асинхронные потоки коммуникации.

**Конфигурация:**
```yaml
name: acc-data-flow-analyst
tools: Read, Grep, Glob
model: sonnet
skills: acc-trace-request-lifecycle, acc-trace-data-transformation, acc-map-async-flows
```

**Навыки:** 3 (анализаторы)

---

## Навигация

[← Назад к README](../README.md) | [Команды](commands.md) | [Навыки →](skills.md) | [Поток компонентов](component-flow.md) | [Краткий справочник](quick-reference.md)
