# Команды

Slash-команды для Claude Code. Команды -- это действия, вызываемые пользователем через `/command-name` в CLI.

## Поддержка мета-инструкций

Все команды поддерживают необязательные мета-инструкции через разделитель `--`:

```
/command <аргументы> -- <мета-инструкции>
```

**Примеры:**
```bash
/acc-audit-ddd ./src -- focus on aggregate boundaries
/acc-generate-test src/Order.php -- only unit tests, skip integration
/acc-commit v2.5.0 -- mention breaking changes
/acc-audit-architecture ./src -- на русском языке
```

Мета-инструкции позволяют:
- Сфокусировать анализ на конкретных аспектах
- Включить/исключить определенные проверки
- Запросить определенный язык вывода
- Добавить пользовательский контекст к задаче

## Обзор

| Команда | Аргументы | Назначение |
|---------|-----------|---------|
| `/acc-commit` | `[tag] [-- instructions]` | Автогенерация commit-сообщения и push |
| `/acc-generate-claude-component` | `[type] [-- instructions]` | Создание команд, агентов или навыков |
| `/acc-audit-claude-components` | `[-- instructions]` | Аудит качества папки `.claude/` |
| `/acc-audit-architecture` | `<path> [-- instructions]` | Многоуровневый аудит архитектуры |
| `/acc-audit-ddd` | `<path> [-- instructions]` | Анализ соответствия DDD |
| `/acc-audit-psr` | `<path> [-- instructions]` | Аудит соответствия PSR |
| `/acc-audit-security` | `<path> [-- instructions]` | Аудит безопасности OWASP Top 10 + PHP |
| `/acc-audit-performance` | `<path> [-- instructions]` | Аудит N+1, памяти, кэширования, сложности |
| `/acc-audit-patterns` | `<path> [-- instructions]` | Аудит паттернов проектирования + SOLID/GRASP |
| `/acc-generate-ddd` | `<type> <name> [-- instructions]` | Генерация DDD-компонентов (entity, VO, aggregate и др.) |
| `/acc-generate-psr` | `<psr> <name> [-- instructions]` | Генерация PSR-совместимых компонентов |
| `/acc-generate-patterns` | `<pattern> <name> [-- instructions]` | Генерация реализаций паттернов проектирования |
| `/acc-refactor` | `<path> [-- instructions]` | Управляемый рефакторинг с анализом |
| `/acc-generate-documentation` | `<path> [-- instructions]` | Генерация документации |
| `/acc-audit-documentation` | `<path> [-- instructions]` | Аудит качества документации |
| `/acc-generate-test` | `<path> [-- instructions]` | Генерация тестов для PHP-кода |
| `/acc-audit-test` | `<path> [-- instructions]` | Аудит качества тестов и покрытия |
| `/acc-code-review` | `[branch] [level] [-- task]` | Многоуровневый code review с привязкой к задаче |
| `/acc-bug-fix` | `<description\|file:line\|trace>` | Диагностика и исправление бага с регрессионным тестированием |
| `/acc-ci-setup` | `<platform> [path] [-- instructions]` | Настройка CI-пайплайна с нуля |
| `/acc-ci-fix` | `<pipeline-url\|log-file\|description> [-- instructions]` | Исправление проблем CI-пайплайна с интерактивным подтверждением |
| `/acc-ci-optimize` | `[path] [-- focus areas]` | Оптимизация производительности CI-пайплайна |
| `/acc-audit-ci` | `[path] [-- focus areas]` | Комплексный аудит CI/CD |
| `/acc-audit-docker` | `[path] [-- focus areas]` | Аудит Docker-конфигурации: Dockerfile, Compose, безопасность, производительность |
| `/acc-generate-docker` | `<type> [name] [-- instructions]` | Генерация Docker-компонентов (Dockerfile, Compose, Nginx и др.) |
| `/acc-explain` | `<path\|route\|command> [mode] [-- instructions]` | Объяснение кода: структура, бизнес-логика, потоки данных, архитектура |

---

## `/acc-generate-claude-component`

**Путь:** `commands/acc-generate-claude-component.md`

Интерактивный мастер создания компонентов Claude Code.

