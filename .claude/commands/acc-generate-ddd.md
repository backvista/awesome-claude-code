---
description: Generate DDD components. Creates entities, value objects, aggregates, commands, queries, repositories, domain services, factories, specifications, DTOs, ACL, and use cases for PHP 8.2.
allowed-tools: Read, Write, Edit, Glob, Grep, Task
model: opus
argument-hint: <component-type> <ComponentName> [-- additional instructions]
---

# Generate DDD Components

Generate Domain-Driven Design components for PHP 8.2 with tests and proper layer placement.

## Input Parsing

Parse `$ARGUMENTS` to extract component type, name, and optional meta-instructions:

```
Format: <component-type> <ComponentName> [-- <meta-instructions>]

Examples:
- /acc-generate-ddd entity Order
- /acc-generate-ddd vo Email
- /acc-generate-ddd aggregate Order -- with OrderLine child entity
- /acc-generate-ddd command CreateOrder
- /acc-generate-ddd query GetOrderById
```

**Parsing rules:**
1. First part = **component type** (required, see list below)
2. Second part = **component name** (required)
3. After ` -- ` = **meta-instructions** (optional customizations)

## Supported Components

### Domain Layer Components

| Component | Aliases | Skill Used |
|-----------|---------|------------|
| `entity` | `ent` | acc-create-entity |
| `value-object` | `vo`, `valueobject` | acc-create-value-object |
| `aggregate` | `agg`, `aggregate-root` | acc-create-aggregate |
| `domain-event` | `event`, `de` | acc-create-domain-event |
| `repository` | `repo` | acc-create-repository |
| `domain-service` | `service`, `ds` | acc-create-domain-service |
| `factory` | `fact` | acc-create-factory |
| `specification` | `spec` | acc-create-specification |

### Application Layer Components

| Component | Aliases | Skill Used |
|-----------|---------|------------|
| `command` | `cmd` | acc-create-command |
| `query` | `qry` | acc-create-query |
| `use-case` | `usecase`, `uc` | acc-create-use-case |
| `dto` | `data-transfer` | acc-create-dto |

### Integration Layer Components

| Component | Aliases | Skill Used |
|-----------|---------|------------|
| `acl` | `anti-corruption` | acc-create-anti-corruption-layer |

## Pre-flight Check

1. Verify valid component type:
   - If not provided, ask user which component to generate
   - If invalid, show list of supported components

2. Check project structure:
   - Read `composer.json` for namespace configuration
   - Determine target directory based on component type

## Instructions

Use the `acc-ddd-generator` agent to generate DDD components:

```
Task tool with subagent_type="acc-ddd-generator"
prompt: "Generate [COMPONENT_TYPE] named [COMPONENT_NAME]. [META-INSTRUCTIONS if provided]

Requirements:
1. PHP 8.2 with declare(strict_types=1)
2. PSR-12 coding style
3. Final readonly classes where appropriate
4. Constructor property promotion
5. Include related components (exceptions, enums)
6. Include unit tests
7. Follow existing project patterns"
```

## Generation Examples

### Domain Layer

#### Entity
```bash
/acc-generate-ddd entity Order
/acc-generate-ddd ent User -- with soft delete
```

Generates:
```
src/Domain/Order/Entity/
├── Order.php
└── OrderId.php (Value Object)
tests/Unit/Domain/Order/Entity/
└── OrderTest.php
```

#### Value Object
```bash
/acc-generate-ddd value-object Email
/acc-generate-ddd vo Money -- with currency support
```

Generates:
```
src/Domain/User/ValueObject/
├── Email.php
└── Exception/InvalidEmailException.php
tests/Unit/Domain/User/ValueObject/
└── EmailTest.php
```

#### Aggregate
```bash
/acc-generate-ddd aggregate Order
/acc-generate-ddd agg ShoppingCart -- with CartItem child entity
```

Generates:
```
src/Domain/Order/Entity/
├── Order.php (Aggregate Root)
├── OrderLine.php (Child Entity)
├── OrderId.php
└── OrderStatus.php (Enum)
src/Domain/Order/Event/
└── OrderCreatedEvent.php
tests/Unit/Domain/Order/Entity/
├── OrderTest.php
└── OrderLineTest.php
```

#### Domain Event
```bash
/acc-generate-ddd domain-event OrderConfirmed
/acc-generate-ddd event UserRegistered
```

Generates:
```
src/Domain/Order/Event/
└── OrderConfirmedEvent.php
tests/Unit/Domain/Order/Event/
└── OrderConfirmedEventTest.php
```

#### Repository
```bash
/acc-generate-ddd repository Order
/acc-generate-ddd repo User -- Doctrine implementation
```

Generates:
```
src/Domain/Order/Repository/
└── OrderRepositoryInterface.php
src/Infrastructure/Persistence/Doctrine/
└── DoctrineOrderRepository.php
tests/Unit/Domain/Order/Repository/
└── InMemoryOrderRepository.php
```

