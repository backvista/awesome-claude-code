---
name: acc-create-psr20-clock
description: Генерирует реализацию PSR-20 Clock для PHP 8.2. Создаёт реализации ClockInterface, включая SystemClock, FrozenClock и OffsetClock для абстракции времени и тестирования. Включает модульные тесты.
---

# Генератор PSR-20 Clock

## Обзор

Генерирует PSR-20-совместимые реализации часов для абстракции времени.

## Когда использовать

- Бизнес-логика, зависящая от времени
- Тестирование кода, чувствительного к времени
- Планирование и расчёты с временем
- Воспроизводимое поведение по времени

## Шаблон: Интерфейс Clock

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Clock;

use DateTimeImmutable;

interface ClockInterface
{
    public function now(): DateTimeImmutable;
}
```

## Шаблон: Системные часы

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Clock;

use DateTimeImmutable;
use Psr\Clock\ClockInterface;

final readonly class SystemClock implements ClockInterface
{
    public function __construct(
        private ?string $timezone = null,
    ) {
    }

    public function now(): DateTimeImmutable
    {
        $now = new DateTimeImmutable('now');

        if ($this->timezone !== null) {
            return $now->setTimezone(new \DateTimeZone($this->timezone));
        }

        return $now;
    }
}
```

## Шаблон: Замороженные часы (для тестирования)

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Clock;

use DateTimeImmutable;
use Psr\Clock\ClockInterface;

final class FrozenClock implements ClockInterface
{
    public function __construct(
        private DateTimeImmutable $frozenAt,
    ) {
    }

    public function now(): DateTimeImmutable
    {
        return $this->frozenAt;
    }

    public function setTo(DateTimeImmutable $dateTime): void
    {
        $this->frozenAt = $dateTime;
    }

    public static function at(string $datetime): self
    {
        return new self(new DateTimeImmutable($datetime));
    }

    public static function fromTimestamp(int $timestamp): self
    {
        return new self((new DateTimeImmutable())->setTimestamp($timestamp));
    }
}
```

## Шаблон: Часы со смещением

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Clock;

use DateInterval;
use DateTimeImmutable;
use Psr\Clock\ClockInterface;

final readonly class OffsetClock implements ClockInterface
{
    public function __construct(
        private ClockInterface $baseClock,
        private DateInterval $offset,
        private bool $subtract = false,
    ) {
    }

    public function now(): DateTimeImmutable
    {
        $now = $this->baseClock->now();

        return $this->subtract
            ? $now->sub($this->offset)
            : $now->add($this->offset);
    }

    public static function ahead(ClockInterface $clock, DateInterval $offset): self
    {
        return new self($clock, $offset, false);
    }

    public static function behind(ClockInterface $clock, DateInterval $offset): self
    {
        return new self($clock, $offset, true);
    }

    public static function daysAhead(ClockInterface $clock, int $days): self
    {
        return new self($clock, new DateInterval("P{$days}D"), false);
    }

    public static function daysBehind(ClockInterface $clock, int $days): self
    {
        return new self($clock, new DateInterval("P{$days}D"), true);
    }
}
```

## Шаблон: Монотонные часы

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Clock;

use DateTimeImmutable;
use Psr\Clock\ClockInterface;

final class MonotonicClock implements ClockInterface
{
    private ?DateTimeImmutable $lastTime = null;

    public function __construct(
        private readonly ClockInterface $baseClock,
    ) {
    }

    public function now(): DateTimeImmutable
    {
        $current = $this->baseClock->now();

        if ($this->lastTime !== null && $current <= $this->lastTime) {
            // Ensure time always moves forward
            $current = $this->lastTime->modify('+1 microsecond');
        }

        $this->lastTime = $current;

        return $current;
    }
}
```

## Шаблон: Модульный тест

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Infrastructure\Clock;

use App\Infrastructure\Clock\FrozenClock;
use App\Infrastructure\Clock\OffsetClock;
use App\Infrastructure\Clock\SystemClock;
use DateInterval;
use DateTimeImmutable;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;

#[Group('unit')]
#[CoversClass(SystemClock::class)]
#[CoversClass(FrozenClock::class)]
#[CoversClass(OffsetClock::class)]
final class ClockTest extends TestCase
{
    public function test_system_clock_returns_current_time(): void
    {
        $clock = new SystemClock();
        $before = new DateTimeImmutable();

        $now = $clock->now();

        $after = new DateTimeImmutable();

        self::assertGreaterThanOrEqual($before, $now);
        self::assertLessThanOrEqual($after, $now);
    }

    public function test_system_clock_with_timezone(): void
    {
        $clock = new SystemClock('UTC');

        $now = $clock->now();

        self::assertSame('UTC', $now->getTimezone()->getName());
    }

    public function test_frozen_clock_returns_fixed_time(): void
    {
        $frozenTime = new DateTimeImmutable('2024-01-15 10:30:00');
        $clock = new FrozenClock($frozenTime);

        self::assertEquals($frozenTime, $clock->now());
        self::assertEquals($frozenTime, $clock->now());
    }

    public function test_frozen_clock_can_be_updated(): void
    {
        $clock = FrozenClock::at('2024-01-15 10:30:00');
        $newTime = new DateTimeImmutable('2024-06-01 12:00:00');

        $clock->setTo($newTime);

        self::assertEquals($newTime, $clock->now());
    }

    public function test_offset_clock_adds_time(): void
    {
        $baseClock = FrozenClock::at('2024-01-15 10:30:00');
        $clock = OffsetClock::daysAhead($baseClock, 5);

        $expected = new DateTimeImmutable('2024-01-20 10:30:00');

        self::assertEquals($expected, $clock->now());
    }

    public function test_offset_clock_subtracts_time(): void
    {
        $baseClock = FrozenClock::at('2024-01-15 10:30:00');
        $clock = OffsetClock::daysBehind($baseClock, 5);

        $expected = new DateTimeImmutable('2024-01-10 10:30:00');

        self::assertEquals($expected, $clock->now());
    }
}
```

## Пример использования

```php
<?php

use App\Infrastructure\Clock\FrozenClock;
use App\Infrastructure\Clock\SystemClock;

// Production: Use system clock
$clock = new SystemClock('UTC');
$service = new SubscriptionService($clock);

// Testing: Use frozen clock
$clock = FrozenClock::at('2024-01-15 10:30:00');
$service = new SubscriptionService($clock);

// Service using clock
final readonly class SubscriptionService
{
    public function __construct(
        private ClockInterface $clock,
    ) {
    }

    public function isExpired(Subscription $subscription): bool
    {
        return $subscription->expiresAt() < $this->clock->now();
    }

    public function daysUntilExpiry(Subscription $subscription): int
    {
        $diff = $this->clock->now()->diff($subscription->expiresAt());

        return $diff->invert ? 0 : $diff->days;
    }
}
```

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Интерфейс Clock | `src/Infrastructure/Clock/ClockInterface.php` |
| Системные часы | `src/Infrastructure/Clock/SystemClock.php` |
| Замороженные часы | `src/Infrastructure/Clock/FrozenClock.php` |
| Часы со смещением | `src/Infrastructure/Clock/OffsetClock.php` |
| Монотонные часы | `src/Infrastructure/Clock/MonotonicClock.php` |
| Тесты | `tests/Unit/Infrastructure/Clock/` |

## Требования

```json
{
    "require": {
        "psr/clock": "^1.0"
    }
}
```
