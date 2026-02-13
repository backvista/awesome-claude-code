---
name: acc-check-test-quality
description: Анализирует качество PHP-тестов. Проверяет структуру тестов, качество утверждений, изоляцию тестов, соглашения об именовании, соблюдение паттерна AAA.
---

# Проверка качества тестов

Анализ PHP-тестов на качество и соблюдение лучших практик.

## Паттерны качества

### 1. Структура тестов (паттерн AAA)

```php
// BAD: Mixed arrange/act/assert
public function testOrderTotal(): void
{
    $order = new Order();
    $this->assertEquals(0, $order->getTotal());
    $order->addItem(new Item('A', 10));
    $order->addItem(new Item('B', 20));
    $this->assertEquals(30, $order->getTotal());
    $order->applyDiscount(5);
    $this->assertEquals(25, $order->getTotal());
}

// GOOD: Clear AAA pattern
public function testOrderTotalWithDiscount(): void
{
    // Arrange
    $order = new Order();
    $order->addItem(new Item('A', 10));
    $order->addItem(new Item('B', 20));

    // Act
    $order->applyDiscount(5);

    // Assert
    $this->assertEquals(25, $order->getTotal());
}
```

### 2. Именование тестов

```php
// BAD: Unclear names
public function testProcess(): void {}
public function test1(): void {}
public function testOrderWorks(): void {}

// GOOD: Descriptive names
public function testProcessReturnsSuccessWhenInputIsValid(): void {}
public function testProcessThrowsExceptionWhenInputIsEmpty(): void {}
public function testOrderTotalIncludesTaxForDomesticOrders(): void {}

// GOOD: Method naming pattern
// test[MethodName][State/Action][ExpectedResult]
public function testCalculateTotal_WithDiscount_ReturnsReducedPrice(): void {}
```

### 3. Один аспект поведения на тест

```php
// BAD: Testing multiple behaviors
public function testUser(): void
{
    $user = new User('John', 'john@example.com');

    $this->assertEquals('John', $user->getName());
    $this->assertEquals('john@example.com', $user->getEmail());
    $this->assertTrue($user->isActive());
    $this->assertEmpty($user->getOrders());
    $this->assertNull($user->getLastLogin());
}

// GOOD: One behavior per test
public function testNewUserIsActiveByDefault(): void
{
    $user = new User('John', 'john@example.com');

    $this->assertTrue($user->isActive());
}

public function testNewUserHasNoOrders(): void
{
    $user = new User('John', 'john@example.com');

    $this->assertEmpty($user->getOrders());
}
```

### 4. Качество утверждений

```php
// BAD: Weak assertions
public function testFindUser(): void
{
    $user = $this->repository->find(1);
    $this->assertNotNull($user);
    $this->assertTrue($user instanceof User);
}

// GOOD: Strong assertions
public function testFindUserReturnsUserWithCorrectId(): void
{
    $user = $this->repository->find(1);

    $this->assertInstanceOf(User::class, $user);
    $this->assertSame(1, $user->getId());
    $this->assertEquals('john@example.com', $user->getEmail());
}

// BAD: assertEquals for arrays (order matters)
$this->assertEquals([1, 2, 3], $result);

// GOOD: Specific array assertions
$this->assertCount(3, $result);
$this->assertContains(1, $result);
$this->assertEqualsCanonicalizing([3, 2, 1], $result);
```

### 5. Изоляция тестов

```php
// BAD: Shared state between tests
class OrderTest extends TestCase
{
    private static Order $order;

    public static function setUpBeforeClass(): void
    {
        self::$order = new Order(); // Shared!
    }

    public function testAddItem(): void
    {
        self::$order->addItem(new Item('A', 10)); // Affects other tests
    }
}

// GOOD: Fresh state per test
class OrderTest extends TestCase
{
    private Order $order;

    protected function setUp(): void
    {
        $this->order = new Order(); // Fresh each test
    }

    public function testAddItem(): void
    {
        $this->order->addItem(new Item('A', 10));
        $this->assertCount(1, $this->order->getItems());
    }
}
```

### 6. Использование моков

