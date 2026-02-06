---
name: acc-create-deptrac-config
description: Generates DEPTRAC configurations for PHP projects. Creates deptrac.yaml with DDD layer rules, bounded context separation, and dependency constraints.
---

# DEPTRAC Configuration Generator

Generates optimized DEPTRAC configurations for architectural dependency analysis.

## Generated Files

```
deptrac.yaml              # Main configuration
deptrac-baseline.yaml     # Violation baseline (if needed)
```

## Configuration by Architecture

### DDD Layered Architecture

```yaml
# deptrac.yaml
deptrac:
  paths:
    - ./src

  layers:
    #############################################
    # Domain Layer (innermost)
    #############################################
    - name: Domain
      collectors:
        - type: directory
          value: src/Domain/.*

    # Domain sublayers
    - name: Domain.Entity
      collectors:
        - type: directory
          value: src/Domain/.*/Entity/.*

    - name: Domain.ValueObject
      collectors:
        - type: directory
          value: src/Domain/.*/ValueObject/.*

    - name: Domain.Event
      collectors:
        - type: directory
          value: src/Domain/.*/Event/.*

    - name: Domain.Repository
      collectors:
        - type: directory
          value: src/Domain/.*/Repository/.*

    - name: Domain.Service
      collectors:
        - type: directory
          value: src/Domain/.*/Service/.*

    #############################################
    # Application Layer
    #############################################
    - name: Application
      collectors:
        - type: directory
          value: src/Application/.*

    - name: Application.UseCase
      collectors:
        - type: directory
          value: src/Application/.*/UseCase/.*

    - name: Application.Command
      collectors:
        - type: directory
          value: src/Application/.*/Command/.*

    - name: Application.Query
      collectors:
        - type: directory
          value: src/Application/.*/Query/.*

    - name: Application.DTO
      collectors:
        - type: directory
          value: src/Application/.*/DTO/.*

    #############################################
    # Infrastructure Layer
    #############################################
    - name: Infrastructure
      collectors:
        - type: directory
          value: src/Infrastructure/.*

    - name: Infrastructure.Persistence
      collectors:
        - type: directory
          value: src/Infrastructure/Persistence/.*

    - name: Infrastructure.Messaging
      collectors:
        - type: directory
          value: src/Infrastructure/Messaging/.*

    - name: Infrastructure.External
      collectors:
        - type: directory
          value: src/Infrastructure/External/.*

    #############################################
    # Presentation Layer (outermost)
    #############################################
    - name: Presentation
      collectors:
        - type: directory
          value: src/(Api|Web|Console)/.*

    - name: Presentation.Api
      collectors:
        - type: directory
          value: src/Api/.*

    - name: Presentation.Web
      collectors:
        - type: directory
          value: src/Web/.*

    - name: Presentation.Console
      collectors:
        - type: directory
          value: src/Console/.*

  #############################################
  # Dependency Rules
  #############################################
  ruleset:
    # Domain has NO dependencies (except language primitives)
    Domain: []
    Domain.Entity: []
    Domain.ValueObject: []
    Domain.Event: []
    Domain.Repository: []  # Only interfaces
    Domain.Service:
      - Domain.Entity
      - Domain.ValueObject
      - Domain.Event
      - Domain.Repository

    # Application depends only on Domain
    Application:
      - Domain
    Application.UseCase:
      - Domain
      - Application.DTO
      - Application.Command
      - Application.Query
    Application.Command:
      - Domain
    Application.Query:
      - Domain
    Application.DTO:
      - Domain.ValueObject  # Can use VOs for type safety

    # Infrastructure implements Domain interfaces
    Infrastructure:
      - Domain
      - Application
    Infrastructure.Persistence:
      - Domain.Entity
      - Domain.Repository
      - Domain.ValueObject
    Infrastructure.Messaging:
      - Domain.Event
      - Application.Command
    Infrastructure.External:
      - Domain
      - Application

    # Presentation depends on Application
    Presentation:
      - Application
      - Domain  # For DTOs, VOs in responses
    Presentation.Api:
      - Application.UseCase
      - Application.DTO
      - Domain.ValueObject
    Presentation.Web:
      - Application.UseCase
      - Application.DTO
    Presentation.Console:
      - Application.UseCase
      - Application.Command
```

### Bounded Context Separation

```yaml
# deptrac.yaml - Multi-bounded context
deptrac:
  paths:
    - ./src

  layers:
    #############################################
    # Bounded Context: Order
    #############################################
    - name: Order
      collectors:
        - type: directory
          value: src/Order/.*

    - name: Order.Domain
      collectors:
        - type: directory
          value: src/Order/Domain/.*

    - name: Order.Application
      collectors:
        - type: directory
          value: src/Order/Application/.*

    - name: Order.Infrastructure
      collectors:
        - type: directory
          value: src/Order/Infrastructure/.*

    #############################################
    # Bounded Context: Payment
    #############################################
    - name: Payment
      collectors:
        - type: directory
          value: src/Payment/.*

    - name: Payment.Domain
      collectors:
        - type: directory
          value: src/Payment/Domain/.*

    - name: Payment.Application
      collectors:
        - type: directory
          value: src/Payment/Application/.*

    #############################################
    # Bounded Context: Shipping
    #############################################
    - name: Shipping
      collectors:
        - type: directory
          value: src/Shipping/.*

    #############################################
    # Shared Kernel
    #############################################
    - name: SharedKernel
      collectors:
        - type: directory
          value: src/SharedKernel/.*

  ruleset:
    # Shared Kernel is available to all
    SharedKernel: []

    # Each context depends only on SharedKernel
    Order.Domain:
      - SharedKernel
    Order.Application:
      - Order.Domain
      - SharedKernel
    Order.Infrastructure:
      - Order.Domain
      - Order.Application
      - SharedKernel

    Payment.Domain:
      - SharedKernel
    Payment.Application:
      - Payment.Domain
      - SharedKernel

    Shipping:
      - SharedKernel

    # Cross-context communication via events/ACL
    # NOT direct dependencies!
```

