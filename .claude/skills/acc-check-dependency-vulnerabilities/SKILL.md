---
name: acc-check-dependency-vulnerabilities
description: Анализирует PHP-зависимости на уязвимости безопасности. Обнаруживает устаревшие пакеты, известные CVE, неподдерживаемые версии, уязвимые транзитивные зависимости.
---

# Проверка уязвимостей зависимостей

Анализ зависимостей PHP-проекта на уязвимости безопасности.

## Процесс анализа

### 1. Проверка composer.json/composer.lock

```bash
# Read composer.lock to get exact versions
cat composer.lock | jq '.packages[] | {name, version}'

# Check for outdated packages
composer outdated --direct

# Security audit
composer audit
```

### 2. Распространённые уязвимые пакеты

| Пакет | Уязвимые версии | Проблема | CVE |
|-------|-----------------|----------|-----|
| symfony/http-kernel | < 4.4.50 | Request smuggling | CVE-2022-24894 |
| guzzlehttp/guzzle | < 7.4.5 | Header injection | CVE-2022-31090 |
| doctrine/dbal | < 2.13.9 | SQL injection | CVE-2021-43608 |
| laravel/framework | < 8.83.27 | SQL injection | CVE-2022-44268 |
| phpseclib | < 3.0.14 | RCE | CVE-2023-27560 |
| twig/twig | < 2.15.3 | SSTI | CVE-2022-39261 |
| phpmailer/phpmailer | < 6.5.0 | XSS | CVE-2021-34551 |
| monolog/monolog | < 2.7.0 | RCE via SMTP | CVE-2022-29244 |

### 3. Версии с истёкшим сроком поддержки

```php
// CRITICAL: EOL PHP versions
// PHP 7.4 - EOL November 2022
// PHP 8.0 - EOL November 2023

// Check supported versions:
// PHP 8.1 - Security fixes until December 2025
// PHP 8.2 - Security fixes until December 2026
// PHP 8.3 - Security fixes until December 2027
```

### 4. Паттерны обнаружения

```json
// composer.json - Risky version constraints
{
    "require": {
        "vendor/package": "*",        // CRITICAL: Any version
        "vendor/package": ">=1.0",    // VULNERABLE: Too permissive
        "vendor/package": "^1.0",     // OK: Semver constraint
        "vendor/package": "1.2.3",    // Best: Exact version
        "vendor/package": "dev-main"  // CRITICAL: Unstable
    }
}
```

### 5. Заброшенные пакеты

```bash
# Check for abandoned packages
composer show --abandoned

# Common abandoned packages to replace:
# phpunit/dbunit → Use fixtures
# zendframework/* → laminas/*
# swiftmailer/swiftmailer → symfony/mailer
# paragonie/random_compat → Use random_bytes() (PHP 7+)
```

### 6. Транзитивные зависимости

```bash
# Check dependency tree
composer depends vendor/package

# Find why a vulnerable package is included
composer why vendor/vulnerable-package
```

## Grep-паттерны

```bash
# composer.json with wildcard versions
Grep: '"\\*"|"dev-|">=|">' --glob "**/composer.json"

# Known vulnerable package names
Grep: "guzzlehttp/guzzle|symfony/http-kernel|doctrine/dbal" --glob "**/composer.lock"

# EOL PHP version
Grep: '"php":\s*"[^"]*7\.[0-4]|"php":\s*"[^"]*8\.0' --glob "**/composer.json"
```

## Классификация серьёзности

| Паттерн | Серьёзность |
|---------|-------------|
| Известная CVE с эксплоитом | Critical |
| EOL-версия PHP | Critical |
| Заброшенный пакет с проблемами | Major |
| Устаревший с исправлениями безопасности | Major |
| Wildcard-ограничение версии | Minor |

## Ресурсы по уязвимостям

- **PHP Security Advisories Database**: https://github.com/FriendsOfPHP/security-advisories
- **Snyk Vulnerability DB**: https://snyk.io/vuln
- **NVD**: https://nvd.nist.gov/
- **Packagist Advisories**: https://packagist.org/advisories

## Устранение

### Процесс обновления

```bash
# Check what will be upgraded
composer update --dry-run

# Update specific package
composer update vendor/package --with-dependencies

# Update all packages
composer update

# After update, run tests
./vendor/bin/phpunit
```

### Ограничения версий

```json
{
    "require": {
        // Good: Specific minor version
        "vendor/package": "^2.5",

        // Best: Lock to patch version in production
        "vendor/package": "2.5.3"
    }
}
```

### Управление lock-файлом

```bash
# Always commit composer.lock
git add composer.lock

# Use consistent platform
composer config platform.php 8.2

# Audit before deploy
composer audit --locked
```

## Формат вывода

```markdown
### Уязвимая зависимость: [package-name]

**Серьёзность:** Critical/Major/Minor
**Текущая версия:** 1.2.3
**Исправленная версия:** 1.2.4
**CVE:** CVE-2024-XXXX

**Проблема:**
[Описание уязвимости]

**Риск:**
[Что может сделать атакующий]

**Расположение:**
- `composer.lock:line` (прямая зависимость)
- Требуется для: `other/package`

**Исправление:**
```bash
composer update vendor/package
```

**Обходное решение (если обновление невозможно):**
[Временная мера]
```

## Автоматическое сканирование

### GitHub Dependabot

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

### Интеграция в CI/CD

```yaml
# In CI pipeline
- name: Security Audit
  run: composer audit --format=json > audit.json

- name: Check for vulnerabilities
  run: |
    if [ -s audit.json ]; then
      cat audit.json
      exit 1
    fi
```

## Важные замечания

1. **Всегда проверяйте composer.lock** — не только composer.json
2. **Транзитивные зависимости важны** — у ваших зависимостей есть свои зависимости
3. **Регулярный аудит** — запускайте `composer audit` в CI/CD
4. **Тестируйте после обновлений** — обновления безопасности могут сломать функциональность
5. **Мониторьте рекомендации** — подпишитесь на рассылки по безопасности
