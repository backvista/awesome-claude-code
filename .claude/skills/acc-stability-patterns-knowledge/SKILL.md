---
name: acc-stability-patterns-knowledge
description: База знаний паттернов стабильности. Содержит паттерны, антипаттерны и PHP-специфические рекомендации для Circuit Breaker, Retry, Rate Limiter, Bulkhead и аудита отказоустойчивости.
---

# База знаний паттернов стабильности

Краткий справочник по паттернам отказоустойчивости и толерантности к сбоям в PHP-приложениях.

## Обзор основных паттернов

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ПАТТЕРНЫ СТАБИЛЬНОСТИ                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌────────────────────────────────────────────────────────────────────┐    │
│   │                      ПОТОК ЗАПРОСОВ                                 │    │
│   │                                                                     │    │
│   │   Client  ──▶  Rate Limiter  ──▶  Circuit Breaker  ──▶  Service   │    │
│   │      │              │                   │                  │        │    │
│   │      │         Ограничение         Мониторинг         Реальная     │    │
│   │      │         запросов            состояния           работа      │    │
│   │      │              │                   │                  │        │    │
│   │      │              ▼                   ▼                  ▼        │    │
│   │      │         ┌────────┐          ┌────────┐         ┌────────┐   │    │
│   │      │         │Bulkhead│          │ Retry  │         │Timeout │   │    │
│   │      │         │Изоляция│          │Повтор  │         │Контроль│   │    │
│   │      │         └────────┘          └────────┘         └────────┘   │    │
│   └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│   Паттерн          │ Назначение                  │ Защищает от              │
│   ─────────────────┼─────────────────────────────┼────────────────────────  │
│   Rate Limiter     │ Ограничение частоты запросов │ DDoS, перегрузка, абьюз │
│   Circuit Breaker  │ Быстрый отказ при сбоях     │ Каскадные сбои          │
│   Retry            │ Повтор временных сбоев      │ Временные отключения     │
│   Bulkhead         │ Изоляция ресурсов           │ Исчерпание ресурсов      │
│   Timeout          │ Ограничение времени ожидания│ Медленные зависимости    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Взаимодействие паттернов

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ВЗАИМОДЕЙСТВИЕ ПАТТЕРНОВ                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                         ┌────────────────────┐                               │
│                         │   Rate Limiter     │                               │
│                         │  (Точка входа)     │                               │
│                         └─────────┬──────────┘                               │
│                                   │                                          │
│                                   ▼                                          │
│                         ┌────────────────────┐                               │
│                         │     Bulkhead       │                               │
│                         │ (Лимиты ресурсов)  │                               │
│                         └─────────┬──────────┘                               │
│                                   │                                          │
│           ┌───────────────────────┼───────────────────────┐                  │
│           │                       │                       │                  │
│           ▼                       ▼                       ▼                  │
│   ┌──────────────┐       ┌──────────────┐        ┌──────────────┐           │
│   │   Service A  │       │   Service B  │        │   Service C  │           │
│   │  ┌────────┐  │       │  ┌────────┐  │        │  ┌────────┐  │           │
│   │  │Circuit │  │       │  │Circuit │  │        │  │Circuit │  │           │
│   │  │Breaker │  │       │  │Breaker │  │        │  │Breaker │  │           │
│   │  └───┬────┘  │       │  └───┬────┘  │        │  └───┬────┘  │           │
│   │      │       │       │      │       │        │      │       │           │
│   │  ┌───▼────┐  │       │  ┌───▼────┐  │        │  ┌───▼────┐  │           │
│   │  │ Retry  │  │       │  │ Retry  │  │        │  │ Retry  │  │           │
│   │  │Повтор  │  │       │  │Повтор  │  │        │  │Повтор  │  │           │
│   │  └────────┘  │       │  └────────┘  │        │  └────────┘  │           │
│   └──────────────┘       └──────────────┘        └──────────────┘           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Краткий справочник

### Состояния Circuit Breaker

| Состояние | Поведение | Переход в |
|-----------|----------|-----------|
| **Closed** | Запросы проходят, отказы подсчитываются | Open (при достижении порога) |
| **Open** | Запросы мгновенно отклоняются, вызовов к сервису нет | Half-Open (после таймаута) |
| **Half-Open** | Ограниченное количество запросов для проверки | Closed (при успехе) / Open (при сбое) |

### Стратегии отсрочки повторов

