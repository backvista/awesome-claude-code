---
name: acc-suggest-simplification
description: Предлагает возможности упрощения кода. Определяет кандидатов для извлечения методов, сложные выражения, избыточный код, возможности рефакторинга.
---

# Предложения по упрощению кода

Анализирует PHP-код на предмет возможностей упрощения и рефакторинга.

## Паттерны упрощения

### 1. Извлечение метода

```php
// ДО: Длинный встроенный блок кода
public function processOrder(Order $order): void
{
    // Validate order (5 lines)
    if ($order->getItems()->isEmpty()) {
        throw new EmptyOrderException();
    }
    if ($order->getTotal()->isNegative()) {
        throw new InvalidTotalException();
    }

    // Process payment (10 lines)
    $payment = $this->paymentGateway->charge(
        $order->getTotal(),
        $order->getPaymentMethod()
    );
    if (!$payment->isSuccessful()) {
        throw new PaymentFailedException();
    }

    // Send notifications (5 lines)
    $this->mailer->send($order->getCustomer()->getEmail(), 'order_confirmed');
}

// ПОСЛЕ: Извлечённые методы
public function processOrder(Order $order): void
{
    $this->validateOrder($order);
    $this->processPayment($order);
    $this->sendConfirmation($order);
}

private function validateOrder(Order $order): void {}
private function processPayment(Order $order): Payment {}
private function sendConfirmation(Order $order): void {}
```

### 2. Введение поясняющей переменной

```php
// ДО: Сложное выражение
if ($user->getSubscription()?->isActive()
    && $user->getCreatedAt() < new DateTime('-30 days')
    && !$user->hasUsedTrial()
    && $user->getOrderCount() > 0) {
    $this->offerUpgrade($user);
}

// ПОСЛЕ: Именованные переменные
$hasActiveSubscription = $user->getSubscription()?->isActive();
$isEstablishedUser = $user->getCreatedAt() < new DateTime('-30 days');
$eligibleForUpgrade = !$user->hasUsedTrial() && $user->getOrderCount() > 0;

if ($hasActiveSubscription && $isEstablishedUser && $eligibleForUpgrade) {
    $this->offerUpgrade($user);
}

// ЕЩЁ ЛУЧШЕ: Извлечение в метод
if ($user->isEligibleForUpgrade()) {
    $this->offerUpgrade($user);
}
```

### 3. Удаление избыточного кода

```php
// ДО: Дублирующие проверки
if ($value !== null) {
    if ($value !== null) {  // Повторная проверка
        $this->process($value);
    }
}

// ДО: Ненужный else
if ($condition) {
    return $a;
} else {
    return $b;
}

// ПОСЛЕ: Упрощённо
if ($condition) {
    return $a;
}
return $b;

// ДО: Избыточное булево сравнение
if ($condition === true) {}
return $value === true;

// ПОСЛЕ: Упрощённо
if ($condition) {}
return $value;
```

### 4. Упрощение условий

```php
// ДО: Вложенные условия
if ($user !== null) {
    if ($user->isActive()) {
        if ($user->hasPermission('edit')) {
            return true;
        }
    }
}
return false;

// ПОСЛЕ: Объединённое условие
return $user !== null
    && $user->isActive()
    && $user->hasPermission('edit');

// ДО: Отрицательное условие
if (!$items->isEmpty()) {
    $this->process($items);
}

// ПОСЛЕ: Положительное условие
if ($items->isNotEmpty()) {
    $this->process($items);
}
```

### 5. Замена временной переменной запросом

```php
// ДО: Временная переменная используется один раз
$basePrice = $order->getBasePrice();
$discount = $basePrice * 0.1;
return $basePrice - $discount;

// ПОСЛЕ: Встраивание или метод
return $order->getBasePrice() * 0.9;

// Или если сложно:
return $order->getBasePrice() - $this->calculateDiscount($order);
```

### 6. Использование методов коллекций

