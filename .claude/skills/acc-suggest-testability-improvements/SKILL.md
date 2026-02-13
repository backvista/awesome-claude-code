---
name: acc-suggest-testability-improvements
description: Предлагает улучшения тестируемости PHP-кода. Предоставляет рекомендации по рефакторингу DI, возможности мокирования, извлечение интерфейсов, рекомендации по стратегии тестирования.
---

# Предложения по улучшению тестируемости

Предоставляет практические рекомендации по улучшению тестируемости кода.

## Категории улучшений

### 1. Извлечение интерфейса для зависимостей

```php
// ДО: Конкретная зависимость
class PaymentProcessor
{
    public function __construct(
        private StripeGateway $gateway, // Конкретный класс
    ) {}
}

// Проблема тестирования: необходимо мокировать внутренности StripeGateway

// ПОСЛЕ: Зависимость от интерфейса
interface PaymentGatewayInterface
{
    public function charge(Money $amount, PaymentMethod $method): PaymentResult;
}

class PaymentProcessor
{
    public function __construct(
        private PaymentGatewayInterface $gateway,
    ) {}
}

// Преимущество для тестов: простая мок-реализация
$mockGateway = $this->createMock(PaymentGatewayInterface::class);
$mockGateway->method('charge')->willReturn(PaymentResult::success());
```

### 2. Внедрение зависимостей времени/случайности

```php
// ДО: Трудно тестировать логику на основе времени
class TokenGenerator
{
    public function generate(): Token
    {
        return new Token(
            bin2hex(random_bytes(32)),
            new DateTime('+1 hour'),
        );
    }
}

// ПОСЛЕ: Внедряемые зависимости
interface ClockInterface
{
    public function now(): DateTimeImmutable;
}

interface RandomGeneratorInterface
{
    public function bytes(int $length): string;
}

class TokenGenerator
{
    public function __construct(
        private ClockInterface $clock,
        private RandomGeneratorInterface $random,
    ) {}

    public function generate(): Token
    {
        return new Token(
            bin2hex($this->random->bytes(32)),
            $this->clock->now()->modify('+1 hour'),
        );
    }
}

// Тест с замороженным временем
$clock = new FrozenClock(new DateTimeImmutable('2024-01-01 12:00:00'));
$random = new FixedRandom('0123456789abcdef...');
$generator = new TokenGenerator($clock, $random);
$token = $generator->generate();
// Теперь утверждения детерминированы
```

### 3. Создание тестовых билдеров

```php
// ДО: Утомительная настройка тестов
public function testOrderProcessing(): void
{
    $customer = new Customer();
    $customer->setId(1);
    $customer->setName('John');
    $customer->setEmail('john@example.com');
    $customer->setStatus('active');

    $product = new Product();
    $product->setId(1);
    $product->setName('Widget');
    $product->setPrice(new Money(1000, 'USD'));

    $order = new Order();
    $order->setCustomer($customer);
    $order->addItem(new OrderItem($product, 2));
    // ... ещё 20 строк
}

// ПОСЛЕ: Fluent-билдер
public function testOrderProcessing(): void
{
    $order = OrderBuilder::create()
        ->withCustomer(CustomerBuilder::active()->build())
        ->withItem('Widget', 1000, quantity: 2)
        ->build();

    $result = $this->processor->process($order);

    $this->assertTrue($result->isSuccessful());
}
```

### 4. Разделение чистой логики и I/O

