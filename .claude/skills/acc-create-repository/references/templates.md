# Шаблоны Repository Pattern

## Интерфейс (слой Domain)

```php
<?php

declare(strict_types=1);

namespace Domain\{BoundedContext}\Repository;

use Domain\{BoundedContext}\Entity\{AggregateRoot};
use Domain\{BoundedContext}\ValueObject\{AggregateRoot}Id;

interface {AggregateRoot}RepositoryInterface
{
    public function findById({AggregateRoot}Id $id): ?{AggregateRoot};

    public function save({AggregateRoot} ${aggregateRoot}): void;

    public function remove({AggregateRoot} ${aggregateRoot}): void;

    public function nextIdentity(): {AggregateRoot}Id;

    {additionalMethods}
}
```

---

## Шаблон реализации Doctrine

```php
<?php

declare(strict_types=1);

namespace Infrastructure\Persistence\Doctrine;

use Domain\{BoundedContext}\Entity\{AggregateRoot};
use Domain\{BoundedContext}\Repository\{AggregateRoot}RepositoryInterface;
use Domain\{BoundedContext}\ValueObject\{AggregateRoot}Id;
use Doctrine\ORM\EntityManagerInterface;

final readonly class Doctrine{AggregateRoot}Repository implements {AggregateRoot}RepositoryInterface
{
    public function __construct(
        private EntityManagerInterface $em
    ) {}

    public function findById({AggregateRoot}Id $id): ?{AggregateRoot}
    {
        return $this->em->find({AggregateRoot}::class, $id->value);
    }

    public function save({AggregateRoot} ${aggregateRoot}): void
    {
        $this->em->persist(${aggregateRoot});
        $this->em->flush();
    }

    public function remove({AggregateRoot} ${aggregateRoot}): void
    {
        $this->em->remove(${aggregateRoot});
        $this->em->flush();
    }

    public function nextIdentity(): {AggregateRoot}Id
    {
        return {AggregateRoot}Id::generate();
    }

    {additionalImplementations}
}
```

---

## In-Memory репозиторий (для тестирования)

```php
<?php

declare(strict_types=1);

namespace Tests\Infrastructure\Persistence;

use Domain\{BoundedContext}\Entity\{AggregateRoot};
use Domain\{BoundedContext}\Repository\{AggregateRoot}RepositoryInterface;
use Domain\{BoundedContext}\ValueObject\{AggregateRoot}Id;

final class InMemory{AggregateRoot}Repository implements {AggregateRoot}RepositoryInterface
{
    /** @var array<string, {AggregateRoot}> */
    private array $items = [];

    public function findById({AggregateRoot}Id $id): ?{AggregateRoot}
    {
        return $this->items[$id->value] ?? null;
    }

    public function save({AggregateRoot} ${aggregateRoot}): void
    {
        $this->items[${aggregateRoot}->id()->value] = ${aggregateRoot};
    }

    public function remove({AggregateRoot} ${aggregateRoot}): void
    {
        unset($this->items[${aggregateRoot}->id()->value]);
    }

    public function nextIdentity(): {AggregateRoot}Id
    {
        return {AggregateRoot}Id::generate();
    }

    public function clear(): void
    {
        $this->items = [];
    }

    public function count(): int
    {
        return count($this->items);
    }
}
```

---

## Шаблон интеграционного теста

```php
<?php

declare(strict_types=1);

namespace Tests\Integration\Infrastructure\Persistence;

use Domain\{BoundedContext}\Entity\{AggregateRoot};
use Domain\{BoundedContext}\ValueObject\{AggregateRoot}Id;
use Infrastructure\Persistence\Doctrine\Doctrine{AggregateRoot}Repository;
use Doctrine\ORM\EntityManagerInterface;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

#[Group('integration')]
#[CoversClass(Doctrine{AggregateRoot}Repository::class)]
final class Doctrine{AggregateRoot}RepositoryTest extends KernelTestCase
{
    private EntityManagerInterface $em;
    private Doctrine{AggregateRoot}Repository $repository;

    protected function setUp(): void
    {
        $kernel = self::bootKernel();
        $this->em = $kernel->getContainer()->get('doctrine.orm.entity_manager');
        $this->repository = new Doctrine{AggregateRoot}Repository($this->em);
    }

    public function testSavesAndFinds(): void
    {
        ${aggregateRoot} = {AggregateRoot}::create(
            id: {AggregateRoot}Id::generate(),
            {factoryParams}
        );

        $this->repository->save(${aggregateRoot});

        $found = $this->repository->findById(${aggregateRoot}->id());

        self::assertNotNull($found);
        self::assertTrue(${aggregateRoot}->id()->equals($found->id()));
    }

    public function testReturnsNullWhenNotFound(): void
    {
        $found = $this->repository->findById({AggregateRoot}Id::generate());

        self::assertNull($found);
    }

    protected function tearDown(): void
    {
        $this->em->clear();
    }
}
```

---

## Правила проектирования

### Интерфейс в слое Domain

```
Domain/
└── Order/
    └── Repository/
        └── OrderRepositoryInterface.php   ← Интерфейс здесь

Infrastructure/
└── Persistence/
    └── Doctrine/
        └── DoctrineOrderRepository.php    ← Реализация здесь
```

### Работает с агрегатами, а не с сущностями

```php
// ХОРОШО: репозиторий для корневого агрегата
interface OrderRepositoryInterface
{
    public function findById(OrderId $id): ?Order;
    public function save(Order $order): void;
}

// ПЛОХО: репозиторий для дочерней сущности
interface OrderLineRepositoryInterface  // OrderLine не является корневым агрегатом
{
    public function findById(OrderLineId $id): ?OrderLine;
}
```

### Никакой бизнес-логики в методах запросов

```php
// ХОРОШО: простые методы запросов
interface OrderRepositoryInterface
{
    public function findById(OrderId $id): ?Order;
    public function findByStatus(OrderStatus $status): array;
}

// ПЛОХО: бизнес-логика в репозитории
interface OrderRepositoryInterface
{
    public function findOrdersEligibleForDiscount(): array;  // Бизнес-логика!
}
```
