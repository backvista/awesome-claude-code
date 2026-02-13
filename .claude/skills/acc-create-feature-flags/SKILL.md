---
name: acc-create-feature-flags
description: Генерирует реализации feature flag для PHP проектов. Создает сервисы флагов, конфигурацию, процентный роллаут, таргетинг пользователей и интеграцию с пайплайнами развертывания.
---

# Feature Flag Generator

Генерирует реализацию feature flag для прогрессивного развертывания.

## Feature Flag Service Interface

```php
<?php
// src/Infrastructure/FeatureFlag/FeatureFlagServiceInterface.php

declare(strict_types=1);

namespace App\Infrastructure\FeatureFlag;

interface FeatureFlagServiceInterface
{
    /**
     * Проверить, включена ли функция глобально.
     */
    public function isEnabled(string $feature): bool;

    /**
     * Проверить, включена ли функция для конкретного пользователя.
     */
    public function isEnabledForUser(string $feature, string $userId): bool;

    /**
     * Проверить, включена ли функция на основе процентного роллаута.
     */
    public function isEnabledForPercentage(string $feature, string $identifier): bool;

    /**
     * Получить вариант для A/B тестирования.
     */
    public function getVariant(string $feature, string $userId): string;

    /**
     * Получить все включенные функции для пользователя.
     */
    public function getEnabledFeatures(string $userId): array;
}
```

## Feature Configuration DTO

```php
<?php
// src/Infrastructure/FeatureFlag/FeatureConfig.php

declare(strict_types=1);

namespace App\Infrastructure\FeatureFlag;

final readonly class FeatureConfig
{
    /**
     * @param string[] $allowedUsers
     * @param string[] $blockedUsers
     * @param string[] $variants
     * @param array<string, mixed> $metadata
     */
    public function __construct(
        public string $name,
        public bool $enabled = false,
        public ?int $percentage = null,
        public array $allowedUsers = [],
        public array $blockedUsers = [],
        public array $variants = [],
        public array $metadata = [],
    ) {}

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            name: $data['name'],
            enabled: $data['enabled'] ?? false,
            percentage: $data['percentage'] ?? null,
            allowedUsers: $data['allowed_users'] ?? [],
            blockedUsers: $data['blocked_users'] ?? [],
            variants: $data['variants'] ?? [],
            metadata: $data['metadata'] ?? [],
        );
    }
}
```

См. `references/templates.md` для: InMemory реализации, YAML конфигурации, загрузчика конфигурации, атрибута, middleware, Twig расширения, использования в шаблонах, интеграции CI/CD, Redis реализации.

## Инструкции по генерации

1. **Выбрать бэкенд хранения:**
   - In-memory (конфигурационный файл)
   - Redis (динамические обновления)
   - Database (audit trail)
   - Внешний сервис (LaunchDarkly, и т.д.)

2. **Определить типы флагов:**
   - Boolean (вкл/выкл)
   - Процентный роллаут
   - Таргетинг пользователей
   - A/B варианты

3. **Интеграция с фреймворком:**
   - Middleware для контекста запроса
   - Twig расширение для шаблонов
   - Сервис для бизнес-логики

4. **Настроить интеграцию CI/CD:**
   - Значения по умолчанию на основе окружения
   - Динамические эндпойнты обновления
   - Возможности отката

## Использование

Предоставить:
- Предпочтительный бэкенд хранения
- Фреймворк (Symfony, Laravel, и т.д.)
- Необходимые типы флагов
- Платформа CI/CD

Генератор:
1. Создаст интерфейс и реализацию
2. Добавит загрузчик конфигурации
3. Интегрирует с фреймворком
4. Настроит хуки CI/CD
