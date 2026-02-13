---
name: acc-create-psr6-cache
description: Генерирует реализацию PSR-6 Cache для PHP 8.2. Создаёт реализации CacheItemPoolInterface и CacheItemInterface с обработкой TTL и отложенным сохранением. Включает модульные тесты.
---

# Генератор PSR-6 Cache

## Обзор

Генерирует PSR-6-совместимые реализации кэша на основе `Psr\Cache\CacheItemPoolInterface` и `Psr\Cache\CacheItemInterface`.

## Когда использовать

- Сложное кэширование с элементами кэша как объектами
- Необходимость отложенного/пакетного сохранения
- Построение фреймворков кэширования
- Необходимость метаданных элементов кэша

## Генерируемые компоненты

| Компонент | Описание | Расположение |
|-----------|----------|--------------|
| CacheItemPool | Реализация пула | `src/Infrastructure/Cache/` |
| CacheItem | Реализация элемента | `src/Infrastructure/Cache/` |
| Модульные тесты | PHPUnit тесты | `tests/Unit/Infrastructure/Cache/` |

## Шаблон: Элемент кэша

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Cache;

use DateInterval;
use DateTimeImmutable;
use DateTimeInterface;
use Psr\Cache\CacheItemInterface;

final class CacheItem implements CacheItemInterface
{
    private mixed $value = null;
    private bool $isHit = false;
    private ?DateTimeImmutable $expiration = null;

    public function __construct(
        private readonly string $key,
    ) {
    }

    public function getKey(): string
    {
        return $this->key;
    }

    public function get(): mixed
    {
        return $this->isHit ? $this->value : null;
    }

    public function isHit(): bool
    {
        return $this->isHit;
    }

    public function set(mixed $value): static
    {
        $this->value = $value;
        $this->isHit = true;

        return $this;
    }

    public function expiresAt(?DateTimeInterface $expiration): static
    {
        $this->expiration = $expiration instanceof DateTimeImmutable
            ? $expiration
            : ($expiration !== null
                ? DateTimeImmutable::createFromInterface($expiration)
                : null);

        return $this;
    }

    public function expiresAfter(int|DateInterval|null $time): static
    {
        if ($time === null) {
            $this->expiration = null;
        } elseif ($time instanceof DateInterval) {
            $this->expiration = (new DateTimeImmutable())->add($time);
        } else {
            $this->expiration = (new DateTimeImmutable())->modify("+{$time} seconds");
        }

        return $this;
    }

    public function getExpiration(): ?DateTimeImmutable
    {
        return $this->expiration;
    }

    public function isExpired(): bool
    {
        if ($this->expiration === null) {
            return false;
        }

        return $this->expiration < new DateTimeImmutable();
    }

    public function markAsHit(): void
    {
        $this->isHit = true;
    }

    public function markAsMiss(): void
    {
        $this->isHit = false;
    }
}
```

## Шаблон: Пул кэша на массиве

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Cache;

use Psr\Cache\CacheItemInterface;
use Psr\Cache\CacheItemPoolInterface;

final class ArrayCachePool implements CacheItemPoolInterface
{
    /** @var array<string, CacheItem> */
    private array $items = [];

    /** @var array<string, CacheItem> */
    private array $deferred = [];

    public function getItem(string $key): CacheItemInterface
    {
        $this->validateKey($key);

        if (isset($this->deferred[$key])) {
            return clone $this->deferred[$key];
        }

        if (isset($this->items[$key])) {
            $item = $this->items[$key];

            if (!$item->isExpired()) {
                return clone $item;
            }

            unset($this->items[$key]);
        }

        $item = new CacheItem($key);
        $item->markAsMiss();

        return $item;
    }

    /** @return iterable<string, CacheItemInterface> */
    public function getItems(array $keys = []): iterable
    {
        $items = [];

        foreach ($keys as $key) {
            $items[$key] = $this->getItem($key);
        }

        return $items;
    }

    public function hasItem(string $key): bool
    {
        $this->validateKey($key);

        return $this->getItem($key)->isHit();
    }

    public function clear(): bool
    {
        $this->items = [];
        $this->deferred = [];

        return true;
    }

    public function deleteItem(string $key): bool
    {
        $this->validateKey($key);

        unset($this->items[$key], $this->deferred[$key]);

        return true;
    }

    public function deleteItems(array $keys): bool
    {
        foreach ($keys as $key) {
            $this->deleteItem($key);
        }

        return true;
    }

    public function save(CacheItemInterface $item): bool
    {
        if (!$item instanceof CacheItem) {
            return false;
        }

        $this->items[$item->getKey()] = $item;
        unset($this->deferred[$item->getKey()]);

        return true;
    }

    public function saveDeferred(CacheItemInterface $item): bool
    {
        if (!$item instanceof CacheItem) {
            return false;
        }

        $this->deferred[$item->getKey()] = $item;

        return true;
    }

    public function commit(): bool
    {
        foreach ($this->deferred as $item) {
            $this->save($item);
        }

        $this->deferred = [];

        return true;
    }

    private function validateKey(string $key): void
    {
        if ($key === '') {
            throw new InvalidArgumentException('Cache key cannot be empty');
        }

        if (preg_match('/[{}()\/\\\\@:]/', $key)) {
            throw new InvalidArgumentException(
                'Cache key contains reserved characters: {}()/\\@:',
            );
        }
    }
}
```

