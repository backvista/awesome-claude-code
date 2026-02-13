---
name: acc-create-action
description: Генерирует ADR Action классы для PHP 8.2. Создаёт обработчики HTTP-эндпоинтов с единственной ответственностью и поддержкой PSR-7. Включает юнит-тесты.
---

# Генератор Action

Генерация ADR-совместимых Action классов для HTTP-эндпоинтов.

## Характеристики Action

- **Единственная ответственность**: Один action = один HTTP-эндпоинт
- **Разбор ввода**: Сбор и разбор данных запроса
- **Вызов домена**: Вызывает UseCase/Handler
- **Делегирование ответа**: Передаёт результат в Responder
- **Без бизнес-логики**: Тонкий координационный слой
- **Invokable**: Единственный метод `__invoke()`

## Шаблон

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\{Context}\{Action};

use Application\{Context}\UseCase\{Action}\{Action}Command;
use Application\{Context}\UseCase\{Action}\{Action}Handler;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class {Action}Action
{
    public function __construct(
        private {Action}Handler $handler,
        private {Action}Responder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        {inputParsing}

        $command = new {Action}Command(
            {commandProperties}
        );

        $result = $this->handler->handle($command);

        return $this->responder->respond($result);
    }

    {privateMethods}
}
```

## Шаблон теста

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Presentation\Api\{Context}\{Action};

use Application\{Context}\UseCase\{Action}\{Action}Command;
use Application\{Context}\UseCase\{Action}\{Action}Handler;
use Application\{Context}\UseCase\{Action}\{Action}Result;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;
use Presentation\Api\{Context}\{Action}\{Action}Action;
use Presentation\Api\{Context}\{Action}\{Action}Responder;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Message\StreamInterface;

#[Group('unit')]
#[CoversClass({Action}Action::class)]
final class {Action}ActionTest extends TestCase
{
    private {Action}Handler $handler;
    private {Action}Responder $responder;
    private {Action}Action $action;

    protected function setUp(): void
    {
        $this->handler = $this->createMock({Action}Handler::class);
        $this->responder = $this->createMock({Action}Responder::class);
        $this->action = new {Action}Action($this->handler, $this->responder);
    }

    public function testInvokesHandlerWithCommand(): void
    {
        $request = $this->createRequest([{testData}]);

        $result = $this->createMock({Action}Result::class);
        $response = $this->createMock(ResponseInterface::class);

        $this->handler
            ->expects($this->once())
            ->method('handle')
            ->with($this->callback(fn ({Action}Command $cmd) =>
                {commandAssertions}
            ))
            ->willReturn($result);

        $this->responder
            ->expects($this->once())
            ->method('respond')
            ->with($result)
            ->willReturn($response);

        $actual = ($this->action)($request);

        self::assertSame($response, $actual);
    }

    private function createRequest(array $body): ServerRequestInterface
    {
        $stream = $this->createMock(StreamInterface::class);
        $request = $this->createMock(ServerRequestInterface::class);
        $request->method('getParsedBody')->willReturn($body);
        $request->method('getBody')->willReturn($stream);

        return $request;
    }
}
```

## Паттерны Action по HTTP-методу

### GET (Чтение одного)

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\GetById;

use Application\User\UseCase\GetUserById\GetUserByIdQuery;
use Application\User\UseCase\GetUserById\GetUserByIdHandler;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class GetUserByIdAction
{
    public function __construct(
        private GetUserByIdHandler $handler,
        private GetUserByIdResponder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $userId = $request->getAttribute('id');

        $query = new GetUserByIdQuery(userId: $userId);
        $result = $this->handler->handle($query);

        return $this->responder->respond($result);
    }
}
```

### GET (Список с пагинацией)

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\ListAll;

use Application\User\UseCase\ListUsers\ListUsersQuery;
use Application\User\UseCase\ListUsers\ListUsersHandler;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class ListUsersAction
{
    public function __construct(
        private ListUsersHandler $handler,
        private ListUsersResponder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();

        $query = new ListUsersQuery(
            page: (int) ($queryParams['page'] ?? 1),
            perPage: (int) ($queryParams['per_page'] ?? 20),
            search: $queryParams['search'] ?? null,
        );

        $result = $this->handler->handle($query);

        return $this->responder->respond($result);
    }
}
```

### POST (Создание)

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\Create;

use Application\User\UseCase\CreateUser\CreateUserCommand;
use Application\User\UseCase\CreateUser\CreateUserHandler;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class CreateUserAction
{
    public function __construct(
        private CreateUserHandler $handler,
        private CreateUserResponder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $body = (array) $request->getParsedBody();

        $command = new CreateUserCommand(
            email: $body['email'] ?? '',
            name: $body['name'] ?? '',
        );

        $result = $this->handler->handle($command);

        return $this->responder->respond($result);
    }
}
```

### PUT/PATCH (Обновление)

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\Update;

use Application\User\UseCase\UpdateUser\UpdateUserCommand;
use Application\User\UseCase\UpdateUser\UpdateUserHandler;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class UpdateUserAction
{
    public function __construct(
        private UpdateUserHandler $handler,
        private UpdateUserResponder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $userId = $request->getAttribute('id');
        $body = (array) $request->getParsedBody();

        $command = new UpdateUserCommand(
            userId: $userId,
            name: $body['name'] ?? null,
            email: $body['email'] ?? null,
        );

        $result = $this->handler->handle($command);

        return $this->responder->respond($result);
    }
}
```

### DELETE

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\Delete;

use Application\User\UseCase\DeleteUser\DeleteUserCommand;
use Application\User\UseCase\DeleteUser\DeleteUserHandler;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class DeleteUserAction
{
    public function __construct(
        private DeleteUserHandler $handler,
        private DeleteUserResponder $responder,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $userId = $request->getAttribute('id');

        $command = new DeleteUserCommand(userId: $userId);
        $result = $this->handler->handle($command);

        return $this->responder->respond($result);
    }
}
```

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Action | `src/Presentation/Api/{Context}/{Action}/{Action}Action.php` |
| Action Interface | `src/Presentation/Shared/Action/ActionInterface.php` |
| Тест | `tests/Unit/Presentation/Api/{Context}/{Action}/{Action}ActionTest.php` |

## Инструкции по генерации

При создании Action:

1. **Определить HTTP-метод** (GET, POST, PUT, DELETE)
2. **Определить источник ввода** (body, query params, route attributes)
3. **Определить Command/Query DTO** (что передать обработчику)
4. **Сгенерировать класс Action** с правильным namespace
5. **Сгенерировать тест** с замоканными зависимостями

## Соглашения об именовании

| HTTP-метод | Имя Action | Command/Query |
|------------|-----------|---------------|
| GET (один) | Get{Resource}ByIdAction | Get{Resource}ByIdQuery |
| GET (список) | List{Resource}sAction | List{Resource}sQuery |
| POST | Create{Resource}Action | Create{Resource}Command |
| PUT | Update{Resource}Action | Update{Resource}Command |
| PATCH | Patch{Resource}Action | Patch{Resource}Command |
| DELETE | Delete{Resource}Action | Delete{Resource}Command |

## Ссылки

Для подробных паттернов и примеров:

- `references/templates.md` — Дополнительные шаблоны Action
- `references/examples.md` — Реальные примеры Action
