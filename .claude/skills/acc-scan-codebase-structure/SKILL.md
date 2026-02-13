---
name: acc-scan-codebase-structure
description: Сканирует дерево каталогов для определения архитектурных слоёв (Domain, Application, Infrastructure, Presentation), обнаружения фреймворка (Symfony, Laravel, кастомный), подсчёта файлов по слоям и построения карты структуры проекта.
---

# Сканер структуры кодовой базы

## Обзор

Анализирует дерево каталогов для построения структурированной карты проекта: определяет архитектурные слои, обнаруживает используемый фреймворк, подсчитывает файлы по слоям и определяет общий паттерн организации проекта.

## Процесс сканирования

### Шаг 1: Анализ дерева каталогов

```bash
# Получить структуру верхнего уровня
Glob: "*" in target path

# Получить полное дерево PHP-файлов
Glob: "**/*.php" in target path

# Получить конфигурационные файлы
Glob: "{composer.json,*.yaml,*.yml,*.xml,*.neon,*.json}" in target path
```

### Шаг 2: Обнаружение фреймворка

| Фреймворк | Паттерн обнаружения | Ключевые файлы |
|-----------|---------------------|----------------|
| Symfony | `symfony/framework-bundle` в composer.json | `config/bundles.php`, `config/services.yaml` |
| Laravel | `laravel/framework` в composer.json | `artisan`, `app/Providers/` |
| Yii2 | `yiisoft/yii2` в composer.json | `config/web.php`, `config/console.php` |
| Slim | `slim/slim` в composer.json | `routes/`, `public/index.php` |
| Кастомный/Без фреймворка | Нет основного фреймворка | Только `composer.json` |

```bash
# Проверка composer.json на фреймворк
Grep: "symfony/framework-bundle|laravel/framework|yiisoft/yii2|slim/slim" in composer.json

# Проверка наличия Symfony bundles
Glob: "config/bundles.php"

# Проверка наличия Laravel artisan
Glob: "artisan"

# Проверка паттернов конфигурации фреймворков
Glob: "config/{services,bundles,web,console,app}.{php,yaml,yml}"
```

### Шаг 3: Определение слоёв

Обнаружение архитектурных слоёв по паттернам пространств имён и структуре каталогов:

#### Доменный слой

```bash
# Стандартные DDD-директории
Glob: "**/Domain/**/*.php"
Glob: "**/Model/**/*.php"
Glob: "**/Entity/**/*.php"

# Доменные компоненты
Grep: "namespace.*\\\\Domain\\\\" --glob "**/*.php"
Grep: "namespace.*\\\\Model\\\\" --glob "**/*.php"

# Маркеры домена
Grep: "interface.*Repository" --glob "**/*.php"
Grep: "class.*ValueObject|extends.*ValueObject" --glob "**/*.php"
Grep: "class.*AggregateRoot|extends.*AggregateRoot" --glob "**/*.php"
Grep: "class.*DomainEvent|extends.*DomainEvent" --glob "**/*.php"
```

#### Слой приложения

```bash
# Стандартные директории Application
Glob: "**/Application/**/*.php"
Glob: "**/UseCase/**/*.php"
Glob: "**/Service/**/*.php"

# Компоненты приложения
Grep: "namespace.*\\\\Application\\\\" --glob "**/*.php"
Grep: "namespace.*\\\\UseCase\\\\" --glob "**/*.php"

# Маркеры CQRS
Grep: "CommandHandler|QueryHandler|CommandBus|QueryBus" --glob "**/*.php"
Grep: "class.*Command\\b|class.*Query\\b" --glob "**/*.php"
```

#### Инфраструктурный слой

```bash
# Стандартные директории Infrastructure
Glob: "**/Infrastructure/**/*.php"
Glob: "**/Persistence/**/*.php"
Glob: "**/Adapter/**/*.php"

# Инфраструктурные компоненты
Grep: "namespace.*\\\\Infrastructure\\\\" --glob "**/*.php"
Grep: "implements.*Repository" --glob "**/*.php"

# Внешние интеграции
Grep: "Redis|RabbitMQ|Doctrine|Elasticsearch|Guzzle" --glob "**/*.php"
```

#### Слой представления

