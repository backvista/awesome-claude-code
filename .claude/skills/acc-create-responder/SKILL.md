---
name: acc-create-responder
description: Генерирует классы ADR Responder для PHP 8.2. Создаёт билдеры HTTP-ответов с поддержкой PSR-7/PSR-17. Включает модульные тесты.
---

# Генератор Responder

Генерирует ADR-совместимые классы Responder для построения HTTP-ответов.

## Характеристики Responder

- **Построение ответа**: Создаёт полный HTTP Response (статус, заголовки, тело)
- **Без бизнес-логики**: Только форматирование и преобразование данных
- **Без доступа к домену**: Без вызовов репозиториев или сервисов
- **Маппинг ошибок**: Отображает доменные ошибки в HTTP-статусы
- **Content Type**: Устанавливает соответствующий заголовок Content-Type
- **Соответствие PSR**: Использует интерфейсы PSR-7 и PSR-17

## Шаблон

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\{Context}\{Action};

use Application\{Context}\UseCase\{Action}\{Action}Result;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;

final readonly class {Action}Responder
{
    public function __construct(
        private ResponseFactoryInterface $responseFactory,
        private StreamFactoryInterface $streamFactory,
    ) {
    }

    public function respond({Action}Result $result): ResponseInterface
    {
        if ($result->isFailure()) {
            return $this->handleFailure($result);
        }

        return $this->success($result);
    }

    private function success({Action}Result $result): ResponseInterface
    {
        {successResponse}
    }

    private function handleFailure({Action}Result $result): ResponseInterface
    {
        return match ($result->failureReason()) {
            {errorMapping}
            default => $this->badRequest($result->errorMessage()),
        };
    }

    private function json(array $data, int $status = 200): ResponseInterface
    {
        $body = $this->streamFactory->createStream(
            json_encode($data, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE)
        );

        return $this->responseFactory->createResponse($status)
            ->withHeader('Content-Type', 'application/json; charset=utf-8')
            ->withBody($body);
    }

    {helperMethods}
}
```

## Шаблон теста

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Presentation\Api\{Context}\{Action};

use Application\{Context}\UseCase\{Action}\{Action}Result;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;
use Presentation\Api\{Context}\{Action}\{Action}Responder;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;
use Psr\Http\Message\StreamInterface;

#[Group('unit')]
#[CoversClass({Action}Responder::class)]
final class {Action}ResponderTest extends TestCase
{
    private ResponseFactoryInterface $responseFactory;
    private StreamFactoryInterface $streamFactory;
    private {Action}Responder $responder;

    protected function setUp(): void
    {
        $this->responseFactory = $this->createMock(ResponseFactoryInterface::class);
        $this->streamFactory = $this->createMock(StreamFactoryInterface::class);
        $this->responder = new {Action}Responder(
            $this->responseFactory,
            $this->streamFactory,
        );

        $this->setupMocks();
    }

    public function testSuccessReturns{ExpectedStatus}(): void
    {
        $result = {Action}Result::success({successData});

        $response = $this->responder->respond($result);

        self::assertSame({expectedStatusCode}, $response->getStatusCode());
    }

    {failureTests}

    private function setupMocks(): void
    {
        $stream = $this->createMock(StreamInterface::class);
        $this->streamFactory->method('createStream')->willReturn($stream);

        $response = $this->createMock(ResponseInterface::class);
        $response->method('withHeader')->willReturnSelf();
        $response->method('withBody')->willReturnSelf();
        $response->method('getStatusCode')->willReturnCallback(
            fn () => $this->responseFactory->lastStatus ?? 200
        );

        $this->responseFactory->method('createResponse')->willReturnCallback(
            function (int $status) use ($response) {
                $this->responseFactory->lastStatus = $status;
                $mock = clone $response;
                $mock->method('getStatusCode')->willReturn($status);
                return $mock;
            }
        );
    }
}
```

## Паттерны Responder

### Create Responder (201)

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
            return match ($result->failureReason()) {
                'email_exists' => $this->conflict('User with this email already exists'),
                'invalid_email' => $this->badRequest('Invalid email format'),
                default => $this->badRequest($result->errorMessage()),
            };
        }

        return $this->created([
            'id' => $result->userId(),
            'email' => $result->email(),
        ]);
    }

    private function created(array $data): ResponseInterface
    {
        return $this->json($data, 201);
    }

    private function conflict(string $message): ResponseInterface
    {
        return $this->json(['error' => $message], 409);
    }

    private function badRequest(string $message): ResponseInterface
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

### Get Responder (200/404)

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\GetById;

use Application\User\UseCase\GetUserById\GetUserByIdResult;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;

