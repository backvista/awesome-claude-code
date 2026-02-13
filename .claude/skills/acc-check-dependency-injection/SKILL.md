---
name: acc-check-dependency-injection
description: Анализирует PHP-код на проблемы внедрения зависимостей. Обнаруживает использование constructor injection, зависимости от интерфейсов, антипаттерн service locator, ключевое слово new в бизнес-логике.
---

# Проверка внедрения зависимостей

Анализ PHP-кода на корректное применение паттернов внедрения зависимостей.

## Паттерны обнаружения

### 1. Ключевое слово New в бизнес-логике

```php
// BAD: Hard-coded dependency
class OrderService
{
    public function process(Order $order): void
    {
        $mailer = new Mailer(); // Can't mock this
        $mailer->send($order->getCustomer(), 'confirmation');
    }
}

// GOOD: Injected dependency
class OrderService
{
    public function __construct(
        private MailerInterface $mailer,
    ) {}

    public function process(Order $order): void
    {
        $this->mailer->send($order->getCustomer(), 'confirmation');
    }
}
```

### 2. Антипаттерн Service Locator

```php
// BAD: Service locator
class UserService
{
    public function register(UserData $data): User
    {
        $hasher = Container::get(PasswordHasher::class);
        $repository = Container::get(UserRepository::class);
        $mailer = Container::get(Mailer::class);

        // Dependencies are hidden
    }
}

// GOOD: Constructor injection
class UserService
{
    public function __construct(
        private PasswordHasher $hasher,
        private UserRepository $repository,
        private Mailer $mailer,
    ) {}

    // Dependencies are explicit
}
```

### 3. Вызовы статических методов

```php
// BAD: Static calls can't be mocked
class ReportGenerator
{
    public function generate(): Report
    {
        $data = Database::query('SELECT ...');  // Static
        $date = Carbon::now();                   // Static
        $id = Uuid::uuid4();                     // Static

        return new Report($data, $date, $id);
    }
}

// GOOD: Injectable services
class ReportGenerator
{
    public function __construct(
        private Connection $database,
        private ClockInterface $clock,
        private UuidGenerator $uuidGenerator,
    ) {}

    public function generate(): Report
    {
        $data = $this->database->query('SELECT ...');
        $date = $this->clock->now();
        $id = $this->uuidGenerator->generate();

        return new Report($data, $date, $id);
    }
}
```

### 4. Отсутствие интерфейса

```php
// BAD: Concrete class dependency
class PaymentProcessor
{
    public function __construct(
        private StripeGateway $gateway, // Concrete class
    ) {}
}

// GOOD: Interface dependency
class PaymentProcessor
{
    public function __construct(
        private PaymentGatewayInterface $gateway, // Interface
    ) {}
}
```

### 5. Скрытые зависимости

```php
// BAD: Uses global/superglobal
class UserController
{
    public function current(): User
    {
        $userId = $_SESSION['user_id']; // Hidden dependency
        return $this->repository->find($userId);
    }
}

// GOOD: Explicit dependency
class UserController
{
    public function __construct(
        private SessionInterface $session,
        private UserRepository $repository,
    ) {}

    public function current(): User
    {
        $userId = $this->session->get('user_id');
        return $this->repository->find($userId);
    }
}
```

### 6. Проблемы setter injection

```php
// BAD: Optional setter injection
class OrderService
{
    private ?Logger $logger = null;

    public function setLogger(Logger $logger): void
    {
        $this->logger = $logger;
    }

    public function process(): void
    {
        $this->logger?->info('Processing'); // May be null
    }
}

// GOOD: Constructor injection
class OrderService
{
    public function __construct(
        private LoggerInterface $logger,
    ) {}

    public function process(): void
    {
        $this->logger->info('Processing');
    }
}
```

### 7. Фабрика внутри класса

```php
// BAD: Factory logic in service
class NotificationService
{
    public function send(string $type, string $message): void
    {
        $channel = match($type) {
            'email' => new EmailChannel(),
            'sms' => new SmsChannel(),
            'push' => new PushChannel(),
        };
        $channel->send($message);
    }
}

// GOOD: Inject factory
class NotificationService
{
    public function __construct(
        private ChannelFactory $channelFactory,
    ) {}

    public function send(string $type, string $message): void
    {
        $channel = $this->channelFactory->create($type);
        $channel->send($message);
    }
}
```

### 8. Доступ к окружению/конфигурации

```php
// BAD: Direct environment access
class ApiClient
{
    public function request(): Response
    {
        $key = getenv('API_KEY'); // Hidden dependency
        // ...
    }
}

// GOOD: Config injection
class ApiClient
{
    public function __construct(
        private string $apiKey, // Or ApiConfig object
    ) {}
}
```

## Grep-паттерны

```bash
# New keyword in methods
Grep: "new\s+[A-Z]\w+\(" --glob "**/*.php"

# Service locator
Grep: "Container::(get|make)|App::(make|resolve)" --glob "**/*.php"

# Static method calls
Grep: "[A-Z]\w+::\w+\(" --glob "**/*.php"

# Superglobals
Grep: "\$_(GET|POST|SESSION|COOKIE|ENV|SERVER)" --glob "**/*.php"

# getenv/putenv
Grep: "(getenv|putenv)\(" --glob "**/*.php"
```

## Допустимое использование New

```php
// OK: Value objects and DTOs
new Money(100, 'USD');
new DateTime('now');
new OrderId($uuid);

// OK: Exceptions
throw new InvalidArgumentException();

// OK: In factories (that's their job)
class UserFactory {
    public function create(): User {
        return new User();
    }
}
```

## Классификация серьёзности

| Паттерн | Серьёзность |
|---------|-------------|
| Service locator | Major |
| New для сервисов | Major |
| Вызовы статических методов | Major |
| Доступ к суперглобалам | Major |
| Отсутствие интерфейса | Minor |
| Setter injection | Minor |

## Формат вывода

```markdown
### Проблема DI: [Описание]

**Серьёзность:** Major/Minor
**Расположение:** `file.php:line`
**Тип:** [Service Locator|New Keyword|Static Call|...]

**Проблема:**
[Описание проблемы DI]

**Текущий код:**
```php
$mailer = new Mailer();
```

**Рекомендация:**
```php
public function __construct(
    private MailerInterface $mailer,
) {}
```

**Влияние на тестирование:**
Невозможно замокать Mailer в юнит-тестах. С инъекцией тесты могут использовать MockMailer.
```