```php
// ДО: Логика смешана с I/O
class PricingService
{
    public function calculateOrderPrice(int $orderId): Money
    {
        $order = $this->repository->find($orderId); // I/O
        $customer = $this->customerRepo->find($order->getCustomerId()); // I/O
        $rates = $this->taxApi->getRates($customer->getCountry()); // I/O

        // Бизнес-логика
        $subtotal = $this->calculateSubtotal($order);
        $discount = $this->applyDiscount($customer, $subtotal);
        $tax = $this->calculateTax($subtotal, $rates);

        return $subtotal->subtract($discount)->add($tax);
    }
}

// ПОСЛЕ: Чистый калькулятор
final readonly class OrderPriceCalculator
{
    public function calculate(
        Order $order,
        Customer $customer,
        TaxRates $taxRates,
    ): Money {
        $subtotal = $this->calculateSubtotal($order);
        $discount = $this->applyDiscount($customer, $subtotal);
        $tax = $this->calculateTax($subtotal, $taxRates);

        return $subtotal->subtract($discount)->add($tax);
    }
}

// I/O в тонком сервисе
final class PricingService
{
    public function __construct(
        private OrderRepository $orderRepo,
        private CustomerRepository $customerRepo,
        private TaxApiInterface $taxApi,
        private OrderPriceCalculator $calculator,
    ) {}

    public function calculateOrderPrice(int $orderId): Money
    {
        $order = $this->orderRepo->find($orderId);
        $customer = $this->customerRepo->find($order->getCustomerId());
        $rates = $this->taxApi->getRates($customer->getCountry());

        return $this->calculator->calculate($order, $customer, $rates);
    }
}

// Теперь калькулятор легко тестируется без моков
```

### 5. Использование паттерна Repository для доступа к данным

```php
// ДО: Прямой доступ к базе данных
class UserService
{
    public function __construct(private PDO $pdo) {}

    public function findActive(): array
    {
        $stmt = $this->pdo->query("SELECT * FROM users WHERE active = 1");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

// ПОСЛЕ: Интерфейс репозитория
interface UserRepositoryInterface
{
    /** @return User[] */
    public function findActive(): array;
    public function findById(int $id): ?User;
    public function save(User $user): void;
}

class UserService
{
    public function __construct(
        private UserRepositoryInterface $repository,
    ) {}

    public function findActive(): array
    {
        return $this->repository->findActive();
    }
}

// In-memory реализация для тестов
class InMemoryUserRepository implements UserRepositoryInterface
{
    private array $users = [];

    public function findActive(): array
    {
        return array_filter($this->users, fn($u) => $u->isActive());
    }

    public function givenUser(User $user): void
    {
        $this->users[$user->getId()] = $user;
    }
}
```

### 6. Создание тестовых двойников

```php
// Fake-реализация для тестирования
final class FakeEmailSender implements EmailSenderInterface
{
    private array $sentEmails = [];

    public function send(Email $email): void
    {
        $this->sentEmails[] = $email;
    }

    public function getSentEmails(): array
    {
        return $this->sentEmails;
    }

    public function assertEmailSentTo(string $address): void
    {
        foreach ($this->sentEmails as $email) {
            if ($email->getTo() === $address) {
                return;
            }
        }
        throw new AssertionError("No email sent to $address");
    }
}
```

### 7. Объекты-параметры для сложных методов

```php
// ДО: Много параметров, трудно мокировать
public function createOrder(
    int $customerId,
    array $items,
    string $shippingMethod,
    string $paymentMethod,
    ?string $couponCode,
    ?string $notes,
): Order {}

// ПОСЛЕ: DTO с билдером
final readonly class CreateOrderRequest
{
    public function __construct(
        public int $customerId,
        public array $items,
        public string $shippingMethod,
        public string $paymentMethod,
        public ?string $couponCode = null,
        public ?string $notes = null,
    ) {}
}

// Тест с билдером
$request = CreateOrderRequestBuilder::create()
    ->forCustomer(1)
    ->withItem('SKU-001', 2)
    ->withShipping('express')
    ->build();
```

## Приоритет реализации

| Улучшение | Эффект | Трудозатраты |
|-----------|--------|-------------|
| Извлечение интерфейса | Высокий | Низкие |
| Внедрение времени/случайности | Высокий | Средние |
| Создание тестовых билдеров | Средний | Средние |
| Разделение чистой логики | Высокий | Высокие |
| Паттерн Repository | Высокий | Средние |

## Формат вывода

```markdown
### Улучшение тестируемости: [Описание]

**Расположение:** `file.php:line`
**Тип:** [Extract Interface|Inject Dependency|Create Builder|...]
**Эффект:** Высокий/Средний/Низкий

**Текущая проблема:**
[Почему текущий код трудно тестировать]

**Предлагаемое улучшение:**
```php
// Улучшенный код
```

**Шаги реализации:**
1. Создать интерфейс XxxInterface
2. Обновить класс для зависимости от интерфейса
3. Создать тестовый двойник/мок
4. Обновить тест

**Польза для тестирования:**
[Как это упрощает тестирование]
```
