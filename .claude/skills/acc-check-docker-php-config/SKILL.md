---
name: acc-check-docker-php-config
description: Проверяет конфигурацию PHP в Docker-контейнерах. Верифицирует настройки php.ini, OPcache, пулы PHP-FPM и конфигурацию расширений для production.
---

# Проверка конфигурации PHP в Docker

Анализ конфигурации PHP в Docker-окружениях на готовность к production.

## Проверки конфигурации

### 1. php.ini: Production vs Development

```dockerfile
# BAD: Development config
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

# GOOD: Production config
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
```

### 2. Конфигурация OPcache

```ini
; GOOD: OPcache optimized for production
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.save_comments=1
```

### 3. OPcache JIT (PHP 8.4+)

```ini
opcache.jit=1255
opcache.jit_buffer_size=128M
```

### 4. Конфигурация пула PHP-FPM

```ini
; BAD: Static pm wastes memory; ondemand has fork overhead
pm = static
pm.max_children = 100

; GOOD: Dynamic pm with tuned values
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 1000
```

### 5. Лимит памяти

```ini
; BAD: Unlimited memory
memory_limit = -1

; GOOD: Appropriate for workload
memory_limit = 128M   ; web
memory_limit = 256M   ; workers
memory_limit = 512M   ; batch
```

### 6. Отчёты об ошибках

```ini
; BAD: Development error display
display_errors = On

; GOOD: Production settings
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /proc/self/fd/2
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
```

### 7. Управление сессиями

```ini
; BAD: File-based sessions (not scalable)
session.save_handler = files

; GOOD: External storage
session.save_handler = redis
session.save_path = "tcp://redis:6379"
```

### 8. Лимиты загрузки

```ini
upload_max_filesize = 20M
post_max_size = 25M
max_file_uploads = 10
```

### 9. Часовой пояс

```ini
date.timezone = UTC
```

### 10. Кэш Realpath

```ini
; GOOD: Increased for Symfony/Laravel
realpath_cache_size = 4096K
realpath_cache_ttl = 600
```

## Grep-паттерны

```bash
Grep: "php.ini-(production|development)" --glob "**/Dockerfile*"
Grep: "opcache\\." --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "^pm[. =]" --glob "**/*.conf"
Grep: "memory_limit" --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "display_errors" --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "session\\.save_handler" --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "upload_max_filesize|post_max_size" --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "date\\.timezone" --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "realpath_cache" --glob "**/{Dockerfile*,*.ini,*.conf}"
Grep: "opcache\\.jit" --glob "**/{Dockerfile*,*.ini,*.conf}"
```

## Источники обнаружения

1. **Dockerfile RUN echo** — inline-директивы php.ini
2. **COPY php.ini** — полная замена конфигурации
3. **COPY conf.d/*.ini** — модульные конфигурационные файлы
4. **Конфигурация пула PHP-FPM** — www.conf или пользовательские пулы
5. **Переменные окружения** — переопределения PHP_INI_SCAN_DIR

## Классификация серьёзности

| Проверка | Серьёзность | Влияние |
|----------|-------------|---------|
| Использование php.ini-development | Critical | Раскрывает ошибки, нет OPcache |
| OPcache отключён | Critical | В 3-10 раз медленнее ответы |
| display_errors = On | Critical | Раскрытие информации |
| memory_limit = -1 | Major | Риск OOM |
| validate_timestamps=1 | Major | Проверки FS на каждый запрос |
| Файловые сессии | Major | Не масштабируется, потеря данных |
| Не задан часовой пояс | Minor | Несогласованные даты |
| Стандартные лимиты загрузки | Minor | Может блокировать загрузки |
| Нет настройки realpath cache | Minor | Лишние обращения к FS |
| JIT не настроен | Minor | Упущенный прирост производительности |

## Формат вывода

```markdown
### Проблема конфигурации PHP: [Описание]

**Серьёзность:** Critical/Major/Minor
**Настройка:** `directive = value`
**Расположение:** `Dockerfile:line` или `config-file:line`

**Текущее значение:**
```ini
directive = current_value
```

**Рекомендуемое значение:**
```ini
directive = recommended_value
```

**Обоснование:**
[Почему эта настройка важна для production]
```
