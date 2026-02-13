---
name: acc-docker-compose-knowledge
description: База знаний по Docker Compose для PHP-стеков. Предоставляет паттерны конфигурации сервисов, проверки здоровья, сетевые настройки и управление окружением.
---

# База знаний по Docker Compose для PHP-стеков

Паттерны конфигурации сервисов и лучшие практики Docker Compose для PHP-приложений.

## Архитектура PHP-стека

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       DOCKER COMPOSE PHP STACK                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌───────────────────────────────────────────────────────────┐             │
│   │                    FRONTEND NETWORK                        │             │
│   │                                                            │             │
│   │   :80/:443          :8025                                  │             │
│   │   ┌────────┐        ┌────────┐                             │             │
│   │   │ Nginx  │        │Mailhog │                             │             │
│   │   └───┬────┘        └────────┘                             │             │
│   │       │ fastcgi:9000                                       │             │
│   └───────┼────────────────────────────────────────────────────┘             │
│           │                                                                  │
│   ┌───────┼────────────────────────────────────────────────────┐             │
│   │       ▼           BACKEND NETWORK                          │             │
│   │   ┌────────┐                                               │             │
│   │   │PHP-FPM │──┐                                            │             │
│   │   └────────┘  │                                            │             │
│   │               │                                            │             │
│   │   ┌────────┐  │  ┌────────┐  ┌──────────┐  ┌────────┐    │             │
│   │   │Worker  │──┤  │ Redis  │  │PostgreSQL│  │RabbitMQ│    │             │
│   │   └────────┘  │  │ :6379  │  │  :5432   │  │ :5672  │    │             │
│   │               │  └────────┘  └──────────┘  └────────┘    │             │
│   │   ┌────────┐  │                                            │             │
│   │   │  Cron  │──┘  ┌──────────────┐  ┌────────┐            │             │
│   │   └────────┘     │Elasticsearch │  │ MinIO  │            │             │
│   │                  │   :9200      │  │ :9000  │            │             │
│   │                  └──────────────┘  └────────┘            │             │
│   └────────────────────────────────────────────────────────────┘             │
│                                                                              │
│   ┌────────────────────────────────────────────────────────────┐             │
│   │                  MONITORING NETWORK                         │             │
│   │   ┌──────────┐  ┌─────────┐  ┌────────┐                   │             │
│   │   │Prometheus│  │ Grafana │  │ Jaeger │                   │             │
│   │   │  :9090   │  │  :3000  │  │ :16686 │                   │             │
│   │   └──────────┘  └─────────┘  └────────┘                   │             │
│   └────────────────────────────────────────────────────────────┘             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Структура Compose-файла

```yaml
# docker-compose.yml — base configuration
version: "3.9"

x-php-base: &php-base
  build:
    context: .
    dockerfile: docker/php/Dockerfile
    target: dev
  volumes:
    - .:/app:cached
    - vendor:/app/vendor
  environment:
    APP_ENV: ${APP_ENV:-dev}
    DATABASE_URL: postgresql://app:secret@postgres:5432/app?serverVersion=16
    REDIS_URL: redis://redis:6379
    MESSENGER_TRANSPORT_DSN: amqp://guest:guest@rabbitmq:5672/%2f/messages
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy

services:
  php:
    <<: *php-base
    expose:
      - "9000"
    networks:
      - frontend
      - backend

  worker:
    <<: *php-base
    command: php bin/console messenger:consume async --time-limit=3600
    restart: unless-stopped
    networks:
      - backend

  cron:
    <<: *php-base
    command: crond -f -d 8
    networks:
      - backend

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "${NGINX_PORT:-80}:80"
    volumes:
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./public:/app/public:ro
    depends_on:
      - php
    networks:
      - frontend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  vendor:
  postgres-data:
  redis-data:
  elasticsearch-data:
  rabbitmq-data:
  minio-data:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
  monitoring:
    driver: bridge
```

## Паттерны проверки здоровья

### PostgreSQL

```yaml
postgres:
  image: postgres:16-alpine
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app} -d ${POSTGRES_DB:-app}"]
    interval: 5s
    timeout: 5s
    retries: 5
    start_period: 10s
```

### MySQL

```yaml
mysql:
  image: mysql:8.4
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
    interval: 5s
    timeout: 5s
    retries: 5
    start_period: 20s
```

### Redis

```yaml
redis:
  image: redis:7-alpine
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 5s
    timeout: 3s
    retries: 3
```

### RabbitMQ

```yaml
rabbitmq:
  image: rabbitmq:3.13-management-alpine
  healthcheck:
    test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
    interval: 10s
    timeout: 10s
    retries: 5
    start_period: 30s
```

