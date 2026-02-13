---
name: acc-ci-tools-knowledge
description: База знаний PHP CI-инструментов. Содержит уровни и конфигурацию PHPStan, интеграцию Psalm, правила PHP-CS-Fixer, анализ слоёв DEPTRAC, автоматический рефакторинг Rector и инструменты покрытия кода.
---

# База знаний PHP CI-инструментов

Краткий справочник по инструментам статического анализа, качества кода и тестирования PHP.

## PHPStan

### Обзор уровней

| Уровень | Описание | Применение |
|-------|-------------|----------|
| 0 | Базовые проверки (неопределённые переменные, классы) | Унаследованные проекты, быстрый старт |
| 1 | + Неопределённые методы, свойства | Минимальная безопасность |
| 2 | + Неизвестные методы на `$this` | Средняя безопасность |
| 3 | + Типы возврата | Рекомендуемый минимум |
| 4 | + Мёртвый код, недостижимый | **Рекомендуется для новых проектов** |
| 5 | + Типы аргументов | Стандартное соответствие |
| 6 | + Отсутствующие typehints | Строгая типизация |
| 7 | + Строгие union-типы | Высокая строгость |
| 8 | + Без mixed, nullsafe | **Рекомендуется для production** |
| 9 | + Максимальная строгость | Clean Architecture |
| max | Экспериментальные правила | Только для экспериментов |

### Шаблон конфигурации

```neon
# phpstan.neon
includes:
    - vendor/phpstan/phpstan-strict-rules/rules.neon
    - vendor/phpstan/phpstan-deprecation-rules/rules.neon
    - vendor/phpstan/phpstan-phpunit/extension.neon
    - phpstan-baseline.neon

parameters:
    level: 8
    paths:
        - src
        - tests
    excludePaths:
        - src/Infrastructure/Legacy/*
        - tests/Fixtures/*

    # PHP version
    phpVersion: 80400

    # Strict rules
    checkMissingIterableValueType: true
    checkGenericClassInNonGenericObjectType: true
    checkUninitializedProperties: true

    # Custom rules
    ignoreErrors:
        - '#Call to an undefined method [a-zA-Z0-9\\_]+::getId\(\)#'

    # Type aliases
    typeAliases:
        UserId: 'string'

    # Parallel processing
    parallel:
        maximumNumberOfProcesses: 4
```

### Распространённые расширения

| Расширение | Назначение |
|-----------|---------|
| `phpstan-strict-rules` | Дополнительные строгие проверки |
| `phpstan-deprecation-rules` | Обнаружение использования устаревшего кода |
| `phpstan-phpunit` | Поддержка PHPUnit |
| `phpstan-doctrine` | Поддержка Doctrine ORM |
| `phpstan-symfony` | Поддержка контейнера Symfony |

### Управление baseline

```bash
# Generate baseline (for existing projects)
vendor/bin/phpstan analyse --generate-baseline

# Analyze with baseline
vendor/bin/phpstan analyse

# CI command
vendor/bin/phpstan analyse --no-progress --error-format=checkstyle > phpstan-report.xml
```

## Psalm

### Уровни ошибок

| Уровень | Описание |
|-------|-------------|
| 1 | Максимальная строгость (рекомендуется для новых) |
| 2 | Очень строгий |
| 3 | Строгий (рекомендуется для существующих) |
| 4 | Ослабленный |
| 5-8 | Постепенно более разрешительные |

### Шаблон конфигурации

```xml
<!-- psalm.xml -->
<?xml version="1.0"?>
<psalm
    errorLevel="2"
    resolveFromConfigFile="true"
    findUnusedBaselineEntry="true"
    findUnusedCode="true"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="https://getpsalm.org/schema/config"
    xsi:schemaLocation="https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd"
>
    <projectFiles>
        <directory name="src"/>
        <ignoreFiles>
            <directory name="vendor"/>
            <directory name="src/Infrastructure/Legacy"/>
        </ignoreFiles>
    </projectFiles>

    <issueHandlers>
        <MixedAssignment errorLevel="suppress"/>
        <PropertyNotSetInConstructor>
            <errorLevel type="suppress">
                <directory name="src/Infrastructure/Doctrine"/>
            </errorLevel>
        </PropertyNotSetInConstructor>
    </issueHandlers>

    <plugins>
        <pluginClass class="Psalm\PhpUnitPlugin\Plugin"/>
        <pluginClass class="Psalm\SymfonyPsalmPlugin\Plugin"/>
    </plugins>
</psalm>
```

### Полезные команды

```bash
# Full analysis
vendor/bin/psalm

# Generate baseline
vendor/bin/psalm --set-baseline=psalm-baseline.xml

# Security analysis
vendor/bin/psalm --taint-analysis

# CI output
vendor/bin/psalm --output-format=checkstyle > psalm-report.xml
```

## PHP-CS-Fixer

### Шаблон конфигурации

```php
<?php
// .php-cs-fixer.dist.php

declare(strict_types=1);

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

$finder = Finder::create()
    ->in([
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ])
    ->exclude([
        'var',
        'vendor',
    ]);

return (new Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PER-CS2.0' => true,
        '@PER-CS2.0:risky' => true,
        '@PHP84Migration' => true,
        '@PHP80Migration:risky' => true,
        '@PHPUnit100Migration:risky' => true,

        // Strict rules
        'declare_strict_types' => true,
        'strict_param' => true,
        'strict_comparison' => true,

        // Modern PHP
        'array_syntax' => ['syntax' => 'short'],
        'modernize_strpos' => true,
        'no_alias_functions' => true,
        'void_return' => true,

        // Clean code
        'no_unused_imports' => true,
        'ordered_imports' => ['imports_order' => ['class', 'function', 'const']],
        'single_line_throw' => false,
        'trailing_comma_in_multiline' => true,

        // DocBlocks
        'no_superfluous_phpdoc_tags' => true,
        'phpdoc_align' => false,
        'phpdoc_separation' => true,
    ])
    ->setFinder($finder)
    ->setCacheFile('.php-cs-fixer.cache');
```

