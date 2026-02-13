---
name: acc-check-docker-healthcheck
description: Проверяет конфигурацию health checks в Docker для PHP-сервисов. Верифицирует health checks PHP-FPM, Nginx и зависимых сервисов.
---

# Проверка конфигурации Docker Health Check

Анализ конфигурации health checks для PHP-стеков и зависимых сервисов.

## Паттерны Health Check по сервисам

### 1. PHP-FPM

```dockerfile
# Using php-fpm-healthcheck script (recommended)
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD php-fpm-healthcheck || exit 1

# Using cgi-fcgi (requires libfcgi)
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD cgi-fcgi -bind -connect 127.0.0.1:9000 /ping || exit 1
```

```ini
; Required PHP-FPM pool config
ping.path = /ping
ping.response = pong
pm.status_path = /status
```

### 2. Nginx

```dockerfile
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Or wget for minimal images
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --spider --quiet http://localhost/health || exit 1
```

### 3. MySQL

```yaml
services:
  mysql:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

### 4. PostgreSQL

```yaml
services:
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

### 5. Redis

```yaml
services:
  redis:
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
```

### 6. RabbitMQ

```yaml
services:
  rabbitmq:
    healthcheck:
      test: ["CMD-SHELL", "rabbitmq-diagnostics check_running && rabbitmq-diagnostics check_local_alarms"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 30s
```

## Рекомендуемые параметры

| Сервис | interval | timeout | start_period | retries |
|--------|----------|---------|--------------|---------|
| PHP-FPM | 10s | 3s | 10s | 3 |
| Nginx | 10s | 3s | 5s | 3 |
| MySQL | 10s | 5s | 30s | 5 |
| PostgreSQL | 10s | 5s | 30s | 5 |
| Redis | 10s | 3s | 5s | 3 |
| RabbitMQ | 15s | 10s | 30s | 5 |

## Обнаружение некорректных Health Checks

```dockerfile
# BAD: Too frequent (overhead)
HEALTHCHECK --interval=1s --timeout=1s --retries=1 CMD curl localhost

# BAD: No start_period (fails during init)
HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD pg_isready

# BAD: Checking external dependency
HEALTHCHECK CMD curl -f https://api.external.com/health

# BAD: Too slow detection (interval*retries > 5min)
HEALTHCHECK --interval=60s --timeout=30s --retries=10 CMD curl localhost
```

## Grep-паттерны

```bash
Grep: "HEALTHCHECK" --glob "**/Dockerfile*"
Grep: "healthcheck:" --glob "**/docker-compose*.yml"
Grep: "depends_on:" --glob "**/docker-compose*.yml"
Grep: "ping\\.path|pm\\.status_path" --glob "**/*.conf"
```

## Классификация серьёзности

| Проблема | Серьёзность | Влияние |
|----------|-------------|---------|
| Нет health check ни для одного сервиса | Critical | Нет обнаружения сбоев |
| PHP-FPM без health check | Critical | Мёртвые воркеры не обнаруживаются |
| БД без health check | Major | Приложение стартует до готовности БД |
| Нет start_period для БД | Major | Ложное unhealthy при инициализации |
| Проверка внешней зависимости | Major | Каскадное влияние внешнего сбоя |
| depends_on без условия | Major | Race condition при запуске |
| Интервал слишком мал (< 5s) | Minor | Лишние накладные расходы |
| Интервал слишком велик (> 60s) | Minor | Медленное обнаружение сбоев |
| timeout >= interval | Minor | Перекрывающиеся проверки |

## Формат вывода

```markdown
### Проблема Health Check: [Описание]

**Серьёзность:** Critical/Major/Minor
**Сервис:** [имя сервиса]
**Файл:** `docker-compose.yml:line` или `Dockerfile:line`

**Проблема:**
[Описание отсутствующего или некорректно настроенного health check]

**Рекомендация:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "..."]
  interval: 10s
  timeout: 3s
  start_period: 10s
  retries: 3
```

**Параметры:**
| Параметр | Текущий | Рекомендуемый | Причина |
|----------|---------|---------------|---------|
| interval | N/A | 10s | Стандартная частота |
| timeout | N/A | 3s | Быстрое обнаружение сбоев |
| start_period | N/A | 10s | Время на инициализацию |
| retries | N/A | 3 | Предотвращение флаппинга |
```
