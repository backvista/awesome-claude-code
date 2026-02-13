---
name: acc-create-read-model
description: Генерирует Read Model/Projection для PHP 8.2. Создаёт оптимизированные модели запросов для стороны чтения CQRS с проекциями и денормализацией. Включает модульные тесты.
---

# Генератор Read Model / Projection

Создаёт инфраструктуру Read Model для стороны чтения CQRS с оптимизированными моделями запросов.

## Когда использовать

| Сценарий | Пример |
|----------|--------|
| Сторона чтения CQRS | Отдельные модели запросов |
| Денормализованные представления | Агрегаты для дашбордов |
| Сложные запросы | Объединения нескольких сущностей |
| Обновления по событиям | Проекции событий |

## Характеристики компонентов

### Read Model
- Оптимизирована для запросов
- Денормализованные данные
- Конечная согласованность
- Без бизнес-логики

### Projection
- Строит модели чтения из событий
- Обрабатывает потоки событий
- Поддерживает синхронизацию
- Идемпотентная обработка

### Repository
- Методы, ориентированные на запросы
- Возвращает модели чтения
- Без операций записи

---

## Процесс генерации

### Шаг 1: Генерация доменной модели чтения

**Путь:** `src/Domain/{BoundedContext}/ReadModel/`

1. `{Name}ReadModel.php` — Иммутабельная модель чтения с fromArray/toArray
2. `{Name}ReadModelRepositoryInterface.php` — Интерфейс репозитория для запросов

### Шаг 2: Генерация проекции приложения

**Путь:** `src/Application/{BoundedContext}/Projection/`

1. `{Name}ProjectionInterface.php` — Контракт проекции
2. `{Name}Projection.php` — Обработчики событий для построения модели чтения

### Шаг 3: Генерация инфраструктуры

**Путь:** `src/Infrastructure/{BoundedContext}/`

1. `Projection/{Name}Store.php` — Хранилище для insert/update/upsert
2. `ReadModel/Doctrine{Name}Repository.php` — Реализация репозитория

### Шаг 4: Генерация тестов

1. `{Name}ReadModelTest.php` — Тесты сериализации модели чтения
2. `{Name}ProjectionTest.php` — Тесты обработки событий проекцией

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Модель чтения | `src/Domain/{BoundedContext}/ReadModel/` |
| Интерфейс репозитория | `src/Domain/{BoundedContext}/ReadModel/` |
| Интерфейс проекции | `src/Application/{BoundedContext}/Projection/` |
| Проекция | `src/Application/{BoundedContext}/Projection/` |
| Хранилище | `src/Infrastructure/{BoundedContext}/Projection/` |
| Реализация репозитория | `src/Infrastructure/{BoundedContext}/ReadModel/` |
| Модульные тесты | `tests/Unit/` |

---

## Соглашения об именовании

| Компонент | Шаблон | Пример |
|-----------|--------|--------|
| Модель чтения | `{Name}ReadModel` | `OrderSummaryReadModel` |
| Интерфейс репозитория | `{Name}ReadModelRepositoryInterface` | `OrderSummaryReadModelRepositoryInterface` |
| Интерфейс проекции | `{Name}ProjectionInterface` | `OrderSummaryProjectionInterface` |
| Проекция | `{Name}Projection` | `OrderSummaryProjection` |
| Хранилище | `{Name}Store` | `OrderSummaryStore` |
| Тест | `{ClassName}Test` | `OrderSummaryProjectionTest` |

---

## Краткий справочник шаблонов

### Модель чтения

```php
final readonly class {Name}ReadModel
{
    public function __construct(
        public string $id,
        // ... denormalized properties
        public \DateTimeImmutable $createdAt,
        public \DateTimeImmutable $updatedAt
    ) {}

    public static function fromArray(array $data): self;
    public function toArray(): array;
}
```

### Проекция

```php
final class {Name}Projection implements {Name}ProjectionInterface
{
    public function project(DomainEventInterface $event): void
    {
        match ($event::class) {
            OrderCreated::class => $this->whenOrderCreated($event),
            OrderShipped::class => $this->whenOrderShipped($event),
            default => null,
        };
    }

    public function reset(): void;
    public function subscribedEvents(): array;
}
```

---

## Пример использования

```php
// Query read model
$orders = $orderSummaryRepository->findByCustomerId($customerId);

// Project event
$projection->project($orderCreatedEvent);

// Reset projection for rebuild
$projection->reset();
```

---

## Схема базы данных

```sql
CREATE TABLE order_summaries (
    id VARCHAR(36) PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id VARCHAR(36) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_cents BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,

    INDEX idx_customer (customer_id),
    INDEX idx_status (status)
);
```

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|-------------|----------|---------|
| Бизнес-логика | Модель чтения содержит поведение | Оставляйте только данные |
| Операции записи | Модификация моделей чтения | Используйте только проекции |
| Неидемпотентность | Повторная проекция ломает данные | Идемпотентная обработка событий |
| Отсутствие reset | Невозможно перестроить | Добавьте метод reset() |
| Жёсткая связанность | Проекция зависит от домена | Используйте только события |

---

## Ссылки

Полные PHP-шаблоны и примеры см. в:
- `references/templates.md` — Шаблоны модели чтения, проекции, хранилища
- `references/examples.md` — Пример OrderSummary и тесты
