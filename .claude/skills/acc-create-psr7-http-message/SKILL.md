---
name: acc-create-psr7-http-message
description: Генерирует реализации PSR-7 HTTP Message для PHP 8.2. Создаёт классы Request, Response, Stream, Uri и ServerRequest с иммутабельностью. Включает модульные тесты.
---

# Генератор PSR-7 HTTP Message

## Обзор

Генерирует PSR-7-совместимые реализации HTTP-сообщений на основе интерфейсов `Psr\Http\Message`.

## Когда использовать

- Построение собственного HTTP-фреймворка
- Создание легковесной обработки HTTP-сообщений
- Необходимость иммутабельных объектов запроса/ответа
- Тестирование HTTP-взаимодействий

## Генерируемые компоненты

| Компонент | Интерфейс | Расположение |
|-----------|-----------|--------------|
| Request | `RequestInterface` | `src/Infrastructure/Http/Message/` |
| Response | `ResponseInterface` | `src/Infrastructure/Http/Message/` |
| ServerRequest | `ServerRequestInterface` | `src/Infrastructure/Http/Message/` |
| Stream | `StreamInterface` | `src/Infrastructure/Http/Message/` |
| Uri | `UriInterface` | `src/Infrastructure/Http/Message/` |
| UploadedFile | `UploadedFileInterface` | `src/Infrastructure/Http/Message/` |

## Краткий шаблон: Response

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Http\Message;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamInterface;

final readonly class Response implements ResponseInterface
{
    private const PHRASES = [
        200 => 'OK', 201 => 'Created', 204 => 'No Content',
        400 => 'Bad Request', 401 => 'Unauthorized', 403 => 'Forbidden',
        404 => 'Not Found', 500 => 'Internal Server Error',
    ];

    public function __construct(
        private int $statusCode = 200,
        private string $reasonPhrase = '',
        private array $headers = [],
        private StreamInterface $body = new Stream(''),
        private string $protocolVersion = '1.1',
    ) {}

    public function getStatusCode(): int { return $this->statusCode; }
    public function getReasonPhrase(): string { return $this->reasonPhrase; }
    public function getHeaders(): array { return $this->headers; }
    public function getBody(): StreamInterface { return $this->body; }

    public function withStatus(int $code, string $reasonPhrase = ''): static
    {
        return new self($code, $reasonPhrase ?: (self::PHRASES[$code] ?? ''),
            $this->headers, $this->body, $this->protocolVersion);
    }

    public function withHeader(string $name, $value): static
    {
        $headers = $this->headers;
        $headers[strtolower($name)] = is_array($value) ? $value : [$value];
        return new self($this->statusCode, $this->reasonPhrase, $headers,
            $this->body, $this->protocolVersion);
    }

    public function withBody(StreamInterface $body): static
    {
        return new self($this->statusCode, $this->reasonPhrase,
            $this->headers, $body, $this->protocolVersion);
    }

    // ... other MessageInterface methods
}
```

## Пример использования

```php
<?php

use App\Infrastructure\Http\Message\Response;
use App\Infrastructure\Http\Message\Stream;

// Create response
$response = new Response(200);
$response = $response
    ->withHeader('Content-Type', 'application/json')
    ->withBody(new Stream(json_encode(['status' => 'ok'])));

// Read response
echo $response->getStatusCode();           // 200
echo $response->getHeaderLine('Content-Type'); // application/json
echo (string) $response->getBody();        // {"status":"ok"}
```

## Требования

```json
{
    "require": {
        "psr/http-message": "^2.0"
    }
}
```

## См. также

- `references/templates.md` - Полные шаблоны Response, Stream, Uri, Request, ServerRequest, UploadedFile
- `references/examples.md` - Примеры интеграции