final readonly class GetUserByIdResponder
{
    public function __construct(
        private ResponseFactoryInterface $responseFactory,
        private StreamFactoryInterface $streamFactory,
    ) {
    }

    public function respond(GetUserByIdResult $result): ResponseInterface
    {
        if ($result->isNotFound()) {
            return $this->notFound('User not found');
        }

        $user = $result->user();

        return $this->json([
            'id' => $user->id()->toString(),
            'email' => $user->email()->value(),
            'name' => $user->name(),
            'created_at' => $user->createdAt()->format('c'),
        ]);
    }

    private function notFound(string $message): ResponseInterface
    {
        return $this->json(['error' => $message], 404);
    }

    private function json(array $data, int $status = 200): ResponseInterface
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

### List Responder с пагинацией

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\ListAll;

use Application\User\UseCase\ListUsers\ListUsersResult;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;

final readonly class ListUsersResponder
{
    public function __construct(
        private ResponseFactoryInterface $responseFactory,
        private StreamFactoryInterface $streamFactory,
    ) {
    }

    public function respond(ListUsersResult $result): ResponseInterface
    {
        $users = array_map(
            fn ($user) => [
                'id' => $user->id()->toString(),
                'email' => $user->email()->value(),
                'name' => $user->name(),
            ],
            $result->users()
        );

        return $this->json([
            'data' => $users,
            'meta' => [
                'total' => $result->total(),
                'page' => $result->page(),
                'per_page' => $result->perPage(),
                'total_pages' => $result->totalPages(),
            ],
        ]);
    }

    private function json(array $data, int $status = 200): ResponseInterface
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

### Delete Responder (204)

```php
<?php

declare(strict_types=1);

namespace Presentation\Api\User\Delete;

use Application\User\UseCase\DeleteUser\DeleteUserResult;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;

final readonly class DeleteUserResponder
{
    public function __construct(
        private ResponseFactoryInterface $responseFactory,
        private StreamFactoryInterface $streamFactory,
    ) {
    }

    public function respond(DeleteUserResult $result): ResponseInterface
    {
        if ($result->isNotFound()) {
            return $this->notFound('User not found');
        }

        if ($result->isFailure()) {
            return $this->badRequest($result->errorMessage());
        }

        return $this->noContent();
    }

    private function noContent(): ResponseInterface
    {
        return $this->responseFactory->createResponse(204);
    }

    private function notFound(string $message): ResponseInterface
    {
        return $this->json(['error' => $message], 404);
    }

    private function badRequest(string $message): ResponseInterface
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

## Маппинг HTTP-статусов

| Доменное условие | HTTP-статус | Метод |
|------------------|-------------|-------|
| Успех (создание) | 201 | `created()` |
| Успех (чтение) | 200 | `json()` |
| Успех (обновление) | 200 | `json()` |
| Успех (удаление) | 204 | `noContent()` |
| Не найдено | 404 | `notFound()` |
| Уже существует | 409 | `conflict()` |
| Ошибка валидации | 422 | `unprocessableEntity()` |
| Некорректный ввод | 400 | `badRequest()` |
| Не авторизован | 401 | `unauthorized()` |
| Запрещено | 403 | `forbidden()` |

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Responder | `src/Presentation/Api/{Context}/{Action}/{Action}Responder.php` |
| Интерфейс | `src/Presentation/Shared/Responder/ResponderInterface.php` |
| Абстрактный класс | `src/Presentation/Shared/Responder/AbstractJsonResponder.php` |
| Тест | `tests/Unit/Presentation/Api/{Context}/{Action}/{Action}ResponderTest.php` |

## Инструкции по генерации

При создании Responder:

1. **Определите тип операции** (create, read, update, delete)
2. **Определите статус успеха** (201, 200, 204)
3. **Перечислите возможные ошибки** и их HTTP-коды
4. **Определите структуру ответа** (какие данные возвращать)
5. **Сгенерируйте класс Responder** с правильным namespace
6. **Сгенерируйте тест** для каждого пути HTTP-статуса

## Соглашения об именовании

| HTTP-метод | Имя Responder | Статус успеха |
|------------|---------------|---------------|
| GET (единичный) | Get{Resource}ByIdResponder | 200 |
| GET (список) | List{Resource}sResponder | 200 |
| POST | Create{Resource}Responder | 201 |
| PUT | Update{Resource}Responder | 200 |
| PATCH | Patch{Resource}Responder | 200 |
| DELETE | Delete{Resource}Responder | 204 |

## Ссылки

Подробные паттерны и примеры:

- `references/templates.md` — Дополнительные шаблоны Responder
- `references/examples.md` — Примеры Responder из реальных проектов
