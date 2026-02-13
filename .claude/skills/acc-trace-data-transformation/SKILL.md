---
name: acc-trace-data-transformation
description: Отображает цепочки преобразования данных — от Request DTO через Command к Entity и Response DTO. Определяет маппинги, сериализаторы, преобразования типов и точки потери данных на границах слоёв.
---

# Трассировщик преобразований данных

## Обзор

Отслеживает как данные трансформируются при прохождении через слои приложения — от сырого HTTP-ввода через DTO, Command, Entity и обратно к Response-объектам. Определяет маппинги, сериализаторы, конвертеры и потенциальные точки потери данных.

## Паттерны цепочек преобразования

### Стандартная CQRS-цепочка

```
HTTP Request Body (JSON/Form)
  → Request DTO (validated input)
    → Command/Query (application layer input)
      → Entity/Aggregate (domain model)
        → Domain Event (side effect data)
        → Response DTO (output format)
          → HTTP Response (JSON/XML)
```

### Паттерны обнаружения

#### Входное преобразование

```bash
# Request DTO / Form Requests
Grep: "class.*Request|class.*Input" --glob "**/Api/**/*.php"
Grep: "class.*Request" --glob "**/Presentation/**/*.php"

# Маппинг Request → Command
Grep: "new.*Command\\(|Command::from|Command::create" --glob "**/*.php"

# Десериализация
Grep: "deserialize|fromArray|fromRequest|fromJson" --glob "**/*.php"
Grep: "Serializer::deserialize|denormalize" --glob "**/*.php"
```

#### Преобразование сущностей

```bash
# Фабрики сущностей / именованные конструкторы
Grep: "static function (create|from|of|new)" --glob "**/Domain/**/*.php"

# Конвертация Entity → DTO
Grep: "function (toArray|toDTO|toResponse|toView)" --glob "**/Domain/**/*.php"
Grep: "::fromEntity|::fromDomain|::fromModel" --glob "**/*.php"
```

#### Выходное преобразование

```bash
# Response DTO
Grep: "class.*Response|class.*Output|class.*View" --glob "**/Api/**/*.php"
Grep: "class.*Resource" --glob "**/Http/**/*.php"

# Сериализация
Grep: "jsonSerialize|toArray|normalize" --glob "**/*.php"
Grep: "JsonResponse|json_encode" --glob "**/*.php"

# Преобразование коллекций
Grep: "->map\\(|array_map|->transform" --glob "**/*.php"
```

#### Маппинги и конвертеры

```bash
# Явные классы-маппинги
Grep: "class.*Mapper|class.*Converter|class.*Transformer|class.*Assembler" --glob "**/*.php"

# Методы маппинга
Grep: "function (map|convert|transform|assemble|adapt)" --glob "**/*.php"

# AutoMapper / Symfony Serializer
Grep: "AutoMapper|ObjectNormalizer|PropertyNormalizer" --glob "**/*.php"
```

## Процесс анализа

### Шаг 1: Определение точек преобразования

Для заданного потока запроса:
1. **Прочитать точку входа** — какой формат данных приходит
2. **Найти каждую границу классов** — где данные меняют форму
3. **Прочитать конструктор/фабрику** — какие поля маппятся
4. **Отследить имена полей** — какие поля переименовываются, объединяются или удаляются

### Шаг 2: Составить карту преобразования полей

| Источник | Цель | Преобразование |
|----------|------|---------------|
| `request.customer_name` | `CreateOrderCommand.customerName` | snake_case → camelCase |
| `command.customerId` | `Customer entity` | ID → полная сущность (запрос в репозиторий) |
| `entity.createdAt` | `response.created_at` | DateTime → string ISO 8601 |
| `entity.money` | `response.amount` | Money VO → float |

### Шаг 3: Определить точки потери данных

Проверить:
- Поля, присутствующие в источнике, но отсутствующие в цели
- Сужение типов (DateTime → string, теряется часовой пояс)
- Потеря точности (float → int)
- Уплощение связей (Entity → только ID)

## Формат вывода

```markdown
## Карта преобразований данных

### Поток: Создание заказа

#### Цепочка преобразований

```
[1] JSON Input
    {
      "customer_id": "uuid-123",
      "items": [{"product_id": "p-1", "quantity": 2}],
      "shipping_address": {"street": "...", "city": "..."}
    }
         │
         ▼  (Десериализация + Валидация)
