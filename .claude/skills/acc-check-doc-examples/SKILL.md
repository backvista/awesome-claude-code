---
name: acc-check-doc-examples
description: Проверяет примеры кода в документации. Сверяет имена классов, сигнатуры методов, пространства имен и импорты с реальной кодовой базой. Обнаруживает устаревшие и вводящие в заблуждение примеры.
---

# Проверка примеров кода в документации

Анализ документации на предмет примеров кода, не соответствующих реальной кодовой базе.

## Паттерны обнаружения

### 1. Неправильное имя класса в примере

```markdown
<!-- DOC says: -->
```php
use App\Service\OrderProcessor;
$processor = new OrderProcessor();
```
<!-- But actual class is App\Application\Order\ProcessOrderUseCase -->
```

### 2. Неверная сигнатура метода

```markdown
<!-- DOC says: -->
```php
$user = $repository->findByEmail($email);
```
<!-- But actual method signature is: -->
```php
public function findByEmail(Email $email): ?User  // Uses Email VO, not string
```

### 3. Устаревшее пространство имен

```markdown
<!-- DOC says: -->
```php
use App\Models\User;  // Laravel-style
```
<!-- But project uses DDD structure: -->
```php
use App\UserManagement\Domain\Entity\User;
```

### 4. Отсутствующие обязательные параметры

```markdown
<!-- DOC says: -->
```php
$order = Order::create($userId, $items);
```
<!-- But actual method requires: -->
```php
Order::create(UserId $userId, ItemCollection $items, Currency $currency, Address $shippingAddress)
```

### 5. Устаревший API в примерах

```markdown
<!-- DOC says: -->
```php
$service->process($data);  // process() was renamed to execute()
```
<!-- Method was renamed but docs not updated -->

## Процесс проверки

### Шаг 1: Извлечение блоков кода из документации

```bash
# Find PHP code blocks in markdown
Grep: "```php" --glob "**/*.md" -A 20

# Find inline code references
Grep: "`[A-Z][a-zA-Z]+::[a-z]" --glob "**/*.md"
Grep: "`\\$[a-z]+->|new [A-Z]" --glob "**/*.md"
```

### Шаг 2: Проверка ссылок на классы

```bash
# For each class mentioned in docs, verify it exists
# Example: doc mentions "OrderProcessor"
Grep: "class OrderProcessor" --glob "**/*.php"

# Verify namespace matches
Grep: "namespace.*Order" --glob "**/*.php"
```

### Шаг 3: Проверка сигнатур методов

```bash
# For each method call in doc examples
# Example: doc mentions "$repo->findByEmail($email)"
Grep: "function findByEmail" --glob "**/*.php"
# Compare parameter types and count
```

### Шаг 4: Проверка путей импорта

```bash
# For each use statement in doc examples
# Example: "use App\Service\OrderProcessor"
Glob: **/Service/OrderProcessor.php
# If not found, search for actual location
Grep: "class OrderProcessor" --glob "**/*.php"
```

### Шаг 5: Проверка параметров конструктора

```bash
# For each "new ClassName(...)" in docs
# Verify constructor matches
Grep: "class OrderProcessor" --glob "**/*.php" -A 20
# Check __construct parameters
```

## Классификация по степени важности

| Паттерн | Важность |
|---------|----------|
| Несуществующий класс в install/quickstart | 🔴 Критическая |
| Неверная сигнатура метода в документации API | 🔴 Критическая |
| Устаревшее пространство имен в примерах | 🟠 Высокая |
| Отсутствующие обязательные параметры | 🟠 Высокая |
| Устаревший метод в примерах | 🟡 Средняя |
| Разница в стиле (не функциональная) | 🟡 Средняя |

## Формат вывода

```markdown
### Несоответствие примера кода: [Описание]

**Важность:** 🔴/🟠/🟡
**Документация:** `file.md:line`
**Ссылка на код:** `src/path/File.php:line`

**В документации:**
```php
// What the doc says
```

**В реальном коде:**
```php
// What the code actually is
```

**Исправление:**
Обновить документацию в соответствии с текущим кодом.
```

## Формат сводного отчета

```markdown
## Проверка примеров кода

| Метрика | Количество |
|--------|-------|
| Проверено блоков кода | X |
| Корректных примеров | X |
| Несовпадений имен классов | X |
| Несовпадений сигнатур методов | X |
| Несовпадений пространств имен | X |
| Использования устаревшего API | X |

### Несоответствующие примеры

| Файл документации | Строка | Ссылка | Проблема |
|----------|------|-----------|-------|
| `README.md` | 45 | `OrderProcessor` | Класс не найден |
| `docs/api.md` | 78 | `findByEmail()` | Неверные параметры |
```
