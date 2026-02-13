---
name: acc-docker-knowledge
description: База знаний по Docker для PHP-проектов. Предоставляет паттерны, лучшие практики и руководства для Dockerfile, Compose, безопасности и готовности к production.
---

# База знаний по Docker

Краткий справочник по паттернам Docker и рекомендациям для PHP.

## Основные концепции

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER FOR PHP                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Dockerfile         → Build image instructions                  │
│   docker-compose.yml → Multi-container orchestration             │
│   .dockerignore      → Build context exclusions                  │
│   entrypoint.sh      → Container startup logic                   │
│   nginx.conf         → Reverse proxy for PHP-FPM                 │
│   php.ini            → PHP runtime configuration                 │
│   supervisord.conf   → Process management                        │
│                                                                  │
│   Multi-Stage Build:                                             │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│   │ composer  │  │ php-ext  │  │production│                     │
│   │  deps     │──│ builder  │──│  final   │                     │
│   └──────────┘  └──────────┘  └──────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Типы Docker-образов PHP

| Образ | Применение | Размер |
|-------|----------|------|
| `php:8.4-fpm-alpine` | Production (FPM) | ~50MB |
| `php:8.4-cli-alpine` | CI/воркеры | ~45MB |
| `php:8.4-fpm` | Production (Debian) | ~150MB |
| `php:8.4-cli` | CI/воркеры (Debian) | ~140MB |
| `php:8.4-apache` | Простые развёртывания | ~160MB |

## Краткие чек-листы

### Чек-лист Dockerfile

- [ ] Многоэтапная сборка (deps -> build -> production)
- [ ] Базовый образ Alpine по возможности
- [ ] Фиксированные теги версий (не `latest`)
- [ ] Заголовок синтаксиса BuildKit
- [ ] Непривилегированный пользователь
- [ ] Определена проверка здоровья
- [ ] Присутствует `.dockerignore`
- [ ] Зависимости Composer установлены до копирования исходников
- [ ] Конфигурация PHP для production (`php.ini-production`)
- [ ] OPcache включён и настроен
- [ ] Нет секретов в аргументах сборки или слоях

### Чек-лист Docker Compose

- [ ] Проверки здоровья для всех сервисов
- [ ] Именованные тома для постоянных данных
- [ ] Переменные окружения через файл `.env`
- [ ] Порядок зависимостей через `depends_on` + `condition`
- [ ] Определены лимиты ресурсов
- [ ] Сети сегментированы (frontend/backend)
- [ ] Нет захардкоженных паролей

### Чек-лист безопасности

- [ ] Непривилегированный пользователь (`USER app`)
- [ ] Файловая система только для чтения где возможно
- [ ] Нет секретов в Dockerfile или образе
- [ ] Минимальный базовый образ
- [ ] Нет ненужных пакетов
- [ ] Capabilities убраны
- [ ] Нет privileged mode

## Краткий справочник по типичным нарушениям

| Нарушение | Где | Критичность |
|-----------|-----|----------|
| `FROM php:latest` | Dockerfile | Высокая |
| `COPY . .` до установки зависимостей | Dockerfile | Высокая |
| Запуск от root | Dockerfile | Высокая |
| Секреты в ENV/ARG | Dockerfile | Критическая |
| Нет проверки здоровья | Dockerfile/Compose | Средняя |
| Нет `.dockerignore` | Корень проекта | Средняя |
| `privileged: true` | docker-compose.yml | Критическая |
| Захардкоженные пароли | docker-compose.yml | Критическая |
| Нет лимитов ресурсов | docker-compose.yml | Средняя |
| Отсутствуют условия `depends_on` | docker-compose.yml | Средняя |

## Лучшие практики для PHP

### Установка расширений

```dockerfile
# Alpine: use apk + docker-php-ext-install
RUN apk add --no-cache libzip-dev icu-dev \
    && docker-php-ext-install zip intl pdo_mysql opcache

# Debian: use apt-get + docker-php-ext-install
RUN apt-get update && apt-get install -y \
    libzip-dev libicu-dev \
    && docker-php-ext-install zip intl pdo_mysql opcache \
    && rm -rf /var/lib/apt/lists/*
```

### Конфигурация OPcache (Production)

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.jit=1255
opcache.jit_buffer_size=256M
```

### Настройка PHP-FPM

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 1000
```

## Ссылки

Подробная информация в справочных файлах:

- `references/image-selection.md` — Сравнение и выбор базовых образов
- `references/multistage-patterns.md` — Паттерны многоэтапной сборки для PHP
- `references/security-hardening.md` — Лучшие практики безопасности и укрепление
- `references/compose-patterns.md` — Паттерны Docker Compose для PHP-стеков
- `references/production-checklist.md` — Чек-лист готовности к production
