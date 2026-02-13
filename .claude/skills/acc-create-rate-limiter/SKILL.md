---
name: acc-create-rate-limiter
description: Генерирует паттерн Rate Limiter для PHP 8.2. Создаёт ограничение запросов с алгоритмами token bucket, sliding window и fixed window. Включает модульные тесты.
---

# Генератор Rate Limiter

Создаёт инфраструктуру паттерна Rate Limiter для ограничения запросов и защиты API.

## Когда использовать

| Сценарий | Пример |
|----------|--------|
| Защита API | Предотвращение злоупотреблений |
| Ограничение ресурсов | Лимиты подключений к базе данных |
| Справедливое использование | Лимиты запросов на пользователя |
| Защита от всплесков | Обработка пиковых нагрузок |

## Характеристики компонентов

### RateLimiterInterface
- Общий интерфейс для всех алгоритмов
- Методы проверки и потребления
- Запросы оставшейся ёмкости

### Алгоритмы
- **Token Bucket**: Плавное ограничение с допуском всплесков
- **Sliding Window**: Ограничение по времени со скользящим окном
- **Fixed Window**: Простой счётчик по времени

### RateLimitResult
- Содержит статус разрешено/отклонено
- Предоставляет информацию о retry-after
- Генерирует HTTP-заголовки

---

## Процесс генерации

### Шаг 1: Генерация основных компонентов

**Путь:** `src/Infrastructure/Resilience/RateLimiter/`

1. `RateLimiterInterface.php` — Общий интерфейс
2. `RateLimitResult.php` — Value object результата с заголовками
3. `RateLimitExceededException.php` — Исключение с информацией о повторе
4. `StorageInterface.php` — Абстракция хранилища

### Шаг 2: Выбор и генерация алгоритма

Выберите на основе сценария:

1. `TokenBucketRateLimiter.php` — Для API с допуском всплесков
2. `SlidingWindowRateLimiter.php` — Для строгих лимитов по времени
3. `FixedWindowRateLimiter.php` — Для простого ограничения

### Шаг 3: Генерация хранилища

1. `RedisStorage.php` — Production-хранилище с TTL

### Шаг 4: Генерация тестов

1. `{Algorithm}RateLimiterTest.php` — Тесты алгоритмов
2. `RateLimitResultTest.php` — Тесты value object результата

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Все классы | `src/Infrastructure/Resilience/RateLimiter/` |
| Модульные тесты | `tests/Unit/Infrastructure/Resilience/RateLimiter/` |

---

## Соглашения об именовании

| Компонент | Шаблон | Пример |
|-----------|--------|--------|
| Интерфейс | `RateLimiterInterface` | `RateLimiterInterface` |
| Token Bucket | `TokenBucketRateLimiter` | `TokenBucketRateLimiter` |
| Sliding Window | `SlidingWindowRateLimiter` | `SlidingWindowRateLimiter` |
| Fixed Window | `FixedWindowRateLimiter` | `FixedWindowRateLimiter` |
| Результат | `RateLimitResult` | `RateLimitResult` |
| Исключение | `RateLimitExceededException` | `RateLimitExceededException` |
| Тест | `{ClassName}Test` | `TokenBucketRateLimiterTest` |

---

## Краткий справочник шаблонов

### RateLimiterInterface

```php
interface RateLimiterInterface
{
    public function attempt(string $key, int $tokens = 1): RateLimitResult;
    public function getRemainingTokens(string $key): int;
    public function getRetryAfter(string $key): ?int;
    public function reset(string $key): void;
}
```

### RateLimitResult

```php
final readonly class RateLimitResult
{
    public static function allowed(int $remaining, int $limit, \DateTimeImmutable $resetsAt): self;
    public static function denied(int $limit, int $retryAfter, \DateTimeImmutable $resetsAt): self;
    public function isAllowed(): bool;
    public function isDenied(): bool;
    public function toHeaders(): array; // X-RateLimit-* headers
}
```

---

## Пример использования

```php
// Create limiter
$limiter = new TokenBucketRateLimiter(
    capacity: 100,
    refillRate: 10.0, // 10 tokens per second
    clock: $clock,
    storage: new RedisStorage($redis)
);

// Check limit
$result = $limiter->attempt('user:123');

if ($result->isDenied()) {
    throw new RateLimitExceededException(
        key: 'user:123',
        limit: $result->limit,
        retryAfterSeconds: $result->retryAfterSeconds
    );
}

// Add headers to response
foreach ($result->toHeaders() as $name => $value) {
    $response = $response->withHeader($name, (string) $value);
}
```

---

## Сравнение алгоритмов

| Алгоритм | Обработка всплесков | Память | Точность | Сценарий |
|----------|---------------------|--------|----------|----------|
| Token Bucket | Хорошая (настраиваемая) | Низкая | Средняя | API с допуском всплесков |
| Sliding Window | Ограниченная | Высокая | Высокая | Строгие лимиты по времени |
| Fixed Window | Плохая (проблемы на границах) | Низкая | Низкая | Простое ограничение |

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|-------------|----------|---------|
| Без Redis/общего хранилища | Лимиты на экземпляр | Используйте общее хранилище |
| Отсутствие заголовков | Клиент не может адаптироваться | Возвращайте X-RateLimit-* заголовки |
| Один алгоритм | Не подходит для всех случаев | Выбирайте под конкретный сценарий |
| Без Retry-After | Клиент спамит | Всегда возвращайте время повтора |
| Синхронная блокировка | Блокировка потоков | Используйте неблокирующую проверку |

---

## Ссылки

Полные PHP-шаблоны и примеры см. в:
- `references/templates.md` — Все реализации алгоритмов
- `references/examples.md` — Пример middleware и тесты