| Стратегия | Формула | Применение |
|-----------|---------|-----------|
| **Фиксированная** | `delay` | Простые случаи, известное время восстановления |
| **Линейная** | `delay * attempt` | Постепенное увеличение |
| **Экспоненциальная** | `delay * 2^(attempt-1)` | Неизвестное восстановление, выбор по умолчанию |
| **Экспоненциальная + Jitter** | `exponential ± random` | Высокий параллелизм, предотвращение thundering herd |

### Алгоритмы Rate Limiter

| Алгоритм | Точность | Память | Обработка всплесков |
|----------|----------|--------|---------------------|
| **Token Bucket** | Средняя | Низкая | Допускает всплески |
| **Sliding Window** | Высокая | Средняя | Плавное ограничение |
| **Fixed Window** | Низкая | Низкая | Всплески на границе |
| **Leaky Bucket** | Высокая | Низкая | Без всплесков |

### Типы Bulkhead

| Тип | Изоляция | Применение |
|-----|----------|-----------|
| **Semaphore** | Счётчик потоков/запросов | Однопроцессные приложения |
| **Thread Pool** | Выделенные потоки | CPU-bound задачи |
| **Queue-based** | Очередь запросов | Асинхронная обработка |
| **Distributed** | Redis/разделяемое состояние | Многоинстансные приложения |

## PHP-реализации паттернов

### Circuit Breaker с PSR Clock

```php
<?php

declare(strict_types=1);

namespace Infrastructure\Resilience;

use Psr\Clock\ClockInterface;

final class CircuitBreaker
{
    private CircuitState $state = CircuitState::Closed;
    private int $failures = 0;
    private ?\DateTimeImmutable $openedAt = null;

    public function __construct(
        private readonly string $name,
        private readonly int $failureThreshold,
        private readonly int $openTimeoutSeconds,
        private readonly ClockInterface $clock
    ) {}

    public function execute(callable $operation, ?callable $fallback = null): mixed
    {
        if (!$this->isAvailable()) {
            return $fallback ? $fallback() : throw new CircuitOpenException($this->name);
        }

        try {
            $result = $operation();
            $this->recordSuccess();
            return $result;
        } catch (\Throwable $e) {
            $this->recordFailure();
            throw $e;
        }
    }

    private function isAvailable(): bool
    {
        if ($this->state === CircuitState::Closed) return true;
        if ($this->state === CircuitState::Open) {
            if ($this->hasTimeoutElapsed()) {
                $this->state = CircuitState::HalfOpen;
                return true;
            }
            return false;
        }
        return true;
    }
}
```

### Retry с экспоненциальной отсрочкой

```php
<?php

declare(strict_types=1);

namespace Infrastructure\Resilience;

final readonly class RetryExecutor
{
    public function execute(
        callable $operation,
        int $maxAttempts = 3,
        int $baseDelayMs = 100
    ): mixed {
        $attempt = 0;
        $lastException = null;

        while ($attempt < $maxAttempts) {
            try {
                return $operation();
            } catch (\Throwable $e) {
                $lastException = $e;
                $attempt++;

                if ($attempt < $maxAttempts) {
                    $delay = $baseDelayMs * (2 ** ($attempt - 1));
                    $jitter = random_int(0, (int)($delay * 0.3));
                    usleep(($delay + $jitter) * 1000);
                }
            }
        }

        throw $lastException;
    }
}
```

### Token Bucket Rate Limiter

```php
<?php

declare(strict_types=1);

namespace Infrastructure\Resilience;

final class TokenBucketRateLimiter
{
    private float $tokens;
    private int $lastRefill;

    public function __construct(
        private readonly int $capacity,
        private readonly float $refillRate,
        private readonly \Redis $redis,
        private readonly string $key
    ) {
        $this->tokens = $capacity;
        $this->lastRefill = time();
    }

    public function attempt(): bool
    {
        $this->refill();

        if ($this->tokens >= 1) {
            $this->tokens--;
            return true;
        }

        return false;
    }

    private function refill(): void
    {
        $now = time();
        $elapsed = $now - $this->lastRefill;
        $this->tokens = min(
            $this->capacity,
            $this->tokens + ($elapsed * $this->refillRate)
        );
        $this->lastRefill = $now;
    }
}
```

## Краткий справочник типичных нарушений

| Нарушение | Где искать | Серьёзность |
|-----------|-----------|------------|
| Нет таймаута на внешних вызовах | HTTP-клиенты, запросы к БД | Критическая |
| Retry без отсрочки | Реализации повторов | Предупреждение |
| Нет circuit breaker на внешних сервисах | API-клиенты, адаптеры | Критическая |
| Неограниченные пулы соединений | Пулы БД, HTTP-пулы | Предупреждение |
| Нет fallback-стратегии | Использование circuit breaker | Предупреждение |
| Retry не-идемпотентных операций | Обработчики команд | Критическая |
| Rate limiting только в памяти | Многоинстансные приложения | Предупреждение |
| Нет jitter в retry | Системы с высоким параллелизмом | Предупреждение |

