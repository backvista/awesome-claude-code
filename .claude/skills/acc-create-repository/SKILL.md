---
name: acc-create-repository
description: Генерирует интерфейсы DDD-репозиториев и заготовки реализаций для PHP 8.2. Создаёт доменные интерфейсы в слое Domain, реализацию в Infrastructure.
---

# Генератор репозиториев

Генерирует DDD-совместимые интерфейсы репозиториев и заготовки реализаций.

## Характеристики репозиториев

- **Интерфейс в Domain**: Контракт определён в слое Domain
- **Реализация в Infrastructure**: Реализация Doctrine/Eloquent/и т.д.
- **Работа с агрегатами**: Не с сущностями напрямую
- **Подобен коллекции**: Операции find, save, remove
- **Без бизнес-логики**: Только операции персистенции

---

## Процесс генерации

### Шаг 1: Генерация интерфейса

**Путь:** `src/Domain/{BoundedContext}/Repository/`

1. `{AggregateRoot}RepositoryInterface.php` — Доменный контракт

### Шаг 2: Генерация реализации

**Путь:** `src/Infrastructure/Persistence/Doctrine/`

1. `Doctrine{AggregateRoot}Repository.php` — Реализация Doctrine

### Шаг 3: Генерация In-Memory репозитория (опционально)

**Путь:** `tests/Infrastructure/Persistence/`

1. `InMemory{AggregateRoot}Repository.php` — Для модульного тестирования

### Шаг 4: Генерация интеграционных тестов

**Путь:** `tests/Integration/Infrastructure/Persistence/`

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Интерфейс | `src/Domain/{BoundedContext}/Repository/` |
| Реализация Doctrine | `src/Infrastructure/Persistence/Doctrine/` |
| In-Memory | `tests/Infrastructure/Persistence/` |
| Интеграционные тесты | `tests/Integration/Infrastructure/Persistence/` |

---

## Соглашения об именовании

| Компонент | Шаблон | Пример |
|-----------|--------|--------|
| Интерфейс | `{AggregateRoot}RepositoryInterface` | `OrderRepositoryInterface` |
| Реализация Doctrine | `Doctrine{AggregateRoot}Repository` | `DoctrineOrderRepository` |
| In-Memory | `InMemory{AggregateRoot}Repository` | `InMemoryOrderRepository` |

---

## Краткий справочник шаблонов

### Интерфейс

```php
interface {AggregateRoot}RepositoryInterface
{
    public function findById({AggregateRoot}Id $id): ?{AggregateRoot};

    public function save({AggregateRoot} $aggregate): void;

    public function remove({AggregateRoot} $aggregate): void;

    public function nextIdentity(): {AggregateRoot}Id;
}
```

### Реализация Doctrine

```php
final readonly class Doctrine{AggregateRoot}Repository implements {AggregateRoot}RepositoryInterface
{
    public function __construct(
        private EntityManagerInterface $em
    ) {}

    public function findById({AggregateRoot}Id $id): ?{AggregateRoot}
    {
        return $this->em->find({AggregateRoot}::class, $id->value);
    }

    public function save({AggregateRoot} $aggregate): void
    {
        $this->em->persist($aggregate);
        $this->em->flush();
    }

    public function remove({AggregateRoot} $aggregate): void
    {
        $this->em->remove($aggregate);
        $this->em->flush();
    }

    public function nextIdentity(): {AggregateRoot}Id
    {
        return {AggregateRoot}Id::generate();
    }
}
```

### Реализация In-Memory

```php
final class InMemory{AggregateRoot}Repository implements {AggregateRoot}RepositoryInterface
{
    private array $items = [];

    public function findById({AggregateRoot}Id $id): ?{AggregateRoot}
    {
        return $this->items[$id->value] ?? null;
    }

    public function save({AggregateRoot} $aggregate): void
    {
        $this->items[$aggregate->id()->value] = $aggregate;
    }

    public function clear(): void
    {
        $this->items = [];
    }
}
```

---

## Правила проектирования

| Правило | Правильно | Неправильно |
|---------|-----------|-------------|
| Размещение по слоям | Интерфейс в Domain | Интерфейс в Infrastructure |
| Область агрегата | Репозиторий на корень агрегата | Репозиторий на сущность |
| Методы запросов | Простые фильтры | Бизнес-логика в запросах |
| Идентификация | Метод `nextIdentity()` | Внешняя генерация ID |

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|-------------|----------|---------|
| Репозиторий сущности | Обходит агрегат | Только корни агрегатов |
| Бизнес-запросы | Логика в репозитории | Используйте паттерн Specification |
| Утечка инфраструктуры | Домен зависит от ORM | Интерфейс в Domain |
| Универсальный репозиторий | Слишком абстрактный | Специфичный для каждого агрегата |
| Без nextIdentity | Невозможно генерировать ID | Добавьте в интерфейс |

---

## Ссылки

Полные PHP-шаблоны и примеры см. в:
- `references/templates.md` — Шаблоны интерфейса, Doctrine, In-Memory, тестов
- `references/examples.md` — Репозитории Order, User с реализациями Doctrine и In-Memory
