---
name: acc-clean-arch-knowledge
description: База знаний Clean Architecture. Предоставляет паттерны, антипаттерны и PHP-специфичные рекомендации для аудита Clean Architecture и Hexagonal Architecture.
---

# База знаний Clean Architecture

Краткий справочник по паттернам Clean Architecture / Hexagonal Architecture и рекомендациям по PHP-реализации.

## Ключевые принципы

### Правило зависимостей

```
┌────────────────────────────────────────────────────────────────┐
│                    FRAMEWORKS & DRIVERS                        │
│  (Web, UI, DB, External Services, Devices)                     │
├────────────────────────────────────────────────────────────────┤
│                    INTERFACE ADAPTERS                          │
│  (Controllers, Gateways, Presenters, Repositories)             │
├────────────────────────────────────────────────────────────────┤
│                    APPLICATION BUSINESS RULES                  │
│  (Use Cases, Application Services)                             │
├────────────────────────────────────────────────────────────────┤
│                    ENTERPRISE BUSINESS RULES                   │
│  (Entities, Value Objects, Domain Services)                    │
└────────────────────────────────────────────────────────────────┘
                              ▲
                              │
              Зависимости направлены ТОЛЬКО ВНУТРЬ
```

**Правило:** Зависимости исходного кода должны быть направлены ВНУТРЬ. Внутренние слои ничего не знают о внешних.

### Hexagonal Architecture (Ports & Adapters)

```
                    ┌─────────────────┐
                    │   Primary       │
                    │   Adapters      │
                    │  (Controllers)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
        ┌──────────►│     PORTS       │◄──────────┐
        │           │  (Interfaces)   │           │
        │           └────────┬────────┘           │
        │                    │                    │
        │                    ▼                    │
        │           ┌─────────────────┐           │
        │           │   APPLICATION   │           │
        │           │    (Use Cases)  │           │
        │           └────────┬────────┘           │
        │                    │                    │
        │                    ▼                    │
        │           ┌─────────────────┐           │
        │           │     DOMAIN      │           │
        │           │   (Entities)    │           │
        │           └─────────────────┘           │
        │                                         │
        │           ┌─────────────────┐           │
        └───────────│   Secondary     │───────────┘
                    │   Adapters      │
                    │ (Repositories,  │
                    │  External APIs) │
                    └─────────────────┘
```

**Правило:** Ядро приложения определяет Ports (интерфейсы). Adapters их реализуют.

## Быстрые чек-листы

### Чек-лист Domain Layer

- [ ] Нет импортов из внешних слоёв
- [ ] Нет зависимостей от фреймворков
- [ ] Чистая бизнес-логика
- [ ] Value Objects для концепций
- [ ] Entities с поведением
- [ ] Только интерфейсы Repository

### Чек-лист Application Layer

- [ ] Use Cases оркестрируют домен
- [ ] Определены Ports (интерфейсы) для внешних сервисов
- [ ] DTO для ввода/вывода
- [ ] Без инфраструктурных деталей
- [ ] Без зависимостей от фреймворков

### Чек-лист Interface Adapters

- [ ] Реализуют интерфейсы domain/application
- [ ] Controllers вызывают Use Cases
- [ ] Presenters форматируют вывод
- [ ] Без бизнес-логики

### Чек-лист Frameworks & Drivers

- [ ] Только конфигурация
- [ ] Настройка DI/wiring
- [ ] Фреймворк-специфичный код изолирован

## Краткий справочник частых нарушений

| Нарушение | Где искать | Серьёзность |
|-----------|-----------|-------------|
| Внутренний слой импортирует внешний | Domain/Application импортирует Infrastructure | Критично |
| Фреймворк в ядре | Doctrine/Symfony в Domain | Критично |
| Use Case с HTTP-деталями | Request/Response в Application | Критично |
| Бизнес-логика в Controller | if/switch по доменному состоянию | Предупреждение |
| Отсутствующий Port | Прямой вызов внешнего сервиса | Предупреждение |
| Adapter с логикой | Repository выполняет валидацию | Предупреждение |

## Паттерны Clean Architecture для PHP 8.2

### Port (Driven Port)

```php
// Application layer - defines the contract
namespace Application\Order\Port;

interface PaymentGatewayInterface
{
    public function charge(PaymentRequest $request): PaymentResponse;
    public function refund(string $transactionId, Money $amount): RefundResponse;
}
```

### Adapter (Driven Adapter)

```php
// Infrastructure layer - implements the contract
namespace Infrastructure\Payment;

final readonly class StripePaymentGateway implements PaymentGatewayInterface
{
    public function __construct(
        private StripeClient $stripe
    ) {}

    public function charge(PaymentRequest $request): PaymentResponse
    {
        $charge = $this->stripe->charges->create([
            'amount' => $request->amount->cents(),
            'currency' => $request->currency->value,
            'source' => $request->token,
        ]);

        return new PaymentResponse(
            transactionId: $charge->id,
            status: PaymentStatus::from($charge->status)
        );
    }
}
```

### Use Case (Application Service)

```php
namespace Application\Order\UseCase;

final readonly class ProcessPaymentUseCase
{
    public function __construct(
        private OrderRepositoryInterface $orders,
        private PaymentGatewayInterface $paymentGateway,  // Port
        private EventDispatcherInterface $events
    ) {}

    public function execute(ProcessPaymentCommand $command): PaymentResult
    {
        $order = $this->orders->findById($command->orderId);

        $payment = $this->paymentGateway->charge(
            new PaymentRequest($order->total(), $command->paymentToken)
        );

        if ($payment->isSuccessful()) {
            $order->markAsPaid($payment->transactionId());
            $this->orders->save($order);
        }

        return new PaymentResult($payment->transactionId(), $payment->status());
    }
}
```

### Controller (Driving Adapter)

```php
namespace Presentation\Api\Order;

final readonly class PaymentController
{
    public function __construct(
        private ProcessPaymentUseCase $processPayment
    ) {}

    public function process(Request $request): JsonResponse
    {
        $command = new ProcessPaymentCommand(
            orderId: new OrderId($request->get('order_id')),
            paymentToken: $request->get('payment_token')
        );

        $result = $this->processPayment->execute($command);

        return new JsonResponse([
            'transaction_id' => $result->transactionId,
            'status' => $result->status->value,
        ]);
    }
}
```

## Ссылки

Для подробной информации загрузите файлы ссылок:

- `references/dependency-rule.md` — Правило зависимостей с пояснением
- `references/layer-boundaries.md` — Ответственности и границы слоёв
- `references/port-adapter-patterns.md` — Паттерны Hexagonal Architecture
- `references/antipatterns.md` — Частые нарушения с паттернами обнаружения