## Паттерны обнаружения

```bash
# Поиск реализаций отказоустойчивости
Glob: **/Resilience/**/*.php
Glob: **/CircuitBreaker/**/*.php
Grep: "CircuitBreaker|RateLimiter|Retry" --glob "**/*.php"

# Проверка правильного использования таймаутов
Grep: "CURLOPT_TIMEOUT|timeout|setTimeout" --glob "**/Http/**/*.php"

# Обнаружение паттернов retry
Grep: "retry|backoff|exponential" --glob "**/*.php"

# Поиск rate limiting
Grep: "RateLimiter|throttle|TokenBucket" --glob "**/*.php"

# Проверка паттернов bulkhead
Grep: "Semaphore|Bulkhead|maxConcurrent" --glob "**/*.php"

# Обнаружение отсутствующих паттернов
Grep: "->request\(|curl_exec|file_get_contents" --glob "**/Infrastructure/**/*.php"
```

## Рекомендации по конфигурации

### Настройки Circuit Breaker

| Тип сервиса | Порог сбоев | Таймаут Open | Порог успехов |
|-------------|------------|--------------|---------------|
| Критический API | 3-5 | 30-60с | 3-5 |
| Фоновая задача | 5-10 | 60-120с | 2-3 |
| Внутренний сервис | 3-5 | 15-30с | 2-3 |
| База данных | 2-3 | 10-20с | 1-2 |

### Конфигурация Retry

| Тип операции | Макс. попыток | Базовая задержка | Макс. задержка |
|-------------|--------------|-----------------|---------------|
| HTTP API-вызов | 3 | 100мс | 10с |
| Запрос к БД | 3 | 50мс | 5с |
| Очередь сообщений | 5 | 1с | 60с |
| Файловая операция | 2 | 10мс | 100мс |

### Настройки Rate Limiter

| Тип эндпоинта | Лимит | Окно | Всплеск |
|---------------|-------|------|---------|
| Публичный API | 100/мин | 1 мин | 20 |
| Аутентифицированный API | 1000/мин | 1 мин | 100 |
| Административный API | 10000/мин | 1 мин | 1000 |
| Webhook | 60/мин | 1 мин | 10 |

## Точки интеграции

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ИНФРАСТРУКТУРНЫЙ СЛОЙ                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   src/Infrastructure/                                                        │
│   ├── Resilience/                                                           │
│   │   ├── CircuitBreaker/                                                   │
│   │   │   ├── CircuitBreaker.php                                           │
│   │   │   ├── CircuitBreakerConfig.php                                     │
│   │   │   ├── CircuitBreakerRegistry.php                                   │
│   │   │   └── CircuitState.php                                             │
│   │   ├── Retry/                                                            │
│   │   │   ├── RetryExecutor.php                                            │
│   │   │   ├── RetryPolicy.php                                              │
│   │   │   └── BackoffStrategy.php                                          │
│   │   ├── RateLimiter/                                                      │
│   │   │   ├── RateLimiterInterface.php                                     │
│   │   │   ├── TokenBucketRateLimiter.php                                   │
│   │   │   └── SlidingWindowRateLimiter.php                                 │
│   │   └── Bulkhead/                                                         │
│   │       ├── BulkheadInterface.php                                        │
│   │       ├── SemaphoreBulkhead.php                                        │
│   │       └── BulkheadRegistry.php                                         │
│   │                                                                         │
│   ├── Http/                                                                  │
│   │   ├── ResilientHttpClient.php    ◀── Использует CircuitBreaker + Retry │
│   │   └── Middleware/                                                       │
│   │       └── RateLimitMiddleware.php                                       │
│   │                                                                         │
│   └── Payment/                                                               │
│       └── PaymentGatewayAdapter.php  ◀── Использует CircuitBreaker + Bulkhead│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Ссылки

Подробная информация в справочных файлах:

- `references/circuit-breaker.md` — Детали реализации Circuit Breaker
- `references/retry-patterns.md` — Стратегии повторов и алгоритмы отсрочки
- `references/rate-limiting.md` — Алгоритмы и конфигурации Rate Limiting
- `references/bulkhead.md` — Паттерны изоляции Bulkhead

## Ресурсы

- `assets/report-template.md` — Шаблон структурированного отчёта аудита