## Шаблон: Модульный тест

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Infrastructure\Cache;

use App\Infrastructure\Cache\ArrayCachePool;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

#[Group('unit')]
#[CoversClass(ArrayCachePool::class)]
final class ArrayCachePoolTest extends TestCase
{
    private ArrayCachePool $pool;

    protected function setUp(): void
    {
        $this->pool = new ArrayCachePool();
    }

    #[Test]
    public function it_returns_miss_for_nonexistent_item(): void
    {
        $item = $this->pool->getItem('nonexistent');

        self::assertFalse($item->isHit());
        self::assertNull($item->get());
    }

    #[Test]
    public function it_saves_and_retrieves_item(): void
    {
        $item = $this->pool->getItem('key');
        $item->set('value');
        $this->pool->save($item);

        $retrieved = $this->pool->getItem('key');

        self::assertTrue($retrieved->isHit());
        self::assertSame('value', $retrieved->get());
    }

    #[Test]
    public function it_handles_deferred_saves(): void
    {
        $item1 = $this->pool->getItem('key1')->set('value1');
        $item2 = $this->pool->getItem('key2')->set('value2');

        $this->pool->saveDeferred($item1);
        $this->pool->saveDeferred($item2);

        self::assertTrue($this->pool->getItem('key1')->isHit());

        $this->pool->commit();

        self::assertTrue($this->pool->getItem('key1')->isHit());
        self::assertTrue($this->pool->getItem('key2')->isHit());
    }

    #[Test]
    public function it_deletes_item(): void
    {
        $item = $this->pool->getItem('key')->set('value');
        $this->pool->save($item);

        $this->pool->deleteItem('key');

        self::assertFalse($this->pool->hasItem('key'));
    }

    #[Test]
    public function it_clears_all_items(): void
    {
        $this->pool->save($this->pool->getItem('key1')->set('value1'));
        $this->pool->save($this->pool->getItem('key2')->set('value2'));

        $this->pool->clear();

        self::assertFalse($this->pool->hasItem('key1'));
        self::assertFalse($this->pool->hasItem('key2'));
    }
}
```

## Пример использования

```php
<?php

use App\Infrastructure\Cache\ArrayCachePool;

$pool = new ArrayCachePool();

// Get item (miss)
$item = $pool->getItem('user_123');

if (!$item->isHit()) {
    $user = $userRepository->find(123);
    $item->set($user);
    $item->expiresAfter(3600); // 1 hour
    $pool->save($item);
}

$user = $item->get();

// Deferred saves
$item1 = $pool->getItem('key1')->set('value1');
$item2 = $pool->getItem('key2')->set('value2');

$pool->saveDeferred($item1);
$pool->saveDeferred($item2);
$pool->commit();
```

## Требования

```json
{
    "require": {
        "psr/cache": "^3.0"
    }
}
```

## См. также

- `references/templates.md` - Реализации на Redis и файловой системе
- `references/examples.md` - Примеры интеграции
