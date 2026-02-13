---
name: acc-create-adapter
description: Генерирует паттерн Adapter для PHP 8.2. Конвертирует несовместимые интерфейсы, оборачивает устаревший код и внешние библиотеки. Включает юнит-тесты.
---

# Генератор паттерна Adapter

Создаёт инфраструктуру паттерна Adapter для преобразования несовместимых интерфейсов в ожидаемые.

## Когда использовать

| Сценарий | Пример |
|----------|--------|
| Интеграция с устаревшим кодом | Обернуть старый API новым интерфейсом |
| Обёртка сторонних библиотек | Адаптеры для Stripe SDK, AWS SDK |
| Стандартизация интерфейсов | Несколько платёжных шлюзов с единым интерфейсом |
| Обратная совместимость | Поддержка старого и нового интерфейсов |

## Характеристики компонентов

### Target Interface
- Определяет ожидаемые операции
- Клиентский код зависит от него
- Контракт Domain layer

### Adapter
- Реализует target interface
- Оборачивает adaptee (существующий класс)
- Транслирует вызовы между интерфейсами

### Adaptee
- Существующий несовместимый класс
- Устаревший код или внешняя библиотека
- Не модифицируется адаптером

---

## Процесс генерации

### Шаг 1: Генерация Target Interface

**Путь:** `src/Domain/{BoundedContext}/`

1. `{Name}Interface.php` — Контракт ожидаемого интерфейса

### Шаг 2: Генерация Adapter

**Путь:** `src/Infrastructure/{BoundedContext}/Adapter/`

1. `{Provider}{Name}Adapter.php` — Преобразует adaptee в target interface
2. `{Legacy}{Name}Adapter.php` — Оборачивает устаревший код
3. `{External}{Name}Adapter.php` — Оборачивает стороннюю библиотеку

### Шаг 3: Генерация тестов

1. `{AdapterName}Test.php` — Проверка поведения адаптера

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Target Interface | `src/Domain/{BoundedContext}/` |
| Adapter | `src/Infrastructure/{BoundedContext}/Adapter/` |
| Adaptee (существующий) | Внешняя библиотека или устаревший код |
| Юнит-тесты | `tests/Unit/Infrastructure/{BoundedContext}/Adapter/` |

---

## Соглашения об именовании

| Компонент | Паттерн | Пример |
|-----------|---------|--------|
| Target Interface | `{Name}Interface` | `PaymentGatewayInterface` |
| Adapter | `{Provider}{Name}Adapter` | `StripePaymentGatewayAdapter` |
| Тест | `{ClassName}Test` | `StripePaymentGatewayAdapterTest` |

---

## Краткий справочник шаблонов

### Target Interface

```php
interface {Name}Interface
{
    public function {operation}({params}): {returnType};
}
```

### Adapter

```php
final readonly class {Provider}{Name}Adapter implements {Name}Interface
{
    public function __construct(
        private {Adaptee} $adaptee
    ) {}

    public function {operation}({params}): {returnType}
    {
        // Translate params to adaptee format
        $adapteeResult = $this->adaptee->{adapteeMethod}({adapteeParams});

        // Convert result to target format
        return {convertedResult};
    }
}
```

---

## Пример использования

```php
// Stripe SDK is the adaptee
$stripeClient = new \Stripe\StripeClient($apiKey);

// Adapter makes it compatible with our interface
$paymentGateway = new StripePaymentGatewayAdapter($stripeClient);

// Use through our domain interface
$result = $paymentGateway->charge($amount, $token);
```

---

## Распространённые адаптеры

| Адаптер | Назначение |
|---------|-----------|
| PaymentGatewayAdapter | Обёртка API Stripe, PayPal, Square |
| StorageAdapter | Обёртка AWS S3, Google Cloud Storage |
| MessengerAdapter | Обёртка API Slack, Discord, Telegram |
| EmailAdapter | Обёртка SendGrid, Mailgun, AWS SES |
| CacheAdapter | Обёртка Redis, Memcached, APCu |
| LoggerAdapter | Обёртка Monolog, Syslog, пользовательских логгеров |

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|-------------|---------|---------|
| Протекающий Adapter | Раскрытие деталей adaptee | Возвращать только типы target interface |
| Множественные ответственности | Adapter содержит бизнес-логику | Сохранять фокус адаптера на трансляции |
| Тесная связанность | Adapter зависит от конкретного adaptee | Принимать интерфейс по возможности |
| Тяжёлая трансляция | Сложные преобразования в адаптере | Извлечь сервисы-трансляторы |
| Отсутствующая обработка ошибок | Утечка исключений adaptee | Перехватывать и конвертировать в доменные исключения |

---

## Ссылки

Для полных PHP-шаблонов и примеров смотрите:
- `references/templates.md` — Шаблоны Target Interface, Adapter для платежей, хранилищ, сообщений
- `references/examples.md` — Адаптеры Stripe, PayPal, AWS S3, legacy user с юнит-тестами
