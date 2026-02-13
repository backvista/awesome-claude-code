---
name: acc-adr-knowledge
description: База знаний о паттерне Action-Domain-Responder. Предоставляет паттерны, антипаттерны и рекомендации для PHP по аудиту ADR (веб-специфичная альтернатива MVC).
---

# База знаний ADR

Краткий справочник по паттерну Action-Domain-Responder и рекомендациям для PHP-реализации.

## Основные принципы

### Компоненты ADR

```
HTTP Request → Action (собирает входные данные)
                 ↓
              Domain (выполняет бизнес-логику)
                 ↓
             Responder (строит HTTP Response)
                 ↓
           HTTP Response
```

**Правило:** Один action = один HTTP endpoint. Responder строит ПОЛНЫЙ response.

### Ответственность компонентов

| Компонент | Ответственность | Содержит |
|-----------|----------------|----------|
| **Action** | Собирает входные данные, вызывает Domain, передаёт в Responder | Парсинг запроса, создание DTO, вызов UseCase |
| **Domain** | Бизнес-логика (то же, что DDD Domain/Application) | Entities, Value Objects, UseCases, Services |
| **Responder** | Строит HTTP Response (статус, заголовки, тело) | Построение ответа, рендеринг шаблонов, content negotiation |

## Сравнение ADR vs MVC

| Аспект | MVC Controller | ADR Action |
|--------|----------------|------------|
| Детализация | Несколько действий | Одно действие на класс |
| Построение ответа | Смешано в контроллере | Отдельный класс Responder |
| HTTP-аспекты | Разбросаны | Изолированы в Responder |
| Тестируемость | Ниже (много обязанностей) | Выше (единая ответственность) |
| Структура файлов | Мало больших файлов | Много сфокусированных файлов |

## Чек-листы

### Чек-лист Action

- [ ] Единственный метод `__invoke()`
- [ ] Нет `new Response()` или построения ответа
- [ ] Нет бизнес-логики (if/switch по состоянию домена)
- [ ] Только парсинг входных данных и вызов домена
- [ ] Возвращает результат Responder

### Чек-лист Responder

- [ ] Получает только результат из домена
- [ ] Строит полный HTTP Response
- [ ] Обрабатывает content negotiation
- [ ] Устанавливает коды статуса на основе результата
- [ ] Нет domain/бизнес-логики
- [ ] Нет доступа к БД/repository

### Чек-лист Domain

- [ ] То же, что DDD Domain/Application слои
- [ ] Нет HTTP/Response-аспектов
- [ ] Возвращает доменные объекты (не HTTP-ответы)
- [ ] Чистая бизнес-логика

## Краткий справочник по нарушениям

| Нарушение | Где искать | Критичность |
|-----------|---------------|----------|
| `new Response()` в Action | *Action.php | Critical |
| `->withStatus()` в Action | *Action.php | Critical |
| `if ($result->isError())` в Action | *Action.php | Warning |
| `$repository->` в Responder | *Responder.php | Critical |
| `$service->` в Responder | *Responder.php | Critical |
| Несколько публичных методов в Action | *Action.php | Warning |
| Логика шаблонов в Action | *Action.php | Warning |

## Паттерны PHP 8.2 для ADR

### Паттерн Action

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\Create;

use Application\User\UseCase\CreateUser\CreateUserUseCase;
use Application\User\UseCase\CreateUser\CreateUserInput;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class CreateUserAction
{
    public function __construct(
        private CreateUserUseCase $useCase,
        private CreateUserResponder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $input = $this->parseInput($request);
        $result = $this->useCase->execute($input);

        return $this->responder->respond($result);
    }

    private function parseInput(ServerRequestInterface $request): CreateUserInput
    {
        $body = (array) $request->getParsedBody();

        return new CreateUserInput(
            email: $body['email'] ?? '',
            name: $body['name'] ?? '',
        );
    }
}
```

### Паттерн Responder

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\Create;

use Application\User\UseCase\CreateUser\CreateUserResult;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;

final readonly class CreateUserResponder
{
    public function __construct(
        private ResponseFactoryInterface $responseFactory,
        private StreamFactoryInterface $streamFactory,
    ) {
    }

    public function respond(CreateUserResult $result): ResponseInterface
    {
        if ($result->isFailure()) {
            return $this->error($result->error());
        }

        return $this->success($result->userId());
    }

    private function success(string $userId): ResponseInterface
    {
        return $this->json(['id' => $userId], 201);
    }

    private function error(string $message): ResponseInterface
    {
        return $this->json(['error' => $message], 400);
    }

    private function json(array $data, int $status): ResponseInterface
    {
        $body = $this->streamFactory->createStream(
            json_encode($data, JSON_THROW_ON_ERROR)
        );

        return $this->responseFactory->createResponse($status)
            ->withHeader('Content-Type', 'application/json')
            ->withBody($body);
    }
}
```

