---
name: acc-create-psr3-logger
description: Генерирует реализацию PSR-3 Logger для PHP 8.2. Создаёт реализации LoggerInterface с уровнями логирования, интерполяцией контекста и использованием LoggerAwareTrait. Включает модульные тесты.
---

# Генератор PSR-3 Logger

## Обзор

Генерирует PSR-3-совместимые реализации логгера на основе `Psr\Log\LoggerInterface`.

## Когда использовать

- Реализация собственных решений для логирования
- Создание логгеров, специфичных для приложения
- Построение адаптеров логирования для внешних сервисов
- Тестирование с mock/null-логгерами

## Генерируемые компоненты

| Компонент | Описание | Расположение |
|-----------|----------|--------------|
| Реализация логгера | Конкретный класс логгера | `src/Infrastructure/Logger/` |
| LoggerAware Trait | Для классов, нуждающихся в логгере | `src/Infrastructure/Logger/` |
| Null Logger | Логгер для тестирования/без операций | `src/Infrastructure/Logger/` |
| Модульные тесты | PHPUnit тесты | `tests/Unit/Infrastructure/Logger/` |

## Именование файлов

| Тип | Шаблон | Пример |
|-----|--------|--------|
| Файловый логгер | `{Name}Logger.php` | `FileLogger.php` |
| Потоковый логгер | `StreamLogger.php` | `StreamLogger.php` |
| Null-логгер | `NullLogger.php` | `NullLogger.php` |
| Trait | `LoggerAwareTrait.php` | `LoggerAwareTrait.php` |

## Шаблон: Файловый логгер

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Logger;

use DateTimeImmutable;
use Psr\Log\LoggerInterface;
use Psr\Log\LogLevel;
use Stringable;

final class FileLogger implements LoggerInterface
{
    private const DATE_FORMAT = 'Y-m-d H:i:s.u';

    public function __construct(
        private readonly string $logFile,
        private readonly string $minLevel = LogLevel::DEBUG,
    ) {
    }

    public function emergency(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::EMERGENCY, $message, $context);
    }

    public function alert(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::ALERT, $message, $context);
    }

    public function critical(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::CRITICAL, $message, $context);
    }

    public function error(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::ERROR, $message, $context);
    }

    public function warning(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::WARNING, $message, $context);
    }

    public function notice(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::NOTICE, $message, $context);
    }

    public function info(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::INFO, $message, $context);
    }

    public function debug(string|Stringable $message, array $context = []): void
    {
        $this->log(LogLevel::DEBUG, $message, $context);
    }

    public function log(mixed $level, string|Stringable $message, array $context = []): void
    {
        if (!$this->shouldLog($level)) {
            return;
        }

        $timestamp = (new DateTimeImmutable())->format(self::DATE_FORMAT);
        $interpolated = $this->interpolate((string) $message, $context);

        $entry = sprintf(
            "[%s] %s: %s%s\n",
            $timestamp,
            strtoupper($level),
            $interpolated,
            $this->formatContext($context),
        );

        file_put_contents($this->logFile, $entry, FILE_APPEND | LOCK_EX);
    }

    private function shouldLog(string $level): bool
    {
        $levels = [
            LogLevel::DEBUG => 0,
            LogLevel::INFO => 1,
            LogLevel::NOTICE => 2,
            LogLevel::WARNING => 3,
            LogLevel::ERROR => 4,
            LogLevel::CRITICAL => 5,
            LogLevel::ALERT => 6,
            LogLevel::EMERGENCY => 7,
        ];

        return ($levels[$level] ?? 0) >= ($levels[$this->minLevel] ?? 0);
    }

    private function interpolate(string $message, array $context): string
    {
        $replace = [];

        foreach ($context as $key => $value) {
            if (is_string($value) || $value instanceof Stringable) {
                $replace['{' . $key . '}'] = (string) $value;
            }
        }

        return strtr($message, $replace);
    }

    private function formatContext(array $context): string
    {
        if (empty($context)) {
            return '';
        }

        $filtered = array_filter(
            $context,
            fn($v) => !is_string($v) && !$v instanceof Stringable,
        );

        if (empty($filtered)) {
            return '';
        }

        return ' ' . json_encode($filtered, JSON_UNESCAPED_SLASHES);
    }
}
```

## Шаблон: Null-логгер

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Logger;

use Psr\Log\LoggerInterface;
use Stringable;

final readonly class NullLogger implements LoggerInterface
{
    public function emergency(string|Stringable $message, array $context = []): void
    {
    }

    public function alert(string|Stringable $message, array $context = []): void
    {
    }

    public function critical(string|Stringable $message, array $context = []): void
    {
    }

    public function error(string|Stringable $message, array $context = []): void
    {
    }

    public function warning(string|Stringable $message, array $context = []): void
    {
    }

    public function notice(string|Stringable $message, array $context = []): void
    {
    }

    public function info(string|Stringable $message, array $context = []): void
    {
    }

    public function debug(string|Stringable $message, array $context = []): void
    {
    }

    public function log(mixed $level, string|Stringable $message, array $context = []): void
    {
    }
}
```

