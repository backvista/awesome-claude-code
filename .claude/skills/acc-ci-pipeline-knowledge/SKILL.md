---
name: acc-ci-pipeline-knowledge
description: База знаний CI/CD-пайплайнов. Содержит обзор платформ (GitHub Actions, GitLab CI), этапы пайплайна, стратегии кеширования, параллелизацию, управление артефактами и окружениями.
---

# База знаний CI/CD-пайплайнов

Краткий справочник по паттернам, платформам и лучшим практикам CI/CD-пайплайнов.

## Этапы пайплайна

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Install   │───▶│    Lint     │───▶│    Test     │───▶│    Build    │───▶│   Deploy    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
     Deps            Code Style         PHPUnit           Docker            Production
     Cache           PHPStan            Coverage          Artifacts         Environments
```

**Стандартный PHP-пайплайн:**
1. **Install** — зависимости Composer, восстановление кеша
2. **Lint** — PHPStan, Psalm, PHP-CS-Fixer, DEPTRAC
3. **Test** — PHPUnit, покрытие кода, мутационное тестирование
4. **Build** — Docker-образ, тегирование версий
5. **Deploy** — деплой в окружение, проверки здоровья

## Сравнение платформ

| Возможность | GitHub Actions | GitLab CI |
|---------|----------------|-----------|
| Файл конфигурации | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| Раннеры | GitHub-hosted / self-hosted | GitLab-hosted / self-hosted |
| Кеширование | `actions/cache` | Встроенный `cache:` |
| Артефакты | `actions/upload-artifact` | Встроенный `artifacts:` |
| Секреты | Repository/Environment secrets | CI/CD Variables |
| Матричные сборки | `strategy.matrix` | `parallel:matrix` |
| Переиспользование | Composite actions, workflows | `include:`, `extends:` |
| Контейнеры | `container:` | `image:` |

## Структура GitHub Actions

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  PHP_VERSION: '8.4'
  COMPOSER_CACHE_DIR: ~/.composer/cache

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
          coverage: none
      - name: Cache Composer
        uses: actions/cache@v4
        with:
          path: ${{ env.COMPOSER_CACHE_DIR }}
          key: composer-${{ hashFiles('composer.lock') }}
      - run: composer install --no-progress --prefer-dist
      - run: vendor/bin/phpstan analyse

  test:
    needs: lint
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_DATABASE: test
          MYSQL_ROOT_PASSWORD: root
        ports:
          - 3306:3306
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
          coverage: xdebug
      - run: composer install --no-progress --prefer-dist
      - run: vendor/bin/phpunit --coverage-clover coverage.xml
      - uses: codecov/codecov-action@v4
```

## Структура GitLab CI

```yaml
stages:
  - install
  - lint
  - test
  - build
  - deploy

variables:
  PHP_VERSION: "8.4"
  COMPOSER_CACHE_DIR: "$CI_PROJECT_DIR/.composer-cache"

.php_template: &php_template
  image: php:${PHP_VERSION}-cli
  cache:
    key: composer-$CI_COMMIT_REF_SLUG
    paths:
      - .composer-cache/
      - vendor/
    policy: pull

install:
  <<: *php_template
  stage: install
  cache:
    policy: pull-push
  script:
    - composer install --no-progress --prefer-dist

lint:phpstan:
  <<: *php_template
  stage: lint
  needs: [install]
  script:
    - vendor/bin/phpstan analyse --memory-limit=1G

test:unit:
  <<: *php_template
  stage: test
  needs: [lint:phpstan]
  services:
    - mysql:8.0
  variables:
    MYSQL_DATABASE: test
    MYSQL_ROOT_PASSWORD: root
  script:
    - vendor/bin/phpunit --coverage-cobertura coverage.xml
  coverage: '/^\s*Lines:\s*\d+.\d+\%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

## Стратегии кеширования

### Кеш Composer

**GitHub Actions:**
```yaml
- name: Cache Composer dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.composer/cache
      vendor
    key: php-${{ hashFiles('composer.lock') }}
    restore-keys: |
      php-
```

**GitLab CI:**
```yaml
cache:
  key:
    files:
      - composer.lock
  paths:
    - .composer-cache/
    - vendor/
  policy: pull-push  # pull on jobs, push on install
```

### Кеш Docker-слоёв

**GitHub Actions:**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**GitLab CI:**
```yaml
build:
  script:
    - docker build --cache-from $CI_REGISTRY_IMAGE:latest -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