### Hexagonal Architecture

```yaml
# deptrac.yaml - Ports & Adapters
deptrac:
  paths:
    - ./src

  layers:
    # Core Domain
    - name: Core
      collectors:
        - type: directory
          value: src/Core/.*

    # Ports (interfaces)
    - name: Port.Inbound
      collectors:
        - type: directory
          value: src/Port/Inbound/.*

    - name: Port.Outbound
      collectors:
        - type: directory
          value: src/Port/Outbound/.*

    # Adapters (implementations)
    - name: Adapter.Primary
      collectors:
        - type: directory
          value: src/Adapter/Primary/.*

    - name: Adapter.Secondary
      collectors:
        - type: directory
          value: src/Adapter/Secondary/.*

  ruleset:
    # Core has no dependencies
    Core: []

    # Ports depend on Core
    Port.Inbound:
      - Core
    Port.Outbound:
      - Core

    # Adapters depend on Ports
    Adapter.Primary:
      - Port.Inbound
      - Core
    Adapter.Secondary:
      - Port.Outbound
      - Core
```

## Advanced Collectors

### Class Name Pattern

```yaml
layers:
  - name: Controllers
    collectors:
      - type: classNameRegex
        value: /.*Controller$/

  - name: Repositories
    collectors:
      - type: classNameRegex
        value: /.*Repository$/

  - name: Services
    collectors:
      - type: classNameRegex
        value: /.*Service$/
```

### Interface Implementation

```yaml
layers:
  - name: EventHandlers
    collectors:
      - type: implements
        value: App\Domain\EventHandler

  - name: CommandHandlers
    collectors:
      - type: implements
        value: App\Application\CommandHandler
```

### Attribute-based

```yaml
layers:
  - name: Aggregates
    collectors:
      - type: attribute
        value: App\Attribute\Aggregate
```

### Combined Collectors

```yaml
layers:
  - name: DomainServices
    collectors:
      - type: bool
        must:
          - type: directory
            value: src/Domain/.*
          - type: classNameRegex
            value: /.*Service$/
        must_not:
          - type: classNameRegex
            value: /.*Test$/
```

## Baseline Management

```yaml
# deptrac.yaml
deptrac:
  paths:
    - ./src

  baseline: deptrac-baseline.yaml

  # ... layers and ruleset
```

### Generate Baseline

```bash
# Generate baseline for current violations
vendor/bin/deptrac analyse --baseline=deptrac-baseline.yaml

# Analyze with baseline
vendor/bin/deptrac analyse
```

## CI Configuration

### GitHub Actions

```yaml
deptrac:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: shivammathur/setup-php@v2
      with:
        php-version: '8.4'
    - run: composer install
    - run: vendor/bin/deptrac analyse --fail-on-uncovered
```

### GitLab CI

```yaml
deptrac:
  script:
    - vendor/bin/deptrac analyse --formatter=junit --output=deptrac-report.xml
  artifacts:
    reports:
      junit: deptrac-report.xml
```

## Output Formats

```bash
# Console (default)
vendor/bin/deptrac analyse

# JUnit for CI
vendor/bin/deptrac analyse --formatter=junit --output=deptrac.xml

# GraphViz
vendor/bin/deptrac analyse --formatter=graphviz --output=deptrac.dot

# JSON
vendor/bin/deptrac analyse --formatter=json --output=deptrac.json
```

## Common Violations and Fixes

### Domain → Infrastructure

```
VIOLATION: Domain\Order\OrderService depends on Infrastructure\Doctrine\OrderRepository

FIX: Use interface in Domain, implementation in Infrastructure
- Domain\Order\Repository\OrderRepositoryInterface (interface)
- Infrastructure\Persistence\DoctrineOrderRepository (implementation)
```

### Cross-Context Dependency

```
VIOLATION: Order\Application\OrderService depends on Payment\Domain\Payment

FIX: Use Anti-Corruption Layer or Events
- Order emits OrderPlacedEvent
- Payment subscribes to event
- Or use ACL: Order\Infrastructure\PaymentGateway
```

## Generation Instructions

1. **Analyze project:**
   - Identify architecture style (DDD, Hexagonal, etc.)
   - Map directory structure
   - Find bounded contexts

2. **Define layers:**
   - Start with main layers (Domain, Application, Infrastructure, Presentation)
   - Add sublayers if needed
   - Create bounded context layers if multi-context

3. **Define rules:**
   - Domain depends on nothing
   - Each layer depends only on inner layers
   - Cross-context only via SharedKernel/Events

4. **Handle violations:**
   - Generate baseline for existing violations
   - Plan refactoring to remove violations

## Usage

Provide:
- Project path
- Architecture style (DDD/Hexagonal/Layered)
- Bounded contexts (if any)
- Current violations to baseline (optional)

The generator will:
1. Analyze directory structure
2. Create appropriate layers
3. Define dependency rules
4. Generate baseline if needed