## Шаблон: Logger Aware

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Logger;

use Psr\Log\LoggerInterface;

trait LoggerAwareTrait
{
    private ?LoggerInterface $logger = null;

    public function setLogger(LoggerInterface $logger): void
    {
        $this->logger = $logger;
    }

    protected function getLogger(): LoggerInterface
    {
        return $this->logger ?? new NullLogger();
    }
}
```

## Шаблон: Модульный тест

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Infrastructure\Logger;

use App\Infrastructure\Logger\FileLogger;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;
use Psr\Log\LogLevel;

#[Group('unit')]
#[CoversClass(FileLogger::class)]
final class FileLoggerTest extends TestCase
{
    private string $logFile;

    protected function setUp(): void
    {
        $this->logFile = sys_get_temp_dir() . '/test_' . uniqid() . '.log';
    }

    protected function tearDown(): void
    {
        if (file_exists($this->logFile)) {
            unlink($this->logFile);
        }
    }

    #[Test]
    public function it_logs_message_with_level(): void
    {
        $logger = new FileLogger($this->logFile);

        $logger->error('Test error message');

        $content = file_get_contents($this->logFile);
        self::assertStringContainsString('ERROR', $content);
        self::assertStringContainsString('Test error message', $content);
    }

    #[Test]
    public function it_interpolates_context_placeholders(): void
    {
        $logger = new FileLogger($this->logFile);

        $logger->info('User {username} logged in', ['username' => 'john']);

        $content = file_get_contents($this->logFile);
        self::assertStringContainsString('User john logged in', $content);
    }

    #[Test]
    public function it_respects_minimum_log_level(): void
    {
        $logger = new FileLogger($this->logFile, LogLevel::ERROR);

        $logger->debug('Debug message');
        $logger->info('Info message');
        $logger->error('Error message');

        $content = file_get_contents($this->logFile);
        self::assertStringNotContainsString('Debug message', $content);
        self::assertStringNotContainsString('Info message', $content);
        self::assertStringContainsString('Error message', $content);
    }

    #[Test]
    public function it_includes_context_in_log(): void
    {
        $logger = new FileLogger($this->logFile);

        $logger->error('Error occurred', ['code' => 500, 'trace' => 'stack']);

        $content = file_get_contents($this->logFile);
        self::assertStringContainsString('500', $content);
    }
}
```

## Примеры использования

### Базовое логирование

```php
<?php

use App\Infrastructure\Logger\FileLogger;
use Psr\Log\LogLevel;

$logger = new FileLogger('/var/log/app.log', LogLevel::INFO);

$logger->info('Application started');
$logger->error('Something went wrong', ['exception' => $e->getMessage()]);
```

### С интерполяцией контекста

```php
<?php

$logger->info('User {user_id} performed {action}', [
    'user_id' => 123,
    'action' => 'login',
    'ip' => '192.168.1.1',
]);
// Output: User 123 performed login {"ip":"192.168.1.1"}
```

### Сервис с поддержкой логгера

```php
<?php

declare(strict_types=1);

namespace App\Application\User\Handler;

use App\Infrastructure\Logger\LoggerAwareTrait;
use Psr\Log\LoggerAwareInterface;

final class CreateUserHandler implements LoggerAwareInterface
{
    use LoggerAwareTrait;

    public function __invoke(CreateUserCommand $command): void
    {
        $this->getLogger()->info('Creating user', ['email' => $command->email]);

        // ... create user

        $this->getLogger()->info('User created successfully');
    }
}
```

## Требования

```json
{
    "require": {
        "psr/log": "^3.0"
    }
}
```

## См. также

- `references/templates.md` - Дополнительные реализации логгера
- `references/examples.md` - Примеры использования в реальных проектах
