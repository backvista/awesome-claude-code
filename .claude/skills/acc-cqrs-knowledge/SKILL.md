---
name: acc-cqrs-knowledge
description: База знаний архитектуры CQRS. Предоставляет паттерны, антипаттерны и PHP-специфичные рекомендации для аудита Command Query Responsibility Segregation.
---

# База знаний CQRS

Краткий справочник по паттернам архитектуры CQRS и рекомендациям по PHP-реализации.

## Ключевые принципы

### Разделение ответственности

```
┌─────────────────────────────────────────────────────────────┐
│                      APPLICATION                            │
├─────────────────────────────────────────────────────────────┤
│   WRITE SIDE (Commands)     │     READ SIDE (Queries)       │
├─────────────────────────────┼───────────────────────────────┤
│ Command → Handler → Domain  │  Query → Handler → ReadModel  │
│ Изменяет состояние          │  Возвращает данные, без       │
│ Использует Domain Model     │  побочных эффектов            │
│ Один aggregate на команду   │  Может обходить Domain Model  │
└─────────────────────────────┴───────────────────────────────┘
```

**Правило:** Commands ЗАПИСЫВАЮТ, Queries ЧИТАЮТ. Никогда не смешивать.

### Компоненты CQRS

| Компонент | Назначение | Возвращает | Побочные эффекты |
|-----------|-----------|------------|-----------------|
| **Command** | Запрос на изменение состояния | void или ID | Да |
| **CommandHandler** | Выполняет логику команды | void или ID | Да |
| **Query** | Запрос на получение данных | Data DTO | Нет |
| **QueryHandler** | Извлекает и преобразует данные | Data DTO | Нет |
| **CommandBus** | Маршрутизирует команды к обработчикам | Зависит | Н/П |
| **QueryBus** | Маршрутизирует запросы к обработчикам | Результат запроса | Н/П |

## Быстрые чек-листы

### Чек-лист Command

- [ ] Именование как императивный глагол + существительное (CreateOrder, ConfirmPayment)
- [ ] Неизменяемый (readonly class)
- [ ] Содержит только данные, необходимые для операции
- [ ] Возвращает void или ID созданного объекта (никогда сущности)
- [ ] Одна команда = один затронутый aggregate
- [ ] Валидирован перед отправкой

### Чек-лист Query

- [ ] Именование как Get/Find/List + существительное (GetOrderDetails, ListCustomers)
- [ ] Неизменяемый (readonly class)
- [ ] Содержит параметры фильтрации/пагинации
- [ ] Handler НЕ имеет побочных эффектов
- [ ] Может использовать оптимизированные read models
- [ ] Возвращает DTO, не сущности

### Чек-лист Handler

- [ ] Единственный метод `execute()` или `__invoke()`
- [ ] Один обработчик на команду/запрос
- [ ] CommandHandler может отправлять domain events
- [ ] QueryHandler никогда не отправляет события
- [ ] Нет кросс-aggregate транзакций в одном обработчике

## Краткий справочник частых нарушений

| Нарушение | Где искать | Серьёзность |
|-----------|-----------|-------------|
| Query с побочными эффектами | QueryHandler вызывает save() | Критично |
| Command возвращает данные | CommandHandler возвращает сущность | Критично |
| Смешанное чтение/запись в обработчике | Handler с get и save | Критично |
| Бизнес-логика в обработчике | if/switch по доменному состоянию | Предупреждение |
| Отсутствующая валидация команды | Command без инвариантов | Предупреждение |
| Query использует write БД | QueryHandler использует EntityManager | Информация |

## Паттерны CQRS для PHP 8.2

### Command

```php
final readonly class CreateOrderCommand
{
    public function __construct(
        public CustomerId $customerId,
        /** @var array<OrderLineData> */
        public array $lines,
        public ?string $notes = null
    ) {
        if (empty($lines)) {
            throw new InvalidArgumentException('Order must have at least one line');
        }
    }
}
```

### Command Handler

```php
final readonly class CreateOrderHandler
{
    public function __construct(
        private OrderRepositoryInterface $orders,
        private EventDispatcherInterface $events
    ) {}

    public function __invoke(CreateOrderCommand $command): OrderId
    {
        $order = Order::create(
            id: OrderId::generate(),
            customerId: $command->customerId,
            lines: $command->lines
        );

        $this->orders->save($order);

        foreach ($order->releaseEvents() as $event) {
            $this->events->dispatch($event);
        }

        return $order->id();
    }
}
```

### Query

```php
final readonly class GetOrderDetailsQuery
{
    public function __construct(
        public OrderId $orderId
    ) {}
}
```

### Query Handler

```php
final readonly class GetOrderDetailsHandler
{
    public function __construct(
        private OrderReadModelInterface $readModel
    ) {}

    public function __invoke(GetOrderDetailsQuery $query): ?OrderDetailsDTO
    {
        return $this->readModel->findById($query->orderId);
    }
}
```

## Ссылки

Для подробной информации загрузите файлы ссылок:

- `references/command-patterns.md` — Структура Command, именование, валидация
- `references/query-patterns.md` — Структура Query, read models
- `references/handler-patterns.md` — Паттерны обработчиков, async/sync
- `references/bus-patterns.md` — Реализации Command/Query bus
- `references/antipatterns.md` — Частые нарушения с паттернами обнаружения