#### Domain Service
```bash
/acc-generate-ddd domain-service MoneyTransfer
/acc-generate-ddd ds PriceCalculator -- with discount rules
```

Generates:
```
src/Domain/Payment/Service/
└── MoneyTransferService.php
tests/Unit/Domain/Payment/Service/
└── MoneyTransferServiceTest.php
```

#### Factory
```bash
/acc-generate-ddd factory Order
/acc-generate-ddd fact User -- from external API
```

Generates:
```
src/Domain/Order/Factory/
└── OrderFactory.php
tests/Unit/Domain/Order/Factory/
└── OrderFactoryTest.php
```

#### Specification
```bash
/acc-generate-ddd specification IsActiveCustomer
/acc-generate-ddd spec CanPlaceOrder -- composite
```

Generates:
```
src/Domain/Customer/Specification/
└── IsActiveCustomerSpecification.php
tests/Unit/Domain/Customer/Specification/
└── IsActiveCustomerSpecificationTest.php
```

### Application Layer

#### Command
```bash
/acc-generate-ddd command CreateOrder
/acc-generate-ddd cmd UpdateUserProfile
```

Generates:
```
src/Application/Order/Command/
├── CreateOrderCommand.php
└── CreateOrderHandler.php
tests/Unit/Application/Order/Command/
├── CreateOrderCommandTest.php
└── CreateOrderHandlerTest.php
```

#### Query
```bash
/acc-generate-ddd query GetOrderDetails
/acc-generate-ddd qry ListUserOrders -- with pagination
```

Generates:
```
src/Application/Order/Query/
├── GetOrderDetailsQuery.php
└── GetOrderDetailsHandler.php
tests/Unit/Application/Order/Query/
├── GetOrderDetailsQueryTest.php
└── GetOrderDetailsHandlerTest.php
```

#### Use Case
```bash
/acc-generate-ddd use-case ProcessPayment
/acc-generate-ddd uc RegisterUser -- with email verification
```

Generates:
```
src/Application/Payment/UseCase/
└── ProcessPaymentUseCase.php
tests/Unit/Application/Payment/UseCase/
└── ProcessPaymentUseCaseTest.php
```

#### DTO
```bash
/acc-generate-ddd dto OrderRequest
/acc-generate-ddd data-transfer UserResponse -- for REST API
```

Generates:
```
src/Application/Order/DTO/
└── OrderRequestDto.php
tests/Unit/Application/Order/DTO/
└── OrderRequestDtoTest.php
```

### Integration Layer

#### Anti-Corruption Layer
```bash
/acc-generate-ddd acl StripePayment
/acc-generate-ddd anti-corruption ExternalCrm -- translate to domain
```

Generates:
```
src/Infrastructure/ACL/Stripe/
├── StripePaymentAdapter.php
├── StripePaymentTranslator.php
└── StripePaymentFacade.php
tests/Unit/Infrastructure/ACL/Stripe/
└── StripePaymentAdapterTest.php
```

## Expected Output

### Generated Files Summary

```
Generated Entity: Order

Files created:
├── src/Domain/Order/Entity/
│   ├── Order.php
│   └── OrderId.php
├── src/Domain/Order/Exception/
│   └── InvalidOrderException.php
└── tests/Unit/Domain/Order/Entity/
    └── OrderTest.php
```

### File Structure by Layer

```
Domain Layer:
├── Entity/     → Entities, Aggregates, Child Entities
├── ValueObject/ → Value Objects, IDs
├── Repository/ → Repository Interfaces
├── Service/    → Domain Services
├── Factory/    → Domain Factories
├── Specification/ → Business Rules
├── Event/      → Domain Events
├── Enum/       → Status, Type enums
└── Exception/  → Domain Exceptions

Application Layer:
├── Command/    → Commands + Handlers
├── Query/      → Queries + Handlers
├── UseCase/    → Use Cases
├── DTO/        → Data Transfer Objects
└── ReadModel/  → Read Model Interfaces

Infrastructure Layer:
├── Persistence/ → Repository Implementations
└── ACL/         → Anti-Corruption Layers
```

## Multiple Components

Generate related components together:

```bash
# Generate full aggregate
/acc-generate-ddd aggregate Order
/acc-generate-ddd command CreateOrder
/acc-generate-ddd query GetOrderById

# Generate CQRS stack
/acc-generate-ddd command UpdateOrder
/acc-generate-ddd query ListOrders -- with filters
```

## Usage Examples

```bash
/acc-generate-ddd entity Order
/acc-generate-ddd vo Email -- with DNS validation
/acc-generate-ddd aggregate ShoppingCart -- with CartItem child
/acc-generate-ddd command CreateOrder
/acc-generate-ddd query GetUserOrders -- with pagination
/acc-generate-ddd use-case ProcessPayment -- with retry logic
/acc-generate-ddd repository Order -- Doctrine implementation
/acc-generate-ddd dto OrderRequest -- for REST API
/acc-generate-ddd acl StripePayment -- translate to domain Money
```
