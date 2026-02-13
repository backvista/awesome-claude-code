---
name: acc-check-docker-compose-config
description: Проверяет конфигурацию Docker Compose для PHP-стеков. Обнаруживает отсутствующие health checks, некорректные зависимости, захардкоженные значения и проблемы с сетью.
---

# Проверка конфигурации Docker Compose

Анализ файлов Docker Compose на предмет проблем конфигурации в стеках PHP-приложений.

## Паттерны обнаружения

### 1. Отсутствующие Health Checks

```yaml
# BAD: No healthcheck section for service
# GOOD: Health check present
services:
  php-fpm:
    healthcheck:
      test: ["CMD-SHELL", "php-fpm-healthcheck || exit 1"]
      interval: 10s
      timeout: 3s
      retries: 3
```

### 2. depends_on без условия

```yaml
# BAD: No health condition (race condition on startup)
services:
  app:
    depends_on:
      - mysql

# GOOD: Health condition enforced
services:
  app:
    depends_on:
      mysql:
        condition: service_healthy
```

### 3. Захардкоженные пароли

```yaml
# BAD: Credentials in plain text
services:
  mysql:
    environment:
      MYSQL_ROOT_PASSWORD: secret123

# GOOD: Using .env file reference
services:
  mysql:
    env_file: [.env]
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
```

### 4. Отсутствие лимитов ресурсов

```yaml
# GOOD: Resource limits defined
services:
  php-fpm:
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
```

### 5. Отсутствие политики перезапуска

```yaml
# GOOD: Restart policy defined
services:
  app:
    restart: unless-stopped
```

### 6. Устаревшее поле version

```yaml
# BAD: Deprecated in Compose V2+
version: "3.8"
services:
  app:
    image: my-app
```

### 7. Отсутствие определения сетей

```yaml
# GOOD: Explicit network isolation
services:
  app:
    networks: [frontend, backend]
  mysql:
    networks: [backend]
networks:
  frontend:
  backend:
    internal: true
```

### 8. Проблемы с правами на тома

```yaml
# GOOD: User mapping to avoid permission issues
services:
  php-fpm:
    user: "${UID:-1000}:${GID:-1000}"
    volumes:
      - ./src:/var/www/html
```

### 9. Конфликты портов

```yaml
# BAD: Binding to all interfaces — ports: ["80:80"]
# GOOD: Specific host binding — ports: ["127.0.0.1:8080:80"]
```

### 10. Отсутствие ссылки на .env файл

```yaml
# GOOD: Explicit env_file with variable interpolation
services:
  app:
    env_file: [.env]
```

## Grep-паттерны

```bash
# Hardcoded passwords
Grep: "PASSWORD.*:.*['\"]?[a-zA-Z0-9]" --glob "**/docker-compose*.yml"

# depends_on without condition
Grep: "depends_on:" --glob "**/docker-compose*.yml"

# Deprecated version field
Grep: "^version:" --glob "**/docker-compose*.yml"

# Port bindings
Grep: "ports:" --glob "**/docker-compose*.yml"
```

## Классификация серьёзности

| Паттерн | Серьёзность | Влияние |
|---------|-------------|---------|
| Захардкоженные учётные данные | Critical | Риск утечки безопасности |
| Нет health checks | Major | Ненадёжные зависимости |
| depends_on без условия | Major | Race conditions при запуске |
| Нет лимитов ресурсов | Major | OOM kills, исчерпание ресурсов |
| Конфликты портов | Major | Ошибка запуска сервиса |
| Отсутствие сетей | Minor | Нет сетевой изоляции |
| Устаревшее поле version | Minor | Предупреждение совместимости |
| Нет политики перезапуска | Minor | Необходимость ручного восстановления |
| Права на тома | Minor | Ошибки доступа к файлам |
| Отсутствие ссылки на .env | Minor | Риск неопределённых переменных |

## Формат вывода

```markdown
### Проблема Compose: [Описание]

**Серьёзность:** Critical/Major/Minor
**Файл:** `docker-compose.yml:line`
**Проблема:** [Описание проблемы]
**Исправление:** [Исправленный фрагмент конфигурации]
**Влияние:** [Что может произойти, если не исправить]
```
