---
name: acc-resolve-entry-point
description: Разрешает HTTP-маршруты (GET /api/orders) и консольные команды (app:process-payments) в файлы-обработчики. Определяет фреймворк, ищет определения маршрутов/команд, извлекает класс и метод обработчика, находит файл через PSR-4 маппинг.
---

# Резолвер точек входа

## Обзор

Разрешает пользовательские HTTP-маршруты или консольные команды в их файлы-обработчики. По заданному маршруту, например `POST /api/orders`, или команде `app:process-payments`, находит точный класс обработчика, метод, путь к файлу и окружающий контекст (middleware, определение маршрута, расписание).

## Типы входных данных

### HTTP-маршрут

```
Pattern: ^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+/
Examples:
  GET /api/orders
  POST /api/orders/{id}/status
  DELETE /api/users/{id}
```

### Консольная команда

```
Pattern: ^[a-z][a-z0-9_-]*:[a-z][a-z0-9:_-]*$
Examples:
  app:process-payments
  import:products
  cache:clear
```

## Процесс разрешения

### Шаг 1: Определить фреймворк

```bash
# Проверка Symfony
Glob: "config/bundles.php"
Grep: "symfony/framework-bundle" --glob "composer.json"

# Проверка Laravel
Glob: "artisan"
Grep: "laravel/framework" --glob "composer.json"

# Проверка Slim
Grep: "slim/slim" --glob "composer.json"

# Fallback: generic PHP (маршрутизация на атрибутах)
```

### Шаг 2: Разрешить HTTP-маршрут

#### Извлечение HTTP-метода и пути из входных данных

```
Input: "POST /api/orders/{id}/status"
Method: POST
Path: /api/orders/{id}/status
Path pattern (regex-escaped): /api/orders/\{[^}]+\}/status
Path pattern (simplified): /api/orders/.*/status
```

#### Разрешение маршрутов Symfony

```bash
# 1. Поиск маршрутов в PHP-атрибутах
Grep: "#\[Route\(" --glob "**/*.php" --output_mode content

# Затем фильтрация по совпадению пути:
# Поиск точного пути или пути с заполнителями параметров
Grep: "#\[Route\(['\"][^'\"]*(/api/orders)" --glob "**/*.php" --output_mode content

# 2. Поиск определений маршрутов в YAML
Grep: "path:\s.*(/api/orders)" --glob "config/routes*.yaml" --output_mode content
Grep: "path:\s.*(/api/orders)" --glob "config/routes/**/*.yaml" --output_mode content

# 3. Поиск определений маршрутов в XML
Grep: "path=\"[^\"]*(/api/orders)" --glob "config/routes*.xml" --output_mode content

# 4. Проверка ограничения по методу
# В найденном атрибуте маршрута проверить параметр methods
Grep: "methods:\s*\[.*POST" in matched file --output_mode content
```

#### Разрешение маршрутов Laravel

```bash
# 1. Поиск в файлах маршрутов
Grep: "Route::(post|any)\(\s*['\"]/?api/orders" --glob "routes/*.php" --output_mode content

# 2. Поиск ресурсных маршрутов
Grep: "Route::apiResource\(['\"]orders" --glob "routes/*.php" --output_mode content
Grep: "Route::resource\(['\"]orders" --glob "routes/*.php" --output_mode content

# 3. Поиск аннотаций контроллеров
Grep: "#\[Route\(" --glob "app/Http/Controllers/**/*.php" --output_mode content
```

#### Универсальное / атрибутное разрешение

```bash
# Поиск во всех PHP-файлах атрибутов маршрутов, совпадающих с путём
Grep: "#\[Route\(['\"][^'\"]*(/api/orders)" --glob "**/*.php" --output_mode content

# Поиск определений маршрутов в стиле Slim
Grep: "->(post|get|put|delete|patch)\(\s*['\"]/?api/orders" --glob "**/*.php" --output_mode content
```

### Шаг 3: Разрешить консольную команду

#### Разрешение команд Symfony

```bash
# 1. Поиск атрибута AsCommand
Grep: "#\[AsCommand\(['\"]app:process-payments" --glob "**/*.php" --output_mode content

# 2. Поиск свойства $defaultName
Grep: "\\\$defaultName\s*=\s*['\"]app:process-payments" --glob "**/*.php" --output_mode content

# 3. Поиск setName() в методе configure()
Grep: "setName\(['\"]app:process-payments" --glob "**/*.php" --output_mode content

# 4. Поиск тега команды в services.yaml
Grep: "console.command" --glob "config/services*.yaml" --output_mode content
```

#### Разрешение команд Laravel

```bash
# 1. Поиск свойства $signature
Grep: "\\\$signature\s*=\s*['\"]app:process-payments" --glob "**/*.php" --output_mode content

# 2. Поиск свойства $name
Grep: "\\\$name\s*=\s*['\"]app:process-payments" --glob "**/*.php" --output_mode content

# 3. Поиск регистрации команд в Kernel
Grep: "app:process-payments" --glob "app/Console/Kernel.php" --output_mode content
```

#### Универсальное разрешение

```bash
# Поиск любого PHP-файла, содержащего имя команды как строку
Grep: "['\"]app:process-payments['\"]" --glob "**/*.php" --output_mode content
```

### Шаг 4: Извлечение деталей обработчика

После нахождения файла с определением маршрута/команды:

```bash
# Прочитать файл, содержащий определение маршрута/команды
Read: matched_file

# Извлечь имя класса и пространство имён
Grep: "^namespace\s+" in matched_file --output_mode content
Grep: "^class\s+" in matched_file --output_mode content

# Для маршрута: извлечь метод обработчика
# - Если у класса есть __invoke → метод __invoke
# - Если атрибут маршрута на конкретном методе → этот метод
# - Если файл маршрута указывает на Controller@method → извлечь метод

# Для команды: метод обработчика — execute() (Symfony) или handle() (Laravel)
```

### Шаг 5: Найти файл обработчика через PSR-4

Если определение маршрута ссылается на другой класс обработчика:

```bash
# Прочитать composer.json для PSR-4 автозагрузки
Read: composer.json → извлечь секцию autoload.psr-4

# Преобразовать пространство имён в путь
# Пример: App\Api\Action\CreateOrderAction
# PSR-4: "App\\" => "src/"
# Путь: src/Api/Action/CreateOrderAction.php

# Проверить существование файла
Glob: "src/Api/Action/CreateOrderAction.php"
```

### Шаг 6: Извлечение Middleware / контекста

#### Для HTTP-маршрутов

```bash
# Symfony: поиск middleware (слушатели событий kernel.request)
Grep: "kernel.request|kernel.controller" --glob "**/*.php" --output_mode content

# Проверка middleware на уровне маршрута в атрибутах
Grep: "#\[IsGranted\(|#\[Security\(" in handler file --output_mode content

# Laravel: проверка middleware в определении маршрута
Grep: "->middleware\(" in route definition context --output_mode content

# Проверка middleware в конструкторе контроллера
Grep: "\$this->middleware\(" in handler file --output_mode content
```

#### Для консольных команд

```bash
# Проверка наличия команды в расписании
# Symfony
Grep: "app:process-payments" --glob "config/scheduler*.{php,yaml}" --output_mode content
Grep: "RecurringMessage" --glob "**/*.php" --output_mode content

# Laravel
Grep: "app:process-payments" --glob "app/Console/Kernel.php" --output_mode content
Grep: "schedule\(" --glob "routes/console.php" --output_mode content
```

## Формат вывода

### Разрешение HTTP-маршрута

```markdown
## Разрешённая точка входа

| Поле | Значение |
|------|----------|
| Тип | HTTP-маршрут |
| Ввод | POST /api/orders |
| Обработчик | App\Api\Action\CreateOrderAction::__invoke |
| Файл | src/Api/Action/CreateOrderAction.php |
| Определение маршрута | config/routes/api.yaml:15 |
| HTTP-метод | POST |
| Путь | /api/orders |
| Параметры пути | — |
| Middleware | auth, json-body |
| Авторизация | #[IsGranted('ROLE_USER')] |
| Фреймворк | Symfony 7.x |

### Цепочка обработки
Определение маршрута → Middleware (auth, json) → CreateOrderAction::__invoke → CreateOrderUseCase
```

### Разрешение консольной команды

```markdown
## Разрешённая точка входа

| Поле | Значение |
|------|----------|
| Тип | Консольная команда |
| Ввод | app:process-payments |
| Обработчик | App\Console\Command\ProcessPaymentsCommand::execute |
| Файл | src/Console/Command/ProcessPaymentsCommand.php |
| Определение команды | #[AsCommand('app:process-payments')] |
| Аргументы | --batch-size (необязательный, по умолчанию: 100) |
| Расписание | Ежедневно в 02:00 (config/scheduler.php) |
| Фреймворк | Symfony 7.x |

### Цепочка выполнения
Расписание/Ручной запуск → ProcessPaymentsCommand::execute → ProcessPaymentUseCase
```

### Разрешение не удалось

```markdown
## Разрешение не удалось

| Поле | Значение |
|------|----------|
| Ввод | GET /api/nonexistent |
| Тип | HTTP-маршрут |
| Фреймворк | Symfony 7.x |

### Результаты поиска
Совпадающее определение маршрута не найдено.

### Рекомендации
1. Проверьте доступные маршруты: `php bin/console debug:router | grep api`
2. Убедитесь в правильности пути маршрута (регистрозависимый)
3. Маршрут может быть определён динамически или через импортированный bundle
4. Попробуйте поиск с более широким путём: `/acc-explain GET /api/`
```

## Множественные совпадения

Когда найдено несколько обработчиков (например, версионированные API, переопределения маршрутов):

```markdown
## Разрешённые точки входа (множественные совпадения)

### Совпадение 1 (основное)
| Поле | Значение |
|------|----------|
| Обработчик | App\Api\V2\CreateOrderAction |
| Файл | src/Api/V2/CreateOrderAction.php |
| Маршрут | config/routes/api_v2.yaml:8 |

### Совпадение 2
| Поле | Значение |
|------|----------|
| Обработчик | App\Api\V1\CreateOrderAction |
| Файл | src/Api/V1/CreateOrderAction.php |
| Маршрут | config/routes/api_v1.yaml:12 |

**Примечание:** Найдено несколько обработчиков. Используется Совпадение 1 (наиболее свежее/специфичное определение).
```

## Обработка параметров пути

При разрешении маршрутов с параметрами:

```
Input: GET /api/orders/{id}/items
Паттерны поиска:
  1. Точный: /api/orders/{id}/items
  2. Regex-атрибут: /api/orders/\{[^}]+\}/items
  3. Упрощённый: orders.*items (fallback)
```

## Интеграция

Этот навык используется:
- `acc-codebase-navigator` — разрешает пользовательские маршруты/команды в файлы обработчиков перед навигацией
- `acc-explain-coordinator` — Фаза 0 разрешения для типов ввода маршрутов/команд