```bash
# Стандартные директории Presentation
Glob: "**/Controller/**/*.php"
Glob: "**/Action/**/*.php"
Glob: "**/Api/**/*.php"
Glob: "**/Console/**/*.php"

# Компоненты представления
Grep: "namespace.*\\\\(Controller|Action|Api|Console|Cli)\\\\" --glob "**/*.php"
Grep: "extends.*Controller|extends.*AbstractController" --glob "**/*.php"
Grep: "#\\[Route\\(|@Route" --glob "**/*.php"
```

### Шаг 4: Обнаружение модулей / ограниченных контекстов

```bash
# Обнаружение ограниченных контекстов (распространённые паттерны)
# Паттерн 1: src/{Context}/Domain|Application|Infrastructure
Glob: "src/*/Domain/"
Glob: "src/*/Application/"

# Паттерн 2: src/Domain/{Context}/
Glob: "src/Domain/*/"

# Паттерн 3: packages/{context}/
Glob: "packages/*/"

# Паттерн 4: modules/{context}/
Glob: "modules/*/"
```

### Шаг 5: Статистика файлов

Для каждого обнаруженного слоя подсчитать:
- Общее количество PHP-файлов
- Классы (ключевое слово class)
- Интерфейсы (ключевое слово interface)
- Абстрактные классы
- Перечисления (PHP 8.1+)
- Трейты

```bash
# Подсчёт по типу для каждой директории
Grep: "^(final |abstract |readonly )?class " --glob "**/*.php" in each layer
Grep: "^interface " --glob "**/*.php" in each layer
Grep: "^enum " --glob "**/*.php" in each layer
Grep: "^trait " --glob "**/*.php" in each layer
```

## Формат вывода

```markdown
## Карта структуры проекта

### Фреймворк
- **Фреймворк:** Symfony 6.4 / Laravel 11 / Кастомный
- **Версия PHP:** 8.4 (из composer.json require.php)
- **Тип:** Монолит / Модульный монолит / Микросервис

### Обзор слоёв

| Слой | Директория | Файлы | Классы | Интерфейсы | Перечисления |
|------|-----------|-------|--------|------------|-------------|
| Domain | src/Domain/ | 45 | 30 | 10 | 5 |
| Application | src/Application/ | 22 | 20 | 2 | 0 |
| Infrastructure | src/Infrastructure/ | 18 | 15 | 0 | 3 |
| Presentation | src/Api/, src/Console/ | 12 | 12 | 0 | 0 |

### Ограниченные контексты (при обнаружении)

| Контекст | Domain | Application | Infrastructure | Presentation |
|----------|--------|-------------|----------------|-------------|
| Order | 15 файлов | 8 файлов | 6 файлов | 4 файла |
| User | 10 файлов | 5 файлов | 4 файла | 3 файла |
| Payment | 8 файлов | 4 файла | 3 файла | 2 файла |

### Дерево каталогов
```
src/
├── Domain/
│   ├── Order/
│   │   ├── Entity/
│   │   ├── ValueObject/
│   │   ├── Event/
│   │   └── Repository/
│   └── User/
├── Application/
│   ├── Command/
│   ├── Query/
│   └── Service/
├── Infrastructure/
│   ├── Persistence/
│   └── Messaging/
└── Presentation/
    ├── Api/
    └── Console/
```

### Ключевые конфигурационные файлы
| Файл | Назначение |
|------|-----------|
| composer.json | Зависимости, автозагрузка |
| config/services.yaml | Конфигурация DI-контейнера |
| config/routes.yaml | Определения маршрутов |
```

## Ключевые индикаторы

### Классификация размера проекта

| Размер | Файлы | Описание |
|--------|-------|----------|
| Малый | < 50 | Один модуль или микросервис |
| Средний | 50-200 | Стандартное приложение |
| Большой | 200-500 | Сложный монолит |
| Очень большой | > 500 | Корпоративное приложение |

### Индикаторы здоровья слоёв

- **Domain > Infrastructure** = Хорошее следование DDD
- **Infrastructure > Domain** = Потенциальные проблемы связанности
- **Нет слоя Application** = Возможная утечка логики в контроллеры
- **Нет слоя Domain** = Паттерн Transaction Script

## Интеграция

Этот навык обеспечивает структурную основу для:
- `acc-identify-entry-points` — использует карту слоёв для поиска точек входа
- `acc-detect-architecture-pattern` — использует структуру для определения паттернов
- Все агенты анализа — используют карту слоёв для ограниченного анализа