### Команды

```bash
# Check (dry run)
vendor/bin/php-cs-fixer fix --dry-run --diff

# Fix
vendor/bin/php-cs-fixer fix

# CI check
vendor/bin/php-cs-fixer fix --dry-run --format=checkstyle > cs-report.xml
```

## DEPTRAC

### Шаблон конфигурации

```yaml
# deptrac.yaml
deptrac:
  paths:
    - ./src

  layers:
    - name: Domain
      collectors:
        - type: directory
          value: src/Domain/.*

    - name: Application
      collectors:
        - type: directory
          value: src/Application/.*

    - name: Infrastructure
      collectors:
        - type: directory
          value: src/Infrastructure/.*

    - name: Presentation
      collectors:
        - type: directory
          value: src/(Api|Web|Console)/.*

  ruleset:
    Domain: []  # Domain depends on nothing

    Application:
      - Domain

    Infrastructure:
      - Domain
      - Application

    Presentation:
      - Application
      - Domain

  skip_violations:
    # Temporary violations during migration
    App\Infrastructure\Legacy\*:
      - App\Domain\*
```

### Команды

```bash
# Analyze
vendor/bin/deptrac analyse

# With baseline
vendor/bin/deptrac analyse --baseline=deptrac-baseline.yaml

# CI output
vendor/bin/deptrac analyse --formatter=junit --output=deptrac-report.xml
```

## Rector

### Шаблон конфигурации

```php
<?php
// rector.php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\PHPUnit\Set\PHPUnitSetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ])
    ->withSkip([
        __DIR__ . '/src/Infrastructure/Legacy',
    ])
    ->withPhpSets(php84: true)
    ->withSets([
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION,
        PHPUnitSetList::PHPUNIT_100,
    ])
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        typeDeclarations: true,
        privatization: true,
        earlyReturn: true,
    );
```

### Команды

```bash
# Preview changes (dry run)
vendor/bin/rector process --dry-run

# Apply changes
vendor/bin/rector process

# Single file
vendor/bin/rector process src/Domain/Order.php
```

## Инструменты покрытия кода

### Покрытие PHPUnit

```xml
<!-- phpunit.xml -->
<phpunit>
    <coverage>
        <report>
            <clover outputFile="coverage.xml"/>
            <html outputDirectory="coverage-html"/>
            <text outputFile="coverage.txt"/>
        </report>
        <include>
            <directory suffix=".php">src</directory>
        </include>
        <exclude>
            <directory>src/Infrastructure/Legacy</directory>
        </exclude>
    </coverage>
</phpunit>
```

### Драйверы покрытия

| Драйвер | Скорость | Точность | Применение |
|--------|-------|----------|----------|
| Xdebug | Медленный | Высокая | Локальная разработка, точные метрики |
| PCOV | Быстрый | Высокая | CI, быстрая обратная связь |
| PHPDBG | Средний | Средняя | Альтернатива |

### Интеграция с CI

```yaml
# GitHub Actions with PCOV
- uses: shivammathur/setup-php@v2
  with:
    php-version: '8.4'
    coverage: pcov

- run: vendor/bin/phpunit --coverage-clover coverage.xml

- uses: codecov/codecov-action@v4
  with:
    files: coverage.xml
```

## Infection (мутационное тестирование)

### Конфигурация

```json
{
    "$schema": "vendor/infection/infection/resources/schema.json",
    "source": {
        "directories": ["src"]
    },
    "logs": {
        "text": "infection.log",
        "html": "infection.html"
    },
    "mutators": {
        "@default": true
    },
    "minMsi": 80,
    "minCoveredMsi": 90
}
```

### Команды

```bash
# Run with coverage
vendor/bin/infection --threads=4

# CI mode
vendor/bin/infection --min-msi=80 --min-covered-msi=90 --threads=max
```

## Матрица сравнения инструментов

| Аспект | PHPStan | Psalm | DEPTRAC | Rector |
|--------|---------|-------|---------|--------|
| Анализ типов | ✅ Глубокий | ✅ Глубокий | ❌ | ⚠️ Базовый |
| Архитектура | ❌ | ❌ | ✅ | ❌ |
| Безопасность | ⚠️ | ✅ Taint | ❌ | ❌ |
| Автоисправление | ❌ | ❌ | ❌ | ✅ |
| Скорость | Быстро | Средне | Быстро | Медленно |
| Конфигурация | NEON | XML | YAML | PHP |

## Рекомендуемая настройка CI

```yaml
lint:
  parallel:
    matrix:
      - TOOL: [phpstan, psalm, cs-fixer, deptrac]
  script:
    - case $TOOL in
        phpstan) vendor/bin/phpstan analyse ;;
        psalm) vendor/bin/psalm ;;
        cs-fixer) vendor/bin/php-cs-fixer fix --dry-run ;;
        deptrac) vendor/bin/deptrac analyse ;;
      esac
```

## Справочные материалы

Детальная информация в справочных файлах:

- `references/phpstan-rules.md` — Пользовательские правила PHPStan
- `references/psalm-plugins.md` — Плагины и аннотации Psalm
- `references/rector-rules.md` — Наборы обновлений Rector
