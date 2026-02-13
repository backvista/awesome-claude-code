---
name: acc-create-query
description: Генерирует CQRS-запросы и обработчики для PHP 8.2. Создаёт DTO запросов только для чтения с обработчиками, возвращающими данные без побочных эффектов. Включает модульные тесты.
---

# Генератор запросов (Query)

Генерирует CQRS-совместимые запросы и обработчики запросов с тестами.

## Характеристики запросов

- **Иммутабельность**: `final readonly class`
- **Вопросительное именование**: Get/Find/List + существительное
- **Без побочных эффектов**: Обработчик никогда не изменяет состояние
- **Возвращает DTO**: Никогда не возвращает доменные сущности
- **Оптимизация для чтения**: Может использовать выделенные модели чтения

---

## Процесс генерации

### Шаг 1: Генерация запроса

**Путь:** `src/Application/{BoundedContext}/Query/`

1. `{Name}Query.php` — Иммутабельный DTO запроса с параметрами

### Шаг 2: Генерация обработчика

**Путь:** `src/Application/{BoundedContext}/Handler/`

1. `{Name}Handler.php` — Потребитель модели чтения

### Шаг 3: Генерация DTO

**Путь:** `src/Application/{BoundedContext}/DTO/`

1. `{Name}DTO.php` — Структура данных результата
2. `PaginatedResultDTO.php` — Для запросов списков (опционально)

### Шаг 4: Генерация интерфейса модели чтения

**Путь:** `src/Application/{BoundedContext}/ReadModel/`

1. `{Name}ReadModelInterface.php` — Контракт методов запроса

### Шаг 5: Генерация тестов

**Путь:** `tests/Unit/Application/{BoundedContext}/`

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Запрос | `src/Application/{BoundedContext}/Query/` |
| Обработчик | `src/Application/{BoundedContext}/Handler/` |
| DTO | `src/Application/{BoundedContext}/DTO/` |
| Интерфейс модели чтения | `src/Application/{BoundedContext}/ReadModel/` |
| Модульные тесты | `tests/Unit/Application/{BoundedContext}/` |

---

## Соглашения об именовании запросов

| Назначение | Имя запроса | Возвращает |
|------------|-------------|------------|
| Один по ID | `GetOrderDetailsQuery` | DTO или исключение |
| Один по полю | `FindUserByEmailQuery` | DTO или null |
| Список/коллекция | `ListOrdersQuery` | PaginatedResult |
| Поиск | `SearchProductsQuery` | массив DTO |
| Подсчёт | `CountPendingOrdersQuery` | int |
| Проверка существования | `CheckEmailExistsQuery` | bool |

---

## Краткий справочник шаблонов

### Запрос

```php
final readonly class {Name}Query
{
    public function __construct(
        public {IdType} $id
    ) {}
}
```

### Запрос с пагинацией

```php
final readonly class List{Name}Query
{
    public function __construct(
        public ?{FilterType} $filter = null,
        public int $limit = 20,
        public int $offset = 0,
        public string $sortBy = 'created_at',
        public string $sortDirection = 'desc'
    ) {
        if ($limit < 1 || $limit > 100) {
            throw new \InvalidArgumentException('Limit must be between 1 and 100');
        }
    }
}
```

### Обработчик

```php
final readonly class {Name}Handler
{
    public function __construct(
        private {ReadModelInterface} $readModel
    ) {}

    public function __invoke({Name}Query $query): {ResultDTO}
    {
        $result = $this->readModel->findById($query->id->value);

        if ($result === null) {
            throw new {NotFoundException}($query->id);
        }

        return $result;
    }
}
```

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|-------------|----------|---------|
| Побочные эффекты | Обработчик изменяет состояние | Оставляйте только для чтения |
| Возврат сущностей | Утечка домена | Возвращайте только DTO |
| Без валидации | Невалидные параметры | Валидируйте в конструкторе |
| Неограниченные списки | Проблемы производительности | Всегда используйте пагинацию |
| Отсутствие модели чтения | Запросы к модели записи | Используйте выделенную модель чтения |

---

## Ссылки

Полные PHP-шаблоны и примеры см. в:
- `references/templates.md` — Шаблоны Query, Handler, DTO, PaginatedResult, ReadModel
- `references/examples.md` — Примеры GetOrderDetails, ListOrders, OrderDTO и тесты