[2] CreateOrderRequest
    customerId: string (валидация: формат uuid)
    items: CreateOrderItemRequest[] (валидация: не пустой)
    shippingAddress: AddressRequest (валидация: все поля обязательны)
         │
         ▼  (Маппинг: CreateOrderRequest → CreateOrderCommand)
[3] CreateOrderCommand
    customerId: CustomerId (оборачивание в Value Object)
    items: OrderItemData[] (DTO с productId + quantity)
    shippingAddress: AddressData (DTO)
         │
         ▼  (Доменная фабрика: Order::create())
[4] Order Entity
    id: OrderId (генерируется)
    customerId: CustomerId
    items: OrderItem[] (сущности с рассчитанными ценами)
    total: Money (рассчитано из items)
    status: OrderStatus::Pending
    shippingAddress: ShippingAddress (Value Object)
    createdAt: DateTimeImmutable
         │
         ▼  (Маппинг ответа: OrderResponse::fromEntity())
[5] OrderResponse
    id: string (OrderId → string)
    customerId: string (CustomerId → string)
    items: OrderItemResponse[] (entity → response)
    total: float (Money → float, валюта отдельно)
    currency: string (из Money)
    status: string (enum → string)
    shippingAddress: AddressResponse
    createdAt: string (ISO 8601)
         │
         ▼  (JSON-сериализация)
[6] JSON Output
    {"id": "...", "customer_id": "...", "total": 150.00, ...}
```

#### Таблица маппинга полей

| Слой | Поле | Тип | Источник | Преобразование |
|------|------|-----|----------|---------------|
| Input → Request | customer_id → customerId | string | JSON key | snake → camel |
| Request → Command | customerId → customerId | string → CustomerId | DTO | Обёртка в VO |
| Command → Entity | items → OrderItem[] | DTO[] → Entity[] | Factory | Обогащение ценами |
| Entity → Response | total → total | Money → float | Mapper | Извлечение суммы |
| Entity → Response | createdAt → createdAt | DateTimeImmutable → string | Mapper | Формат ISO 8601 |
| Response → JSON | customerId → customer_id | string | Serializer | camel → snake |

#### Точки обогащения данных

| Шаг | Что добавляется | Источник |
|-----|-----------------|----------|
| Command → Entity | OrderId | Генерируется (UUID) |
| Command → Entity | Цены товаров | Запрос в ProductRepository |
| Command → Entity | Итоговая сумма | Рассчитывается из items |
| Command → Entity | Метка времени создания | Системные часы |
| Command → Entity | Начальный статус | Доменное значение по умолчанию (Pending) |

#### Потенциальные точки потери данных

| Шаг | Поле | Проблема |
|-----|------|---------|
| Money → float | точность | Потеря точности с плавающей точкой |
| DateTime → string | часовой пояс | Проверить сохранение часового пояса |
| Entity → Response | внутреннее состояние | Внутренние данные домена не раскрываются (ожидаемо) |
```

## Индикаторы качества преобразований

| Индикатор | Хорошо | Предупреждение |
|-----------|--------|----------------|
| Типобезопасность | Типизированные DTO на границах | Нетипизированные массивы |
| Валидация | На входной границе | Разбросана или отсутствует |
| Маппинг | Явный маппер/фабрика | Неявный в контроллере |
| Value Objects | Домен использует VO | Примитивы повсюду |
| Сериализация | Контролируемая (toArray/normalize) | json_encode на сущности |

## Распространённые антипаттерны

| Антипаттерн | Обнаружение | Проблема |
|-------------|-------------|---------|
| Entity как Response | `return json_encode($entity)` | Раскрывает внутреннюю структуру |
| Передача массивов | `$data = ['key' => $value]` | Нет типобезопасности |
| Отсутствие DTO | Controller → Repository напрямую | Пропуск валидации |
| Утечка абстракции | Доменные типы в API-ответе | Жёсткая связанность |

## Интеграция

Этот навык используется:
- `acc-data-flow-analyst` — документирует цепочки преобразования данных
- `acc-trace-request-lifecycle` — обогащает жизненный цикл деталями данных
- `acc-explain-business-process` — показывает перспективу данных в процессах