## Паттерны обнаружения

### Обнаружение Action

```bash
# Поиск классов Action
Glob: **/*Action.php
Glob: **/Action/**/*.php
Grep: "implements.*ActionInterface|extends.*Action" --glob "**/*.php"

# Обнаружение использования паттерна Action
Grep: "public function __invoke.*Request" --glob "**/*Action.php"
```

### Обнаружение Responder

```bash
# Поиск классов Responder
Glob: **/*Responder.php
Glob: **/Responder/**/*.php
Grep: "implements.*ResponderInterface" --glob "**/*.php"

# Обнаружение использования паттерна Responder
Grep: "public function respond" --glob "**/*Responder.php"
```

### Обнаружение нарушений

```bash
# Построение ответа в Action (Critical)
Grep: "new Response|->withStatus|->withHeader|->withBody" --glob "**/*Action.php"

# Бизнес-логика в Action (Warning)
Grep: "if \(.*->status|switch \(|->isValid\(\)" --glob "**/*Action.php"

# Вызовы домена в Responder (Critical)
Grep: "Repository|Service|UseCase" --glob "**/*Responder.php"

# Несколько публичных методов в Action (Warning)
Grep: "public function [^_]" --glob "**/*Action.php" | wc -l
```

## Структура файлов

### Рекомендуемая структура

```
src/
├── Presentation/
│   ├── Api/
│   │   └── {Context}/
│   │       └── {Action}/
│   │           ├── {Action}Action.php
│   │           ├── {Action}Responder.php
│   │           └── {Action}Request.php (опциональный DTO)
│   ├── Web/
│   │   └── {Context}/
│   │       └── {Action}/
│   │           ├── {Action}Action.php
│   │           ├── {Action}Responder.php
│   │           └── templates/ (для HTML)
│   └── Shared/
│       ├── Action/
│       │   └── ActionInterface.php
│       └── Responder/
│           └── ResponderInterface.php
├── Application/
│   └── {Context}/
│       └── UseCase/
│           └── {Action}/
│               ├── {Action}UseCase.php
│               ├── {Action}Input.php
│               └── {Action}Result.php
└── Domain/
    └── ...
```

### Альтернативная структура (Feature-Based)

```
src/
├── User/
│   ├── Presentation/
│   │   ├── CreateUser/
│   │   │   ├── CreateUserAction.php
│   │   │   └── CreateUserResponder.php
│   │   └── GetUser/
│   │       ├── GetUserAction.php
│   │       └── GetUserResponder.php
│   ├── Application/
│   │   └── ...
│   └── Domain/
│       └── ...
```

## Интеграция с DDD

ADR естественно сочетается с DDD-слоями:

| ADR | DDD-слой | Примечания |
|-----|-----------|-------|
| Action | Presentation | Точка входа для HTTP |
| Responder | Presentation | Точка выхода для HTTP |
| Domain | Domain + Application | Бизнес-логика через UseCases |

## Интеграция с PSR

ADR работает с PSR-7/PSR-15:

| PSR | Использование |
|-----|-------|
| PSR-7 | Интерфейсы Request/Response |
| PSR-15 | Middleware для сквозных задач |
| PSR-17 | Фабрики Response/Stream в Responder |

## Антипаттерны

### 1. Толстый Action (Critical)

```php
// ПЛОХО: Action делает слишком много
class CreateUserAction
{
    public function __invoke(Request $request): Response
    {
        $data = $request->getParsedBody();

        // Валидация в Action
        if (empty($data['email'])) {
            return new Response(400, [], 'Email required');
        }

        // Бизнес-логика в Action
        $user = new User($data['email']);
        $this->repository->save($user);

        // Построение ответа в Action
        return new Response(201, [], json_encode(['id' => $user->id()]));
    }
}
```

### 2. Анемичный Responder (Warning)

```php
// ПЛОХО: Responder не выполняет свою работу
class CreateUserResponder
{
    public function respond($data): Response
    {
        return new Response(200, [], json_encode($data));
    }
}
```

### 3. Умный Responder (Critical)

```php
// ПЛОХО: Responder с бизнес-логикой
class CreateUserResponder
{
    public function respond(User $user): Response
    {
        // Доменная логика в Responder!
        if ($user->isAdmin()) {
            $this->notificationService->notifyAdmins();
        }

        return $this->json(['id' => $user->id()], 201);
    }
}
```

## Справочные материалы

Для детальной информации загрузите эти справочные файлы:

- `references/action-patterns.md` — паттерны и лучшие практики классов Action
- `references/responder-patterns.md` — паттерны классов Responder
- `references/domain-integration.md` — интеграция с DDD Domain слоем
- `references/mvc-comparison.md` — детальное сравнение MVC vs ADR
- `references/antipatterns.md` — распространённые нарушения ADR с примерами

## Ресурсы

- `assets/report-template.md` — шаблон отчёта ADR-аудита
