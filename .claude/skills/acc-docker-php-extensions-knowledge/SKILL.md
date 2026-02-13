---
name: acc-docker-php-extensions-knowledge
description: База знаний по PHP-расширениям для Docker. Предоставляет паттерны установки распространённых расширений, управление зависимостями сборки и использование PECL.
---

# База знаний по PHP-расширениям для Docker

Паттерны установки, сборки и управления PHP-расширениями в Docker-контейнерах.

## Категории расширений

| Категория | Расширения | Назначение |
|-----------|-----------|-----------|
| **Ядро** | opcache, intl, mbstring, bcmath | Производительность, i18n, математика |
| **Базы данных** | pdo_pgsql, pdo_mysql, pgsql, mysqli | Подключение к БД |
| **Кеш** | redis, apcu, memcached | Слои кеширования |
| **Криптография** | sodium, openssl | Шифрование, хеширование |
| **Изображения** | gd, imagick | Обработка изображений |
| **Архивы** | zip, zlib, bz2 | Сжатие |
| **Сообщения** | amqp, pcntl | Очереди, управление процессами |
| **Отладка** | xdebug, pcov | Отладка, покрытие |
| **Сериализация** | igbinary, msgpack | Быстрая сериализация |

## Методы установки

### Метод 1: docker-php-ext-install (встроенные расширения)

```dockerfile
# Extensions bundled with PHP source
RUN docker-php-ext-install -j$(nproc) \
    opcache \
    intl \
    pdo_pgsql \
    pdo_mysql \
    zip \
    bcmath \
    pcntl \
    sockets
```

### Метод 2: docker-php-ext-configure + install

```dockerfile
# Extensions requiring configuration
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j$(nproc) gd
```

### Метод 3: PECL Install

```dockerfile
# Extensions from PECL repository
RUN pecl install redis-6.1.0 apcu-5.1.24 igbinary-3.2.16 \
    && docker-php-ext-enable redis apcu igbinary
```

### Метод 4: Ручная компиляция

```dockerfile
# For extensions not in PECL or needing custom patches
RUN curl -fsSL https://github.com/example/ext/archive/v1.0.tar.gz | tar xz \
    && cd ext-1.0 \
    && phpize \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable ext
```

## Зависимости сборки Alpine vs Debian

| Расширение | Пакеты Alpine | Пакеты Debian |
|-----------|----------------|-----------------|
| intl | `icu-dev` | `libicu-dev` |
| pdo_pgsql | `libpq-dev` | `libpq-dev` |
| pdo_mysql | (нет) | (нет) |
| gd | `freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev` | `libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev` |
| zip | `libzip-dev` | `libzip-dev` |
| imagick | `imagemagick-dev` | `libmagickwand-dev` |
| amqp | `rabbitmq-c-dev` | `librabbitmq-dev` |
| memcached | `libmemcached-dev zlib-dev` | `libmemcached-dev zlib1g-dev` |
| sodium | `libsodium-dev` | `libsodium-dev` |
| bz2 | `bzip2-dev` | `libbz2-dev` |
| xsl | `libxslt-dev` | `libxslt1-dev` |
| ldap | `openldap-dev` | `libldap2-dev` |
| gmp | `gmp-dev` | `libgmp-dev` |
| imap | `imap-dev krb5-dev` | `libc-client-dev libkrb5-dev` |

## Паттерн Runtime vs Build зависимостей

```dockerfile
FROM php:8.4-fpm-alpine AS production

# 1. Install build dependencies (virtual package for easy removal)
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libpq-dev \
        libzip-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        rabbitmq-c-dev \
    \
# 2. Install and configure extensions
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        intl \
        pdo_pgsql \
        zip \
        gd \
        opcache \
        bcmath \
        pcntl \
        sockets \
    \
# 3. Install PECL extensions
    && pecl install redis apcu amqp igbinary \
    && docker-php-ext-enable redis apcu amqp igbinary \
    \
# 4. Remove build dependencies (keep runtime libs)
    && apk del .build-deps

# 5. Install runtime-only libraries
RUN apk add --no-cache \
    icu-libs \
    libpq \
    libzip \
    freetype \
    libjpeg-turbo \
    libpng \
    rabbitmq-c
```

## Паттерн отдельного этапа сборки расширений

```dockerfile
# Dedicated stage for compiling extensions (reusable across images)
FROM php:8.4-fpm-alpine AS ext-builder

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libpq-dev \
        libzip-dev \
    && docker-php-ext-install -j$(nproc) intl pdo_pgsql zip opcache bcmath \
    && pecl install redis apcu \
    && docker-php-ext-enable redis apcu \
    && apk del .build-deps

# Production stage copies only compiled artifacts
FROM php:8.4-fpm-alpine AS production

COPY --from=ext-builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=ext-builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

RUN apk add --no-cache icu-libs libpq libzip
```

## Комбинации расширений для фреймворков

### Стек Symfony

```dockerfile
RUN docker-php-ext-install -j$(nproc) \
    intl \           # Translation, validation, routing
    pdo_pgsql \      # Doctrine DBAL (PostgreSQL)
    opcache \        # Performance
    zip \            # Composer, file handling
    bcmath \         # Precise math (money)
    pcntl \          # Messenger async workers
    sockets          # Messenger AMQP transport

RUN pecl install redis apcu amqp \
    && docker-php-ext-enable redis apcu amqp
```

### Стек Laravel

```dockerfile
RUN docker-php-ext-install -j$(nproc) \
    pdo_mysql \      # Eloquent (MySQL)
    opcache \        # Performance
    zip \            # File handling
    bcmath \         # Precise math
    pcntl \          # Horizon workers
    exif             # Image metadata

RUN pecl install redis igbinary \
    && docker-php-ext-enable redis igbinary
```

### API Platform / Высоконагруженные проекты

```dockerfile
RUN docker-php-ext-install -j$(nproc) \
    intl \
    pdo_pgsql \
    opcache \
    bcmath \
    pcntl \
    sockets

RUN pecl install redis apcu amqp igbinary msgpack \
    && docker-php-ext-enable redis apcu amqp igbinary msgpack
```

## Конфигурация OPcache для production

```ini
; /usr/local/etc/php/conf.d/opcache.ini
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=256
opcache.interned_strings_buffer=32
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.save_comments=1
opcache.jit=tracing
opcache.jit_buffer_size=128M
```

```dockerfile
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
```

## Устранение неполадок

| Проблема | Причина | Решение |
|----------|---------|---------|
| `cannot find -licu` | Отсутствует icu-dev | `apk add icu-dev` или `apt install libicu-dev` |
| `pecl install fails` | Отсутствует $PHPIZE_DEPS | `apk add $PHPIZE_DEPS` |
| Расширение загружается, но segfault | Несовместимость Alpine musl | Перейдите на Debian-образ |
| `Class 'Redis' not found` | Расширение не подключено | `docker-php-ext-enable redis` |
| `iconv(): Wrong encoding` | Alpine musl iconv | Установите `gnu-libiconv` |
| Медленная сборка | Последовательная компиляция | Используйте `-j$(nproc)` и кеш BuildKit |

## Ссылки

Полная матрица расширений со всеми зависимостями находится в `references/extensions-matrix.md`.
Выбор базового образа описан в `acc-docker-base-images-knowledge`.