```php
// BAD: Over-mocking
public function testProcessOrder(): void
{
    $order = $this->createMock(Order::class);
    $order->method('getItems')->willReturn([]);
    $order->method('getTotal')->willReturn(new Money(100));
    $order->method('getCustomer')->willReturn($this->createMock(Customer::class));
    // Testing mocks, not real behavior
}

// GOOD: Real objects where possible
public function testProcessOrder(): void
{
    $order = OrderBuilder::create()
        ->withItem('Product A', 50)
        ->withItem('Product B', 50)
        ->build();

    $result = $this->processor->process($order);

    $this->assertTrue($result->isSuccessful());
}

// Mock only external dependencies
public function testSendNotification(): void
{
    $mailer = $this->createMock(MailerInterface::class);
    $mailer->expects($this->once())
           ->method('send')
           ->with($this->callback(fn($email) => $email->getTo() === 'user@example.com'));

    $service = new NotificationService($mailer);
    $service->notifyUser($this->createUser('user@example.com'));
}
```

### 7. Тестовые данные

```php
// BAD: Magic values
public function testPricing(): void
{
    $this->assertEquals(108.5, $this->calculator->calculate(100, 0.085));
}

// GOOD: Named values with meaning
public function testPricingIncludesTax(): void
{
    $basePrice = 100.0;
    $taxRate = 0.085; // 8.5%
    $expectedTotal = 108.5;

    $actualTotal = $this->calculator->calculate($basePrice, $taxRate);

    $this->assertEquals($expectedTotal, $actualTotal);
}

// BETTER: Test builders
public function testOrderWithMultipleItems(): void
{
    $order = OrderBuilder::create()
        ->withItem(ProductBuilder::create()->withPrice(50)->build())
        ->withItem(ProductBuilder::create()->withPrice(30)->build())
        ->build();

    $this->assertEquals(80, $order->getTotal()->getAmount());
}
```

### 8. Тестирование исключений

```php
// BAD: Generic exception test
public function testInvalidInput(): void
{
    $this->expectException(Exception::class);
    $this->service->process(null);
}

// GOOD: Specific exception with message
public function testProcessThrowsWhenInputIsNull(): void
{
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('Input cannot be null');

    $this->service->process(null);
}

// BETTER: Assert on exception object
public function testProcessThrowsDetailedException(): void
{
    try {
        $this->service->process(null);
        $this->fail('Expected exception was not thrown');
    } catch (ProcessingException $e) {
        $this->assertEquals('INPUT_REQUIRED', $e->getCode());
        $this->assertStringContainsString('null', $e->getMessage());
    }
}
```

## Паттерны Grep

```bash
# Multiple assertions in test
Grep: "assert.*\n.*assert.*\n.*assert.*\n.*assert" --glob "**/*Test.php"

# Static test data
Grep: "static\s+\\\$\w+|setUpBeforeClass" --glob "**/*Test.php"

# Generic exception
Grep: "expectException\(Exception::class\)" --glob "**/*Test.php"

# Poor naming
Grep: "function\s+test\d+|function\s+testIt" --glob "**/*Test.php"
```

## Классификация серьёзности

| Паттерн | Серьёзность |
|---------|----------|
| Общее состояние между тестами | 🟠 Серьёзная |
| Тестирование поведения моков | 🟠 Серьёзная |
| Несколько аспектов поведения в одном тесте | 🟡 Незначительная |
| Обобщённое тестирование исключений | 🟡 Незначительная |
| Слабые утверждения | 🟡 Незначительная |
| Плохое именование | 🟢 Предложение |

## Формат вывода

```markdown
### Проблема качества тестов: [Описание]

**Серьёзность:** 🟠/🟡/🟢
**Расположение:** `tests/OrderTest.php:line`
**Тип:** [Структура|Изоляция|Утверждения|Именование|...]

**Проблема:**
Тест смешивает несколько аспектов поведения и имеет неясные утверждения.

**Текущий код:**
```php
public function testOrder(): void
{
    $order = new Order();
    $order->addItem(new Item('A', 10));
    $this->assertNotNull($order);
    $this->assertEquals(1, count($order->getItems()));
}
```

**Предложение:**
```php
public function testAddItem_IncreasesItemCount(): void
{
    // Arrange
    $order = new Order();
    $item = new Item('A', 10);

    // Act
    $order->addItem($item);

    // Assert
    $this->assertCount(1, $order->getItems());
}
```
```