### Elasticsearch

```yaml
elasticsearch:
  image: elasticsearch:8.15.0
  healthcheck:
    test: ["CMD-SHELL", "curl -sf http://localhost:9200/_cluster/health || exit 1"]
    interval: 10s
    timeout: 10s
    retries: 5
    start_period: 30s
```

### PHP-FPM

```yaml
php:
  healthcheck:
    test: ["CMD-SHELL", "php-fpm-healthcheck || exit 1"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 15s
```

## Стратегии томов

| Стратегия | Синтаксис | Производительность | Применение |
|----------|--------|-------------|----------|
| Bind mount | `./src:/app/src` | Нативная (Linux), медленная (Mac) | Исходный код для разработки |
| Bind + cached | `./src:/app/src:cached` | Лучше на Mac | Код на macOS |
| Named volume | `vendor:/app/vendor` | Быстрая | Зависимости, данные |
| tmpfs | `tmpfs: /tmp` | Самая быстрая | Временные файлы, кеш |
| Anonymous | `/app/var` | Быстрая | Эфемерные данные |

### Рекомендуемая структура томов

```yaml
volumes:
  - .:/app:cached                      # Source code (bind, dev only)
  - vendor:/app/vendor                 # Composer vendor (named)
  - ./docker/php/php.ini:/usr/local/etc/php/php.ini:ro  # Config (bind, ro)
```

## Управление окружением

### Иерархия файлов .env

```
.env                  # Defaults (committed to git)
.env.local            # Local overrides (gitignored)
.env.${APP_ENV}       # Per-environment (committed)
.env.${APP_ENV}.local # Per-environment local (gitignored)
```

### Docker Compose .env

```bash
# .env (project root — Docker Compose reads this)
COMPOSE_PROJECT_NAME=myapp
COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml

# Service versions
POSTGRES_VERSION=16
REDIS_VERSION=7
RABBITMQ_VERSION=3.13

# Ports (avoid conflicts)
NGINX_PORT=80
POSTGRES_PORT=5432
REDIS_PORT=6379
RABBITMQ_PORT=5672
RABBITMQ_MGMT_PORT=15672

# Credentials
POSTGRES_USER=app
POSTGRES_PASSWORD=secret
POSTGRES_DB=app
```

## Паттерн override-файлов

```yaml
# docker-compose.override.yml — development overrides (auto-loaded)
services:
  php:
    build:
      target: dev
    volumes:
      - .:/app:cached
    environment:
      XDEBUG_MODE: debug
      XDEBUG_CONFIG: client_host=host.docker.internal

  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "8025:8025"
    networks:
      - frontend
```

```yaml
# docker-compose.prod.yml — production overrides
services:
  php:
    build:
      target: production
    volumes: []  # No bind mounts
    restart: unless-stopped

  nginx:
    restart: unless-stopped
```

Использование:

```bash
# Development (auto-loads override)
docker compose up -d

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Testing
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d
```

## Профили

```yaml
services:
  php:
    # Always starts (no profile)

  elasticsearch:
    profiles: ["search"]

  mailhog:
    profiles: ["dev"]

  prometheus:
    profiles: ["monitoring"]

  grafana:
    profiles: ["monitoring"]
```

```bash
# Start core services only
docker compose up -d

# Start with search
docker compose --profile search up -d

# Start with monitoring
docker compose --profile monitoring up -d

# Start everything
docker compose --profile search --profile monitoring --profile dev up -d
```

## Конфигурация сети

```yaml
networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24

  backend:
    driver: bridge
    internal: true    # No external access

  monitoring:
    driver: bridge
```

### Распределение сервисов по сетям

| Сервис | frontend | backend | monitoring |
|--------|----------|---------|------------|
| nginx | да | - | - |
| php-fpm | да | да | - |
| worker | - | да | - |
| postgres | - | да | - |
| redis | - | да | - |
| rabbitmq | - | да | - |
| prometheus | - | - | да |
| grafana | - | - | да |

## Общие паттерны

### Ожидание зависимостей

```yaml
php:
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
    rabbitmq:
      condition: service_healthy
```

### Лимиты ресурсов

```yaml
php:
  deploy:
    resources:
      limits:
        cpus: "2.0"
        memory: 512M
      reservations:
        cpus: "0.5"
        memory: 256M
```

### Конфигурация логирования

```yaml
php:
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"
```

## Ссылки

Полные конфигурации сервисов описаны в `references/service-configs.md`.
Подробности по сетям см. в `acc-docker-networking-knowledge`.