```php
// ДО: Ручной цикл
$active = [];
foreach ($users as $user) {
    if ($user->isActive()) {
        $active[] = $user;
    }
}

// ПОСЛЕ: array_filter
$active = array_filter($users, fn($user) => $user->isActive());

// ДО: Ручной маппинг
$emails = [];
foreach ($users as $user) {
    $emails[] = $user->getEmail();
}

// ПОСЛЕ: array_map
$emails = array_map(fn($user) => $user->getEmail(), $users);

// ДО: Ручной поиск
$found = null;
foreach ($items as $item) {
    if ($item->getId() === $id) {
        $found = $item;
        break;
    }
}

// ПОСЛЕ: Метод коллекции
$found = $collection->first(fn($item) => $item->getId() === $id);
```

### 7. Замена switch полиморфизмом

```php
// ДО: Switch по типу
public function calculateShipping(Order $order): Money
{
    switch ($order->getShippingMethod()) {
        case 'standard':
            return $this->calculateStandardShipping($order);
        case 'express':
            return $this->calculateExpressShipping($order);
        case 'overnight':
            return $this->calculateOvernightShipping($order);
        default:
            throw new InvalidMethodException();
    }
}

// ПОСЛЕ: Паттерн Strategy
interface ShippingCalculator {
    public function calculate(Order $order): Money;
}

class StandardShipping implements ShippingCalculator {}
class ExpressShipping implements ShippingCalculator {}

public function calculateShipping(Order $order): Money
{
    return $this->shippingCalculators
        ->get($order->getShippingMethod())
        ->calculate($order);
}
```

### 8. Паттерн Null Object

```php
// ДО: Проверки на null повсюду
if ($user->getAddress() !== null) {
    echo $user->getAddress()->getCity();
} else {
    echo 'Unknown';
}

// ПОСЛЕ: Null Object
class NullAddress implements AddressInterface
{
    public function getCity(): string
    {
        return 'Unknown';
    }
}

// Всегда безопасный вызов
echo $user->getAddress()->getCity();
```

### 9. Guard-выражения

```php
// ДО: Глубокая вложенность
public function process(Request $request): Response
{
    if ($request !== null) {
        if ($request->isValid()) {
            if ($this->canProcess($request)) {
                return $this->doProcess($request);
            } else {
                return $this->error('Cannot process');
            }
        } else {
            return $this->error('Invalid request');
        }
    } else {
        return $this->error('No request');
    }
}

// ПОСЛЕ: Guard-выражения
public function process(Request $request): Response
{
    if ($request === null) {
        return $this->error('No request');
    }

    if (!$request->isValid()) {
        return $this->error('Invalid request');
    }

    if (!$this->canProcess($request)) {
        return $this->error('Cannot process');
    }

    return $this->doProcess($request);
}
```

### 10. Использование современных возможностей PHP

```php
// ДО: Старый синтаксис
$name = isset($data['name']) ? $data['name'] : 'default';

// ПОСЛЕ: Null coalescing
$name = $data['name'] ?? 'default';

// ДО: Присвоение свойства
$value = $object->getValue();
if ($value !== null) {
    echo $value;
}

// ПОСЛЕ: Nullsafe-оператор
echo $object?->getValue();

// ДО: Match как if/else
if ($status === 'active') {
    $color = 'green';
} elseif ($status === 'pending') {
    $color = 'yellow';
} else {
    $color = 'red';
}

// ПОСЛЕ: Выражение match
$color = match($status) {
    'active' => 'green',
    'pending' => 'yellow',
    default => 'red',
};
```

## Классификация серьёзности

| Паттерн | Серьёзность |
|---------|------------|
| Глубоко вложенный код | 🟠 Значительная |
| Повторяющиеся блоки кода | 🟠 Значительная |
| Сложные булевы выражения | 🟡 Незначительная |
| Старый синтаксис при наличии современного PHP | 🟢 Рекомендация |
| Многословный, но понятный код | 🟢 Рекомендация |

## Формат вывода

```markdown
### Упрощение: [Описание]

**Серьёзность:** 🟠/🟡/🟢
**Расположение:** `file.php:line`
**Тип:** [Extract Method|Guard Clause|Collection Method|...]

**Проблема:**
[Описание сложности]

**Текущий код:**
```php
// Сложный код
```

**Предложение:**
```php
// Упрощённый код
```

**Преимущества:**
- Улучшенная читаемость
- Сниженная когнитивная нагрузка
- Упрощённое тестирование
- Лучшая переиспользуемость
```