**Аргументы:**
```
/acc-generate-claude-component [type] [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `type` | Нет | Тип компонента: `command`, `agent`, `skill`, `hook` |
| `-- instructions` | Нет | Дополнительный контекст для генерации |

**Примеры:**
```bash
/acc-generate-claude-component                        # Интерактивный режим
/acc-generate-claude-component command                # Пропуск выбора типа
/acc-generate-claude-component agent -- for DDD auditing
/acc-generate-claude-component skill -- generates Value Objects
```

**Процесс:**
1. Спрашивает, что создать (command/agent/skill/hook) -- пропускается, если тип указан
2. Собирает требования через вопросы
3. Использует агент `acc-claude-code-expert` с навыком `acc-claude-code-knowledge`
4. Создает компонент с правильной структурой
5. Валидирует и показывает результат

---

## `/acc-audit-claude-components`

**Путь:** `commands/acc-audit-claude-components.md`

Аудит структуры и качества конфигурации папки `.claude/`.

**Аргументы:**
```
/acc-audit-claude-components [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `-- instructions` | Нет | Фокусировка аудита на конкретных аспектах |

**Примеры:**
```bash
/acc-audit-claude-components                           # Полный аудит
/acc-audit-claude-components -- focus on agents only
/acc-audit-claude-components -- check for unused skills
```

**Анализирует:**
- Команды (YAML frontmatter, описания, ограничения инструментов)
- Агенты (именование, ссылки на навыки, права инструментов)
- Навыки (структура, размер, ссылки)
- Настройки (хуки, разрешения, секреты)
- Целостность перекрестных ссылок

**Результат:**
- Дерево файлов с индикаторами статуса
- Детальный анализ проблем
- Приоритизированные рекомендации
- Готовые к применению быстрые исправления

---

## `/acc-commit`

**Путь:** `commands/acc-commit.md`

Автогенерация commit-сообщения из diff и push в текущую ветку.

**Аргументы:**
```
/acc-commit [tag-name] [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `tag-name` | Нет | Тег версии для создания (например, `v2.5.0`) |
| `-- instructions` | Нет | Подсказки для commit-сообщения |

**Примеры:**
```bash
/acc-commit                                      # Commit и push
/acc-commit v2.5.0                               # Commit, push и создание тега
/acc-commit -- focus on security changes
/acc-commit v2.5.0 -- mention breaking changes
/acc-commit -- use Russian for commit message
```

---

## `/acc-audit-architecture`

**Путь:** `commands/acc-audit-architecture.md`

Комплексный многоуровневый аудит архитектуры для PHP-проектов.

**Аргументы:**
```
/acc-audit-architecture <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к проекту или папке для аудита |
| `-- instructions` | Нет | Фокусировка или настройка аудита |

**Примеры:**
```bash
/acc-audit-architecture ./src
/acc-audit-architecture ./src -- only check CQRS patterns
/acc-audit-architecture ./src -- generate fixes for violations
/acc-audit-architecture ./src -- на русском языке
```

**Анализирует:**
- Соответствие DDD
- Паттерны CQRS
- Clean Architecture
- Hexagonal Architecture
- Layered Architecture
- Event Sourcing
- Event-Driven Architecture
- Outbox Pattern
- Saga Pattern
- Паттерны стабильности (Circuit Breaker, Retry, Rate Limiter, Bulkhead)
- Поведенческие паттерны (Strategy, State, Chain, Decorator, Null Object, Template Method, Visitor, Iterator, Memento)
- Структурные паттерны GoF (Adapter, Facade, Proxy, Composite, Bridge, Flyweight)

---

## `/acc-audit-ddd`

**Путь:** `commands/acc-audit-ddd.md`

Анализ соответствия DDD для PHP-проектов.

**Аргументы:**
```
/acc-audit-ddd <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к проекту или папке для аудита |
| `-- instructions` | Нет | Фокусировка на конкретных аспектах DDD |

**Примеры:**
```bash
/acc-audit-ddd ./src
/acc-audit-ddd ./src/Domain/Order -- focus on aggregate boundaries
/acc-audit-ddd ./src -- generate missing Value Objects
```

---

## `/acc-audit-psr`

**Путь:** `commands/acc-audit-psr.md`

Анализ соответствия PSR для PHP-проектов.

**Аргументы:**
```
/acc-audit-psr <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к проекту или папке для аудита |
| `-- instructions` | Нет | Фокусировка на конкретных стандартах PSR |

**Примеры:**
```bash
/acc-audit-psr ./src
/acc-audit-psr ./src -- only PSR-12 style check
/acc-audit-psr ./src -- generate missing PSR interfaces
```

**Проверяет:**
- Соответствие стилю PSR-1/PSR-12
- Структуру автозагрузки PSR-4
- Реализации PSR-интерфейсов

---

## `/acc-generate-documentation`

**Путь:** `commands/acc-generate-documentation.md`

Генерация документации для файла, папки или проекта.

**Аргументы:**
```
/acc-generate-documentation <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к файлу/папке для документирования (`.` для корня проекта) |
| `-- instructions` | Нет | Настройка формата документации |

**Примеры:**
```bash
/acc-generate-documentation ./
/acc-generate-documentation src/ -- focus on API documentation
/acc-generate-documentation ./ -- create architecture doc with C4 diagrams
/acc-generate-documentation src/Domain/Order -- document only public interfaces
/acc-generate-documentation ./ -- на русском языке
```

**Генерирует:**
- README.md для проектов
- ARCHITECTURE.md с диаграммами
- API-документацию
- Руководства по началу работы

---

## `/acc-audit-documentation`

**Путь:** `commands/acc-audit-documentation.md`

Аудит качества документации.

**Аргументы:**
```
/acc-audit-documentation <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к папке документации для аудита |
| `-- instructions` | Нет | Фокусировка на конкретных аспектах качества |

**Примеры:**
```bash
/acc-audit-documentation ./docs
/acc-audit-documentation ./docs -- only check code examples
/acc-audit-documentation ./ -- fix broken links
```

**Проверяет:**
- Полноту (все API задокументированы)
- Точность (код соответствует документации)
- Ясность (нет жаргона, рабочие примеры)
- Единообразие (единый стиль)
- Навигацию (рабочие ссылки)

---

## `/acc-generate-test`

**Путь:** `commands/acc-generate-test.md`

Генерация тестов для PHP-файла или папки.

**Аргументы:**
```
/acc-generate-test <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к PHP-файлу или папке для тестирования |
| `-- instructions` | Нет | Настройка генерации тестов |

**Примеры:**
```bash
/acc-generate-test src/Domain/Order/Order.php
/acc-generate-test src/Domain/Order/ -- only unit tests, skip integration
/acc-generate-test src/Service/PaymentService.php -- include edge cases for null payments
/acc-generate-test src/ -- create builders for all entities
/acc-generate-test src/Application/ -- focus on happy path scenarios
```

**Генерирует:**
- Модульные тесты для Value Objects, Entities, Services
- Интеграционные тесты для Repositories, HTTP-клиентов
- Test Data Builders и Object Mothers
- InMemory-реализации репозиториев
- Тестовые дублеры (Mocks, Stubs, Fakes, Spies)

---

## `/acc-audit-test`

**Путь:** `commands/acc-audit-test.md`

Аудит качества тестов и покрытия.

**Аргументы:**
```
/acc-audit-test <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к папке с тестами или проекту |
| `-- instructions` | Нет | Фокусировка на конкретных аспектах качества |

**Примеры:**
```bash
/acc-audit-test ./tests
/acc-audit-test ./src -- check coverage gaps only
/acc-audit-test ./tests -- focus on test smells
/acc-audit-test ./tests/Unit/Domain -- generate missing tests
```

**Проверяет:**
- Пробелы в покрытии (непротестированные классы, методы, ветки)
- Тестовые антипаттерны (15 видов)
- Соблюдение соглашений об именовании
- Проблемы изоляции тестов

**Результат:**
- Метрики качества с баллами
- Приоритизированный список проблем
- Рекомендации навыков для исправления

---

## `/acc-code-review`

**Путь:** `commands/acc-code-review.md`

Многоуровневый code review с анализом git diff и привязкой к задаче.

**Аргументы:**
```
/acc-code-review [branch] [level] [-- task-description]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `branch` | Нет | Ветка для ревью (по умолчанию: текущая) |
| `level` | Нет | Глубина ревью: `low`, `medium`, `high` (по умолчанию: high) |
| `-- task-description` | Нет | Ожидаемая задача для анализа соответствия |

**Примеры:**
```bash
/acc-code-review                                    # Текущая ветка, уровень high
/acc-code-review feature/payment                    # feature/payment vs main, high
/acc-code-review medium                             # Текущая ветка, уровень medium
/acc-code-review feature/payment medium             # feature/payment vs main, medium
/acc-code-review feature/payment -- add auth        # С привязкой к задаче
/acc-code-review -- implement JWT auth              # Текущая ветка + привязка к задаче
/acc-code-review feature/payment low -- add tests   # Все опции вместе
```

**Уровни ревью:**

| Уровень | Проверки | Сценарий использования |
|-------|--------|----------|
| **LOW** | PSR, тесты, инкапсуляция, code smells | Быстрая проверка PR |
| **MEDIUM** | LOW + баги, читаемость, нарушения SOLID | Стандартное ревью |
| **HIGH** | MEDIUM + безопасность, производительность, тестируемость, DDD, архитектура | Полный аудит |

**Результат:**
- Сводка изменений (файлы, коммиты, измененные строки)
- Находки по серьезности (Critical/Major/Minor/Suggestion)
- Анализ соответствия задаче с процентной оценкой (если задача указана)
- Вердикт: APPROVE / APPROVE WITH COMMENTS / REQUEST CHANGES

---

## `/acc-bug-fix`

**Путь:** `commands/acc-bug-fix.md`

Автоматическая диагностика бага, генерация исправления и регрессионное тестирование.

**Аргументы:**
```
/acc-bug-fix <description|file:line|stack-trace> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `description` | **Да** | Описание бага, ссылка file:line или stack trace |
| `-- instructions` | Нет | Фокусировка или настройка процесса исправления |

**Форматы ввода:**
- Текстовое описание: `"NullPointerException in OrderService::process()"`
- Ссылка file:line: `src/Domain/Order.php:45 "off-by-one error"`
- Stack trace: Вставьте полный trace
- Лог-файл: `@storage/logs/error.log`

**Примеры:**
```bash
/acc-bug-fix "NullPointerException in OrderService::process()"
/acc-bug-fix src/Domain/Order.php:45 "off-by-one error in loop"
/acc-bug-fix @storage/logs/laravel.log
/acc-bug-fix "Payment fails for amounts > 1000" -- focus on validation
/acc-bug-fix src/Service/Auth.php:78 -- skip tests
/acc-bug-fix "Race condition in inventory" -- dry-run
```

**Мета-инструкции:**
| Инструкция | Эффект |
|-------------|--------|
| `-- focus on <area>` | Приоритизировать конкретную область кода |
| `-- skip tests` | Не генерировать регрессионный тест |
| `-- dry-run` | Показать исправление без применения |
| `-- verbose` | Включить детальный анализ |

**Рабочий процесс:**
1. **Разбор ввода** -- Извлечение файла, строки, описания
2. **Диагностика** -- `acc-bug-hunter` категоризирует баг (9 типов)
3. **Исправление** -- `acc-bug-fixer` генерирует минимальное безопасное исправление
4. **Тестирование** -- `acc-test-generator` создает регрессионный тест
5. **Применение** -- Применение изменений и запуск тестов

**Результат:**
- Категория и серьезность бага
- Анализ первопричины
- Diff примененного исправления
- Файл регрессионного теста
- Результаты выполнения тестов

---

## `/acc-audit-security`

**Путь:** `commands/acc-audit-security.md`

Аудит безопасности, охватывающий OWASP Top 10 и PHP-специфичные уязвимости.

**Аргументы:**
```
/acc-audit-security <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к проекту или папке для аудита |
| `-- instructions` | Нет | Фокусировка на конкретных аспектах безопасности |

**Примеры:**
```bash
/acc-audit-security ./src
/acc-audit-security ./src/Api -- focus on OWASP A01-A03
/acc-audit-security ./src/Payment -- check SQL injection and CSRF
/acc-audit-security ./src -- skip A06 (vulnerable components)
```

**Проверяет:**
- OWASP Top 10 (2021): Access Control, Crypto, Injection и др.
- PHP-специфичные: `unserialize()`, `eval()`, `shell_exec()`, type juggling
- Идентификаторы CWE и векторы атак
- Примеры кода для исправлений

---

## `/acc-audit-performance`

**Путь:** `commands/acc-audit-performance.md`

Аудит производительности с фокусом на базу данных, память и эффективность алгоритмов.

**Аргументы:**
```
/acc-audit-performance <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к проекту или папке для аудита |
| `-- instructions` | Нет | Фокусировка на конкретных аспектах производительности |

**Примеры:**
```bash
/acc-audit-performance ./src
/acc-audit-performance ./src/Repository -- check N+1 queries
/acc-audit-performance ./src -- focus on memory and caching
/acc-audit-performance ./src/Domain -- analyze algorithm complexity
```

**Проверяет:**
- Проблемы N+1 запросов
- Эффективность запросов (SELECT *, отсутствующие индексы)
- Проблемы памяти (большие массивы, отсутствие генераторов)
- Возможности кэширования
- Сложность алгоритмов (паттерны O(n^2))
- Пробелы в пакетной обработке
- Проблемы пула соединений
- Накладные расходы сериализации

---

## `/acc-audit-patterns`

**Путь:** `commands/acc-audit-patterns.md`

Аудит паттернов проектирования с анализом соответствия SOLID/GRASP.

**Аргументы:**
```
/acc-audit-patterns <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к проекту или папке для аудита |
| `-- instructions` | Нет | Фокусировка на конкретных категориях паттернов |

**Примеры:**
```bash
/acc-audit-patterns ./src
/acc-audit-patterns ./src/Infrastructure -- focus on stability patterns
/acc-audit-patterns ./src -- check behavioral patterns only
/acc-audit-patterns ./src -- skip SOLID analysis
```

**Проверяет:**
- **Паттерны стабильности**: Circuit Breaker, Retry, Rate Limiter, Bulkhead
- **Поведенческие паттерны**: Strategy, State, Chain of Responsibility, Decorator, Null Object, Template Method, Visitor, Iterator, Memento
- **Структурные паттерны GoF**: Adapter, Facade, Proxy, Composite, Bridge, Flyweight
- **Порождающие паттерны**: Builder, Object Pool, Factory
- **Интеграционные паттерны**: Outbox, Saga, ADR
- **Принципы SOLID**: SRP, OCP, LSP, ISP, DIP
- **Принципы GRASP**: Information Expert, Creator, Controller и др.

---

## `/acc-generate-ddd`

**Путь:** `commands/acc-generate-ddd.md`

Генерация DDD-компонентов для PHP 8.2 с тестами и правильным размещением по слоям.

**Аргументы:**
```
/acc-generate-ddd <component-type> <ComponentName> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `component-type` | **Да** | Компонент для генерации (см. список ниже) |
| `ComponentName` | **Да** | Имя компонента |
| `-- instructions` | Нет | Настройка генерации |

**Примеры:**
```bash
/acc-generate-ddd entity Order
/acc-generate-ddd vo Email -- with DNS validation
/acc-generate-ddd aggregate ShoppingCart -- with CartItem child
/acc-generate-ddd command CreateOrder
/acc-generate-ddd query GetUserOrders -- with pagination
/acc-generate-ddd use-case ProcessPayment -- with retry logic
/acc-generate-ddd repository Order -- Doctrine implementation
/acc-generate-ddd dto OrderRequest -- for REST API
/acc-generate-ddd acl StripePayment
```

**Поддерживаемые компоненты:**

| Компонент | Псевдонимы | Слой |
|-----------|---------|-------|
| `entity` | `ent` | Domain |
| `value-object` | `vo`, `valueobject` | Domain |
| `aggregate` | `agg`, `aggregate-root` | Domain |
| `domain-event` | `event`, `de` | Domain |
| `repository` | `repo` | Domain + Infrastructure |
| `domain-service` | `service`, `ds` | Domain |
| `factory` | `fact` | Domain |
| `specification` | `spec` | Domain |
| `command` | `cmd` | Application |
| `query` | `qry` | Application |
| `use-case` | `usecase`, `uc` | Application |
| `dto` | `data-transfer` | Application |
| `acl` | `anti-corruption` | Infrastructure |

---

## `/acc-generate-psr`

**Путь:** `commands/acc-generate-psr.md`

Генерация PSR-совместимых PHP-компонентов с тестами.

**Аргументы:**
```
/acc-generate-psr <psr-number> <ComponentName> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `psr-number` | **Да** | Стандарт PSR: `psr-3`, `psr-6`, `psr-7` и др. |
| `ComponentName` | Нет | Имя для реализации |
| `-- instructions` | Нет | Настройка генерации |

**Примеры:**
```bash
/acc-generate-psr psr-3 FileLogger
/acc-generate-psr psr-15 AuthMiddleware
/acc-generate-psr psr-6 RedisCache -- with TTL support
/acc-generate-psr psr-7 -- generate full HTTP stack
/acc-generate-psr psr-20 FrozenClock -- for testing
```

**Поддерживаемые PSR:**
- PSR-3 (Logger), PSR-6 (Cache), PSR-7 (HTTP Message)
- PSR-11 (Container), PSR-13 (Links), PSR-14 (Events)
- PSR-15 (Middleware), PSR-16 (Simple Cache)
- PSR-17 (HTTP Factories), PSR-18 (HTTP Client), PSR-20 (Clock)

---

## `/acc-generate-patterns`

**Путь:** `commands/acc-generate-patterns.md`

Генерация реализаций паттернов проектирования с конфигурацией DI.

**Аргументы:**
```
/acc-generate-patterns <pattern-name> <ComponentName> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `pattern-name` | **Да** | Паттерн для генерации (см. список ниже) |
| `ComponentName` | **Да** | Имя контекста/компонента |
| `-- instructions` | Нет | Настройка генерации |

**Примеры:**
```bash
/acc-generate-patterns circuit-breaker PaymentGateway
/acc-generate-patterns strategy PaymentProcessor
/acc-generate-patterns saga CheckoutWorkflow
/acc-generate-patterns builder UserProfile -- with validation
/acc-generate-patterns outbox Order -- with Doctrine integration
```

**Поддерживаемые паттерны:**
- **Стабильность**: `circuit-breaker`, `retry`, `rate-limiter`, `bulkhead`
- **Поведенческие**: `strategy`, `state`, `chain-of-responsibility`, `decorator`, `null-object`, `template-method`, `visitor`, `iterator`, `memento`
- **Структурные GoF**: `adapter`, `facade`, `proxy`, `composite`, `bridge`, `flyweight`
- **Порождающие**: `builder`, `object-pool`, `factory`
- **Интеграционные**: `outbox`, `saga`, `action`, `responder`

---

## `/acc-refactor`

**Путь:** `commands/acc-refactor.md`

Управляемый рефакторинг с анализом и применением паттернов.

**Аргументы:**
```
/acc-refactor <path> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | **Да** | Путь к файлу или папке для рефакторинга |
| `-- instructions` | Нет | Фокусировка или настройка рефакторинга |

**Примеры:**
```bash
/acc-refactor ./src/Domain/OrderService.php
/acc-refactor ./src/Application -- focus on SOLID violations
/acc-refactor ./src -- extract value objects only
/acc-refactor ./src/Service -- analyze testability, skip style
/acc-refactor ./src -- quick wins only
```

**Анализирует:**
- Code smells (God Class, Long Method, Primitive Obsession и др.)
- Нарушения SOLID
- Проблемы тестируемости (DI, побочные эффекты, покрытие)
- Читаемость (именование, сложность, магические значения)

**Предоставляет:**
- Приоритизированную дорожную карту рефакторинга
- Команды генерации для автоматических исправлений
- Быстрые улучшения для немедленного применения
- Предупреждения о покрытии тестами
- Рекомендации по безопасности

---

## `/acc-ci-setup`

**Путь:** `commands/acc-ci-setup.md`

Настройка CI-пайплайна с нуля для PHP-проектов.

**Аргументы:**
```
/acc-ci-setup <platform> [path] [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `platform` | **Да** | CI-платформа: `github` или `gitlab` |
| `path` | Нет | Путь к проекту (по умолчанию: `./`) |
| `-- instructions` | Нет | Настройка генерации пайплайна |

**Примеры:**
```bash
/acc-ci-setup github
/acc-ci-setup gitlab ./my-project
/acc-ci-setup github -- include Docker, blue-green deploy
/acc-ci-setup gitlab -- focus on testing, high coverage
/acc-ci-setup github -- minimal, only lint and tests
```

**Генерирует:**
- CI-workflow (`.github/workflows/ci.yml` или `.gitlab-ci.yml`)
- Конфигурации статического анализа (PHPStan, Psalm, PHP-CS-Fixer, DEPTRAC)
- Конфигурацию тестирования (PHPUnit)
- Docker-файлы (по запросу)
- Конфигурацию деплоя (по запросу)

---

## `/acc-ci-fix`

**Путь:** `commands/acc-ci-fix.md`

Диагностика и исправление проблем CI-пайплайна с интерактивным подтверждением.

**Аргументы:**
```
/acc-ci-fix <pipeline-url|log-file|description> [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `pipeline-url` | Нет | URL пайплайна GitHub/GitLab |
| `log-file` | Нет | Путь к лог-файлу |
| `description` | Нет | Текстовое описание проблемы |
| `-- instructions` | Нет | Мета-инструкции для процесса исправления |

**Форматы ввода:**
- URL пайплайна: `https://github.com/org/repo/actions/runs/123`
- Лог-файл: `./ci-error.log` или `@storage/logs/ci.log`
- Описание: `"PHPStan fails with memory error"`

**Примеры:**
```bash
# Интерактивный режим (по умолчанию) - диагностика, показ исправления, запрос подтверждения
/acc-ci-fix "PHPStan memory exhausted"
/acc-ci-fix https://github.com/org/repo/actions/runs/12345
/acc-ci-fix ./ci-error.log

# Пробный запуск - показ диагностики и исправления без применения
/acc-ci-fix ./ci.log -- dry-run

# Автоприменение - применение исправления без запроса (для скриптов/CI)
/acc-ci-fix ./ci.log -- auto-apply

# С дополнительными опциями
/acc-ci-fix ./logs/ci.txt -- verbose, skip-validation
/acc-ci-fix "Tests timeout" -- focus on Docker
```

**Мета-инструкции:**
| Инструкция | Эффект |
|-------------|--------|
| `-- dry-run` | Показать диагностику и исправление без применения |
| `-- auto-apply` | Применить исправление без запроса (для CI/скриптов) |
| `-- skip-validation` | Не запускать локальные проверки синтаксиса |
| `-- verbose` | Включить детальный вывод диагностики |
| `-- focus on <area>` | Приоритизировать конкретную область (tests, lint, docker) |

**Поддерживаемые типы проблем:**

| Тип проблемы | Поддержка автоисправления |
|------------|------------------|
| Memory exhausted | ✅ Полная |
| Composer conflict | ✅ Полная |
| PHPStan baseline | ✅ Полная |
| Service not ready | ✅ Полная |
| Docker build fail | ⚠️ Частичная |
| Timeout | ✅ Полная |
| Permission denied | ✅ Полная |
| Cache miss | ✅ Полная |
| PHP extension | ✅ Полная |
| Env variable | ✅ Полная |

**Рабочий процесс:**
1. **Разбор ввода** -- URL, лог-файл или описание
2. **Диагностика** -- `acc-ci-debugger` определяет тип сбоя и первопричину
3. **Генерация исправления** -- `acc-ci-fixer` создает предварительный просмотр исправления
4. **Запрос подтверждения** -- Если не указано `-- dry-run` или `-- auto-apply`
5. **Применение или пропуск** -- В зависимости от ответа пользователя
6. **Валидация** -- Запуск локальных проверок синтаксиса (если не указано `-- skip-validation`)
7. **Отчет** -- Сводка с diff и инструкциями отката

---

## `/acc-ci-optimize`

**Путь:** `commands/acc-ci-optimize.md`

Оптимизация производительности CI/CD-пайплайна.

**Аргументы:**
```
/acc-ci-optimize [path] [-- focus areas]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | Нет | Путь к проекту (по умолчанию: `./`) |
| `-- focus areas` | Нет | Конкретные цели оптимизации |

**Примеры:**
```bash
/acc-ci-optimize
/acc-ci-optimize -- focus on caching, reduce cache misses
/acc-ci-optimize -- optimize Docker build time
/acc-ci-optimize -- split tests into parallel jobs
/acc-ci-optimize ./my-project -- target 10 min total
```

**Оптимизирует:**
- Кэширование (Composer, Docker-слои, артефакты)
- Параллелизацию (независимые задачи, разделение тестов)
- Docker-сборки (multi-stage, порядок слоев)
- Зависимости задач (быстрый отказ, тайм-ауты)

**Результат:**
- Сравнение метрик до/после
- Конкретные изменения для применения
- Оценка экономии времени

---

## `/acc-audit-ci`

**Путь:** `commands/acc-audit-ci.md`

Комплексный аудит CI/CD для PHP-проектов.

**Аргументы:**
```
/acc-audit-ci [path] [-- focus areas]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | Нет | Путь к проекту (по умолчанию: `./`) |
| `-- focus areas` | Нет | Фокусировка на конкретных областях аудита |

**Примеры:**
```bash
/acc-audit-ci
/acc-audit-ci -- focus on security
/acc-audit-ci -- performance only
/acc-audit-ci ./my-project -- security and testing, skip deployment
/acc-audit-ci -- quick audit
```

**Категории аудита:**
- **Пайплайн**: Организация стадий, зависимости, триггеры
- **Статический анализ**: Уровень PHPStan, Psalm, правила DEPTRAC
- **Тестирование**: Пороги покрытия, организация тестов
- **Безопасность**: Обработка секретов, разрешения, зависимости
- **Производительность**: Эффективность кэширования, параллелизация
- **Docker**: Размер образов, оптимизация слоев, безопасность
- **Деплой**: Zero-downtime, health checks, откат

**Результат:**
- Сводка с оценками
- Проблемы по серьезности (Critical/High/Medium/Low)
- Приоритизированные рекомендации
- Список действий

---

## `/acc-audit-docker`

**Путь:** `commands/acc-audit-docker.md`

Комплексный аудит Docker-конфигурации для PHP-проектов.

**Аргументы:**
```
/acc-audit-docker [path] [-- focus areas]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `path` | Нет | Путь к проекту (по умолчанию: `./`) |
| `-- focus areas` | Нет | Фокусировка на конкретных областях аудита |

**Примеры:**
```bash
/acc-audit-docker
/acc-audit-docker -- focus on security
/acc-audit-docker -- performance and image size
/acc-audit-docker ./ -- security and production readiness
```

**Категории аудита:**
- **Архитектура Dockerfile**: Multi-stage, слои, BuildKit
- **Базовые образы и расширения**: Выбор, закрепление версий, совместимость
- **Docker Compose**: Сервисы, health checks, сети
- **Производительность**: Время сборки, размер образа, кэширование, PHP-FPM
- **Безопасность**: Права доступа, секреты, уязвимости
- **Готовность к production**: Health checks, graceful shutdown, логирование

---

## `/acc-generate-docker`

**Путь:** `commands/acc-generate-docker.md`

Генерация Docker-компонентов для PHP-проектов.

**Аргументы:**
```
/acc-generate-docker <component-type> [name] [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `component-type` | **Да** | Компонент для генерации (см. список ниже) |
| `name` | Нет | Имя проекта/сервиса |
| `-- instructions` | Нет | Настройка генерации |

**Примеры:**
```bash
/acc-generate-docker full
/acc-generate-docker dockerfile -- with Symfony
/acc-generate-docker compose -- with PostgreSQL and Redis
/acc-generate-docker nginx -- with SSL
/acc-generate-docker entrypoint -- with migrations
```

**Поддерживаемые компоненты:**

| Компонент | Псевдонимы | Описание |
|-----------|---------|-------------|
| `dockerfile` | `df` | Production multi-stage Dockerfile |
| `compose` | `dc` | Конфигурация Docker Compose |
| `nginx` | `web` | Конфигурация Nginx reverse proxy |
| `entrypoint` | `ep` | Скрипт entrypoint контейнера |
| `makefile` | `mk` | Команды Docker Makefile |
| `env` | `environment` | Шаблон переменных окружения |
| `healthcheck` | `hc` | Скрипт health check |
| `full` | `all` | Полная Docker-конфигурация |

---

## `/acc-explain`

**Путь:** `commands/acc-explain.md`

Объяснение структуры кода, бизнес-логики, потоков данных и архитектурных паттернов. Принимает пути к файлам, директории, HTTP-маршруты или консольные команды.

**Аргументы:**
```
/acc-explain <path|route|command> [mode] [-- instructions]
```

| Аргумент | Обязательный | Описание |
|----------|----------|-------------|
| `input` | **Да** | Файл, директория, `.`, HTTP-маршрут (`GET /api/orders`) или консольная команда (`app:process-payments`) |
| `mode` | Нет | `quick`, `deep`, `onboarding`, `business`, `qa` (автоопределение) |
| `-- instructions` | Нет | Область фокуса или конкретный вопрос |

**Типы ввода (автоопределение):**

| Ввод | Паттерн | Пример |
|-------|---------|---------|
| HTTP-маршрут | `METHOD /path` | `GET /api/orders`, `POST /api/orders/{id}/status` |
| Консольная команда | `namespace:name` | `app:process-payments`, `import:products` |
| Путь к файлу | Существующий файл | `src/Domain/Order/Order.php` |
| Директория | Существующая директория | `src/Domain/Order/` |
| Корень проекта | `.` | `.` |

**Примеры:**
```bash
# HTTP-маршруты
/acc-explain GET /api/orders                               # Резолв маршрута → объяснение обработчика
/acc-explain POST /api/orders/{id}/status deep             # Режим deep для маршрута
/acc-explain DELETE /api/users/{id} -- explain cascade deletion

# Консольные команды
/acc-explain app:process-payments                          # Резолв команды → объяснение обработчика
/acc-explain import:products -- explain data transformation pipeline

# Файл/директория (стандартное поведение)
/acc-explain src/Domain/Order/Order.php                    # Режим quick (авто)
/acc-explain src/Domain/Order/                             # Режим deep (авто)
/acc-explain .                                             # Режим onboarding (авто)
/acc-explain src/Payment business                          # Режим business
/acc-explain src/Domain qa -- how are discounts calculated? # Режим qa
/acc-explain src/Domain/Order/ deep -- focus on state transitions
```

**Режимы:**

| Режим | Автоопределение | Глубина | Аудитория |
|------|-------------|-------|----------|
| `quick` | Отдельный файл, HTTP-маршрут, консольная команда | 1-2 экрана | Разработчик |
| `deep` | Директория | Полный анализ + диаграммы | Senior / Архитектор |
| `onboarding` | `.` (корень) | Исчерпывающее руководство | Новый член команды |
| `business` | Только явно | Нетехнический обзор | PM / Стейкхолдер |
| `qa` | Только явно | Фокус на ответе | Любой |

**Рабочий процесс:**
0. **Резолв** -- Если ввод route/command, резолв в файл обработчика (Фаза 0)
1. **Навигация** -- Сканирование структуры, поиск точек входа, определение паттернов
2. **Анализ** -- Извлечение бизнес-логики, трассировка потоков данных, аудит паттернов
3. **Визуализация** -- Генерация Mermaid-диаграмм (deep/onboarding/business)
4. **Представление** -- Агрегация результатов, предложение документации

**Результат:**
- Quick: Назначение, ответственности, бизнес-правила, поток данных, зависимости
- Deep: Полный анализ с Mermaid-диаграммами, доменная модель, машины состояний
- Onboarding: Руководство по проекту с C4-диаграммами, глоссарий, "Как ориентироваться"
- Business: Нетехнический обзор с простыми диаграммами потоков
- QA: Прямой ответ со ссылками на код

---

## Навигация

[← Назад к README](../README.md) | [Агенты →](agents.md) | [Навыки](skills.md) | [Поток компонентов](component-flow.md) | [Краткий справочник](quick-reference.md)