```

## Паттерны параллелизации

### Матричная стратегия (GitHub Actions)

```yaml
test:
  strategy:
    matrix:
      php: ['8.2', '8.3', '8.4']
      database: ['mysql', 'postgres']
      exclude:
        - php: '8.2'
          database: 'postgres'
    fail-fast: false
  runs-on: ubuntu-latest
  steps:
    - run: echo "Testing PHP ${{ matrix.php }} with ${{ matrix.database }}"
```

### Параллельные задания (GitLab CI)

```yaml
test:
  parallel:
    matrix:
      - PHP_VERSION: ['8.2', '8.3', '8.4']
        DATABASE: ['mysql', 'postgres']
  script:
    - echo "Testing PHP $PHP_VERSION with $DATABASE"
```

### Разделение тестов

```yaml
# Split PHPUnit tests across runners
test:
  parallel: 4
  script:
    - vendor/bin/phpunit --testsuite unit --filter "Test$((($CI_NODE_INDEX - 1) * 25 + 1))-$(($CI_NODE_INDEX * 25))"
```

## Управление окружениями

### Окружения GitHub

```yaml
deploy-production:
  runs-on: ubuntu-latest
  environment:
    name: production
    url: https://example.com
  steps:
    - name: Deploy
      env:
        DATABASE_URL: ${{ secrets.DATABASE_URL }}
      run: ./deploy.sh
```

### Окружения GitLab

```yaml
deploy:production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  script:
    - ./deploy.sh
```

## Управление артефактами

### Отчёты о тестах

**GitHub Actions:**
```yaml
- name: Upload test results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: test-results
    path: |
      coverage.xml
      junit.xml
    retention-days: 30
```

**GitLab CI:**
```yaml
test:
  artifacts:
    when: always
    paths:
      - coverage.xml
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    expire_in: 30 days
```

## Чек-лист оптимизации пайплайна

| Оптимизация | Эффект | Реализация |
|-------------|--------|----------------|
| Кеширование зависимостей | ⬇️ 2-5 мин | Кеш composer, npm |
| Кеширование Docker-слоёв | ⬇️ 3-10 мин | BuildKit cache |
| Параллельные задания | ⬇️ 50-80% | Matrix, разделение тестов |
| Пропуск неизменённого | ⬇️ Варьируется | Фильтры путей, needs |
| Лёгкие образы | ⬇️ 1-3 мин | Alpine, multi-stage |
| Быстрый отказ | ⬇️ Варьируется | Ранний выход при ошибках |

## Распространённые паттерны пайплайнов

### 1. Пайплайн для монорепозитория

```yaml
# Only run when specific paths change
on:
  push:
    paths:
      - 'services/api/**'
      - 'shared/**'
```

### 2. Pull Request vs Push

```yaml
on:
  pull_request:
    # Run tests, skip deploy
  push:
    branches: [main]
    # Run full pipeline with deploy
```

### 3. Запланированные проверки безопасности

```yaml
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly Monday
  workflow_dispatch:  # Manual trigger
```

### 4. Рабочий процесс релиза

```yaml
on:
  release:
    types: [published]

jobs:
  publish:
    steps:
      - name: Get version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_ENV
```

## Лучшие практики

### РЕКОМЕНДУЕТСЯ

- ✅ Агрессивно кешировать зависимости
- ✅ Использовать конкретные версии actions (`@v4`, не `@latest`)
- ✅ Быстрый отказ в PR-пайплайнах
- ✅ Запускать проверки безопасности по расписанию
- ✅ Использовать окружения как шлюзы для деплоя
- ✅ Хранить секреты в хранилище, не в коде

### НЕ РЕКОМЕНДУЕТСЯ

- ❌ Запускать полный пайплайн на каждом коммите
- ❌ Устанавливать зависимости в каждом задании
- ❌ Использовать изменяемые теги для Docker-образов
- ❌ Выводить секреты в логи
- ❌ Пропускать тесты для «быстрых исправлений»
- ❌ Деплоить без проверок здоровья

## Справочные материалы

Детальная информация в справочных файлах:

- `references/github-actions.md` — Глубокое погружение в GitHub Actions
- `references/gitlab-ci.md` — Конфигурация GitLab CI
- `references/caching.md` — Стратегии и паттерны кеширования
