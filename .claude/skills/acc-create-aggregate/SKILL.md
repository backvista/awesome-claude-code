---
name: acc-create-aggregate
description: Генерирует DDD Aggregates для PHP 8.2. Создаёт границы согласованности с корневой сущностью, domain events и защитой инвариантов. Включает юнит-тесты.
---

# Генератор Aggregate

Генерация DDD-совместимых Aggregates с корнем, domain events и тестами.

## Характеристики Aggregate

- **Граница согласованности**: Все изменения атомарны
- **Корневая сущность**: Единственная точка входа
- **Транзакционная согласованность**: Инварианты всегда валидны
- **Domain events**: Фиксируют произошедшие изменения
- **Инкапсуляция**: Дочерние элементы доступны через корень
- **Идентичность**: Ссылка по ID корня

---

## Процесс генерации

### Шаг 1: Генерация базового AggregateRoot

**Путь:** `src/Domain/Shared/Aggregate/`

1. `AggregateRoot.php` — Базовый класс с записью событий

### Шаг 2: Генерация корневой сущности Aggregate

**Путь:** `src/Domain/{BoundedContext}/Entity/`

1. `{Name}.php` — Основной aggregate root

### Шаг 3: Генерация дочерних сущностей (при необходимости)

**Путь:** `src/Domain/{BoundedContext}/Entity/`

1. `{ChildName}.php` — Дочерняя сущность внутри aggregate

### Шаг 4: Генерация Domain Events

**Путь:** `src/Domain/{BoundedContext}/Event/`

1. `{Name}CreatedEvent.php`
2. `{Name}{Action}Event.php` для каждого поведения

### Шаг 5: Генерация тестов

**Путь:** `tests/Unit/Domain/{BoundedContext}/Entity/`

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Базовый AggregateRoot | `src/Domain/Shared/Aggregate/` |
| Сущность Aggregate | `src/Domain/{BoundedContext}/Entity/` |
| Дочерние сущности | `src/Domain/{BoundedContext}/Entity/` |
| Domain Events | `src/Domain/{BoundedContext}/Event/` |
| Юнит-тесты | `tests/Unit/Domain/{BoundedContext}/Entity/` |

---

## Соглашения об именовании

| Компонент | Паттерн | Пример |
|-----------|---------|--------|
| Aggregate Root | `{Name}` | `Order` |
| Дочерняя сущность | `{Parent}{Name}` | `OrderLine` |
| Событие создания | `{Name}CreatedEvent` | `OrderCreatedEvent` |
| Событие состояния | `{Name}{Action}Event` | `OrderConfirmedEvent` |

---

## Краткий справочник шаблонов

### Базовый AggregateRoot

```php
abstract class AggregateRoot
{
    private array $events = [];

    protected function recordEvent(DomainEvent $event): void
    {
        $this->events[] = $event;
    }

    public function releaseEvents(): array
    {
        $events = $this->events;
        $this->events = [];
        return $events;
    }
}
```

### Корневая сущность Aggregate

```php
final class {Name} extends AggregateRoot
{
    private {Name}Status $status;

    private function __construct(
        private readonly {Name}Id $id,
        {properties}
    ) {
        $this->status = {Name}Status::Draft;
    }

    public static function create({Name}Id $id, {params}): self
    {
        $aggregate = new self($id, {args});

        $aggregate->recordEvent(new {Name}CreatedEvent(...));

        return $aggregate;
    }

    public function {behavior}({params}): void
    {
        $this->ensureValidState();
        // Apply change
        $this->recordEvent(new {Name}{Behavior}Event(...));
    }
}
```

### Дочерняя сущность

```php
final readonly class {ChildName}
{
    public function __construct(
        public {PropertyType} $property1,
        public {PropertyType} $property2
    ) {}

    public function total(): Money
    {
        return $this->unitPrice->multiply($this->quantity);
    }
}
```

---

## Правила проектирования

| Правило | Хорошо | Плохо |
|---------|--------|-------|
| Граница транзакции | Один aggregate на транзакцию | Несколько aggregates |
| Ссылка | Только по ID | Полная ссылка на сущность |
| Размер | Маленький, сфокусированный | Большой с множеством коллекций |
| Инварианты | Всегда валидны | Может быть в невалидном состоянии |
| События | Запись всех изменений состояния | Без записи событий |

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|-------------|---------|---------|
| Большой Aggregate | Проблемы производительности | Разделить на меньшие aggregates |
| Ссылки на Entity | Тесная связанность | Использовать только ID |
| Публичные сеттеры | Нет защиты инвариантов | Использовать методы поведения |
| Отсутствующие события | Невозможно отследить историю | Записывать событие для каждого изменения |
| Нет корня | Множественные точки входа | Единственная корневая сущность |

---

## Ссылки

Для полных PHP-шаблонов и примеров смотрите:
- `references/templates.md` — Шаблоны AggregateRoot, Entity, Child Entity, Test
- `references/examples.md` — Aggregate Order с OrderLine, событиями и тестами
