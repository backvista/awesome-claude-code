---
name: acc-docker-buildkit-knowledge
description: База знаний по Docker BuildKit. Предоставляет паттерны кеш-монтирования, секреты сборки, SSH-проброс и оптимизацию параллельной сборки.
---

# База знаний по Docker BuildKit

Краткий справочник по возможностям BuildKit и паттернам оптимизации.

## Заголовок синтаксиса BuildKit

```dockerfile
# syntax=docker/dockerfile:1
```

Всегда добавляйте эту строку первой для включения возможностей BuildKit. Эта директива указывает Docker использовать последний стабильный синтаксис Dockerfile с поддержкой BuildKit.

## Обзор типов монтирования

```
+---------------------------------------------------------------------------+
|                      BUILDKIT MOUNT TYPES                                   |
+---------------------------------------------------------------------------+
|                                                                            |
|   type=cache    Persistent cache between builds (composer, apk, npm)       |
|   type=bind     Bind-mount files from build context or other stage         |
|   type=secret   Mount sensitive files without baking into layers           |
|   type=ssh      Forward SSH agent for private repository access            |
|   type=tmpfs    Temporary filesystem, discarded after RUN                  |
|                                                                            |
+---------------------------------------------------------------------------+
```

## Паттерны кеш-монтирования

### Кеш Composer

```dockerfile
# syntax=docker/dockerfile:1
FROM composer:2 AS deps

WORKDIR /app
COPY composer.json composer.lock ./

RUN --mount=type=cache,target=/root/.composer/cache \
    composer install --no-dev --no-scripts --prefer-dist --no-autoloader

COPY . .
RUN composer dump-autoload --optimize --classmap-authoritative
```

### Кеш APK (Alpine)

```dockerfile
# syntax=docker/dockerfile:1
FROM php:8.4-fpm-alpine

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache libzip-dev icu-dev postgresql-dev && \
    docker-php-ext-install zip intl pdo_pgsql opcache
```

### Кеш APT (Debian)

```dockerfile
# syntax=docker/dockerfile:1
FROM php:8.4-fpm

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev libicu-dev libpq-dev && \
    docker-php-ext-install zip intl pdo_pgsql opcache
```

### Кеш NPM (для фронтенд-ресурсов)

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine AS frontend

WORKDIR /app
COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --production

COPY resources/ resources/
RUN npm run build
```

## Секреты сборки

### Приватный репозиторий Composer

```dockerfile
# syntax=docker/dockerfile:1
FROM composer:2 AS deps

WORKDIR /app
COPY composer.json composer.lock ./

# Mount auth.json as a secret - never stored in any layer
RUN --mount=type=secret,id=composer_auth,target=/root/.composer/auth.json \
    composer install --no-dev --prefer-dist
```

```bash
# Build command
docker build --secret id=composer_auth,src=auth.json -t myapp .
```

### Несколько секретов

```dockerfile
RUN --mount=type=secret,id=github_token \
    --mount=type=secret,id=npm_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token) \
    NPM_TOKEN=$(cat /run/secrets/npm_token) \
    composer install --no-dev
```

## Проброс SSH

```dockerfile
# syntax=docker/dockerfile:1
FROM composer:2 AS deps

# Install SSH client
RUN apk add --no-cache openssh-client git

WORKDIR /app
COPY composer.json composer.lock ./

# Forward SSH agent for private repos
RUN --mount=type=ssh \
    mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    composer install --no-dev --prefer-dist
```

```bash
# Build with SSH forwarding
docker build --ssh default -t myapp .

# Or with specific key
docker build --ssh default=$HOME/.ssh/id_rsa -t myapp .
```

## Параллельная сборка этапов

```dockerfile
# syntax=docker/dockerfile:1

# Stage 1: Composer dependencies (runs in parallel with Stage 2)
FROM composer:2 AS composer-deps
WORKDIR /app
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/root/.composer/cache \
    composer install --no-dev --no-scripts --prefer-dist

# Stage 2: Frontend assets (runs in parallel with Stage 1)
FROM node:20-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --production
COPY resources/ resources/
RUN npm run build

# Stage 3: PHP extensions (runs in parallel with Stage 1 and 2)
FROM php:8.4-fpm-alpine AS php-ext
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache libzip-dev icu-dev && \
    docker-php-ext-install zip intl pdo_mysql opcache

# Stage 4: Final image (waits for all parallel stages)
FROM php:8.4-fpm-alpine AS production

COPY --from=php-ext /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=php-ext /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=composer-deps /app/vendor /var/www/html/vendor
COPY --from=frontend /app/public/build /var/www/html/public/build
COPY . /var/www/html
```

BuildKit автоматически обнаруживает независимые этапы и собирает их параллельно.

## Inline Cache

```dockerfile
# syntax=docker/dockerfile:1
FROM php:8.4-fpm-alpine

# Enable inline cache metadata in the image
ARG BUILDKIT_INLINE_CACHE=1
```

```bash
# Build with cache export
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t myapp:latest .

# Build using remote image as cache source
docker build \
    --cache-from myregistry/myapp:latest \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t myapp:latest .
```

## Мультиплатформенная сборка Buildx

```bash
# Create builder instance
docker buildx create --name multiarch --use

# Build for multiple platforms
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t myregistry/myapp:latest \
    --push .
```

```dockerfile
# syntax=docker/dockerfile:1
# Platform-aware Dockerfile
FROM --platform=$BUILDPLATFORM composer:2 AS deps
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist

FROM php:8.4-fpm-alpine
# This stage uses the target platform automatically
COPY --from=deps /app/vendor /var/www/html/vendor
COPY . /var/www/html
```

## Сравнение производительности

| Возможность | Без BuildKit | С BuildKit |
|------------|-----------------|---------------|
| Кеш-монтирование | Недоступно | Постоянный между сборками |
| Параллельные этапы | Последовательно | Автоматически параллельно |
| Обработка секретов | ARG/ENV (небезопасно) | `--mount=type=secret` |
| Проброс SSH | Копирование ключей (небезопасно) | `--mount=type=ssh` |
| Вывод сборки | Подробный | Структурированный, прогресс-бар |
| Экспорт кеша | Только локально | Registry, inline, локально |

## Паттерны обнаружения

```bash
# Check for BuildKit usage
Grep: "syntax=docker/dockerfile" --glob "**/Dockerfile*"
Grep: "--mount=type=" --glob "**/Dockerfile*"

# Find cache optimization opportunities
Grep: "composer install|npm install|apk add|apt-get install" --glob "**/Dockerfile*"

# Check for insecure secret handling
Grep: "ARG.*TOKEN|ARG.*PASSWORD|ARG.*SECRET" --glob "**/Dockerfile*"
Grep: "COPY.*auth.json|COPY.*\.npmrc" --glob "**/Dockerfile*"
```
