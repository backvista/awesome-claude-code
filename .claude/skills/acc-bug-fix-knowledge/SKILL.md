---
name: acc-bug-fix-knowledge
description: База знаний по исправлению ошибок. Предоставляет категории ошибок, симптомы, паттерны исправлений и принципы минимального вмешательства для проектов на PHP 8.2.
---

# База знаний по исправлению ошибок

Комплексная база знаний для диагностики и исправления ошибок в PHP-приложениях, следующих паттернам DDD, CQRS и Clean Architecture.

## Категории ошибок и симптомы

### 1. Логические ошибки
**Симптомы:**
- Некорректный вывод для валидного ввода
- Неправильная ветка в условных операторах
- Инвертированная булева логика
- Ошибки на единицу в циклах
- Необработанные граничные случаи

**Частые причины:**
- `>` вместо `>=`, `&&` вместо `||`
- Ошибки отрицания (`!$condition` вместо `$condition`)
- Ошибки границ цикла (`< count` вместо `<= count`)
- Отсутствующий `break` в switch-операторах

**Паттерн исправления:**
```php
// Before: Logic error
if ($amount > $limit) { // Should be >=
    throw new LimitExceededException();
}

// After: Fixed
if ($amount >= $limit) {
    throw new LimitExceededException();
}
```

### 2. Проблемы с Null
**Симптомы:**
- "Call to a member function on null"
- "Cannot access property on null"
- Неожиданные null-возвраты
- Отсутствующие проверки null после опциональных операций

**Частые причины:**
- Repository возвращает null для несуществующей сущности
- Опциональные связи не проверены
- Nullable-параметры не валидированы
- Цепочка вызовов на потенциально null-объектах

**Паттерн исправления:**
```php
// Before: Null pointer risk
$user = $this->userRepository->find($id);
$email = $user->getEmail(); // Crashes if user is null

// After: Safe with null check
$user = $this->userRepository->find($id);
if ($user === null) {
    throw new UserNotFoundException($id);
}
$email = $user->getEmail();

// Alternative: Null coalescing
$email = $user?->getEmail() ?? throw new UserNotFoundException($id);
```

### 3. Проблемы границ
**Симптомы:**
- Выход за пределы индекса массива
- Доступ к пустой коллекции
- Ошибки строковых индексов
- Числовое переполнение/потеря разрядности

**Частые причины:**
- Доступ к первому/последнему элементу без проверки пустоты
- Индекс цикла превышает размер массива
- Целочисленное переполнение при вычислениях
- Отсутствующая валидация границ

**Паттерн исправления:**
```php
// Before: Boundary issue
$firstItem = $items[0]; // Crashes if empty

// After: Safe boundary check
if ($items === []) {
    throw new EmptyCollectionException('items');
}
$firstItem = $items[0];

// Alternative: Using first() with default
$firstItem = $items[0] ?? throw new EmptyCollectionException('items');
```

### 4. Состояния гонки
**Симптомы:**
- Периодические сбои
- Повреждение данных под нагрузкой
- Потерянные обновления
- Дублирование записей

**Частые причины:**
- Проверка-затем-действие без блокировки
- Разделяемое изменяемое состояние
- Отсутствующие транзакции БД
- Конкурентный доступ к файлам

**Паттерн исправления:**
```php
// Before: Race condition
if (!$this->repository->exists($id)) {
    $this->repository->save($entity); // Another process might insert between check and save
}

// After: Atomic operation with locking
$this->lockManager->acquire("entity:$id");
try {
    if (!$this->repository->exists($id)) {
        $this->repository->save($entity);
    }
} finally {
    $this->lockManager->release("entity:$id");
}

// Alternative: Database-level uniqueness
// Use UNIQUE constraint + INSERT ... ON DUPLICATE KEY
```

### 5. Утечки ресурсов
**Симптомы:**
- Исчерпание памяти со временем
- "Too many open files"
- Исчерпание пула соединений БД
- Постепенная деградация производительности

**Частые причины:**
- Незакрытые файловые дескрипторы
- Отсутствующее освобождение соединений БД
- Обработчики событий не удалены
- Циклические ссылки, препятствующие GC

**Паттерн исправления:**
```php
// Before: Resource leak
$handle = fopen($path, 'r');
$content = fread($handle, filesize($path));
// Missing fclose()

// After: Proper resource management
$handle = fopen($path, 'r');
try {
    $content = fread($handle, filesize($path));
} finally {
    fclose($handle);
}

// Better: Use high-level functions
$content = file_get_contents($path);
```

### 6. Проблемы обработки исключений
**Симптомы:**
- Тихие сбои
- Общие сообщения об ошибках
- Потеря контекста исключений
- Проглоченные исключения

**Частые причины:**
- Пустые блоки catch
- Перехват слишком широких типов исключений
- Отсутствие повторного выброса после логирования
- Отсутствующая цепочка исключений

**Паттерн исправления:**
```php
// Before: Swallowed exception
try {
    $this->service->process($data);
} catch (Exception $e) {
    // Silent failure - bug hidden
}

// After: Proper exception handling
try {
    $this->service->process($data);
} catch (ValidationException $e) {
    throw new ProcessingFailedException(
        "Failed to process data: {$e->getMessage()}",
        previous: $e
    );
}
```

### 7. Проблемы типов
**Симптомы:**
- "Type error: Argument must be of type X, Y given"
- Неожиданное приведение типов
- Путаница string/int
- Несоответствие array/object

**Частые причины:**
- Отсутствующее объявление strict_types
- Неявное приведение типов
- Смешанные типы из внешних источников
- Устаревший код без подсказок типов

**Паттерн исправления:**
```php
// Before: Type issue
function calculate($amount) { // No type hint
    return $amount * 1.1; // Fails if string passed
}

// After: Strict typing
declare(strict_types=1);

function calculate(float $amount): float {
    return $amount * 1.1;
}
```

### 8. SQL-инъекции
**Симптомы:**
- Уязвимости безопасности
- Неожиданные результаты запросов
- Повреждение данных
- Обход аутентификации

**Частые причины:**
- Конкатенация строк в запросах
- Отсутствующая привязка параметров
- Невалидированный пользовательский ввод в запросах
- Динамические имена таблиц/столбцов

**Паттерн исправления:**
```php
// Before: SQL injection vulnerability
$query = "SELECT * FROM users WHERE email = '$email'";

// After: Parameterized query
$query = "SELECT * FROM users WHERE email = :email";
$stmt = $pdo->prepare($query);
$stmt->execute(['email' => $email]);
```

### 9. Бесконечные циклы
**Симптомы:**
- Зависание приложения
- 100% загрузка CPU
- Таймауты запросов
- Исчерпание памяти

**Частые причины:**
- Отсутствующее или недостижимое условие выхода
- Итератор не продвигается
- Рекурсивный вызов без базового случая
- Циклические зависимости в обработке

**Паттерн исправления:**
```php
// Before: Potential infinite loop
while ($item = $queue->pop()) {
    $this->process($item);
    // If process() adds items back to queue, infinite loop
}

// After: Safe with limit
$maxIterations = 10000;
$iterations = 0;
while ($item = $queue->pop()) {
    if (++$iterations > $maxIterations) {
        throw new MaxIterationsExceededException($maxIterations);
    }
    $this->process($item);
}
```

## Принципы минимального вмешательства

### 1. Исправление единственной ответственности
- Исправлять ТОЛЬКО ошибку, ничего более
- Никакого рефакторинга при исправлении
- Никаких улучшений «пока я тут»
- Минимальный diff

### 2. Сохранение поведения
- Существующие тесты должны проходить
- Контракты API не должны меняться
- Побочные эффекты должны сохраняться (если намеренные)
- Формат сообщений об ошибках должен совпадать

### 3. Обратная совместимость
- Сигнатуры публичных методов без изменений
- Возвращаемые типы без изменений
- Типы исключений без изменений
- Payload событий без изменений

### 4. Сначала тест
- Написать падающий тест, воспроизводящий ошибку
- Исправление должно сделать тест зелёным
- Никаких исправлений без теста воспроизведения

## Чек-лист валидации исправления

Перед применением исправления проверьте:

1. **Тест воспроизведения существует**
   - [ ] Тест падает без исправления
   - [ ] Тест проходит с исправлением
   - [ ] Тест покрывает граничные случаи

2. **Минимальное изменение**
   - [ ] Изменён только затронутый код
   - [ ] Нет несвязанного рефакторинга
   - [ ] Нет изменений форматирования

3. **Нет регрессий**
   - [ ] Все существующие тесты проходят
   - [ ] Нет новых предупреждений
   - [ ] Производительность не деградировала

4. **Качество кода**
   - [ ] Нет новых code smells
   - [ ] Принципы SOLID соблюдены
   - [ ] Паттерны DDD сохранены

5. **Документация**
   - [ ] PHPDoc обновлён при необходимости
   - [ ] Запись в CHANGELOG добавлена
   - [ ] Issue связан в коммите

## Паттерны ошибок, специфичные для DDD

### Ошибки Domain Layer
- Обход валидации Value Object
- Нарушение инвариантов Entity
- Пересечение границы Aggregate
- Потеря Domain Event

### Ошибки Application Layer
- Use Case без транзакции
- Смешивание Command/Query
- Отсутствующая проверка авторизации
- Event handler не идемпотентен

### Ошибки Infrastructure Layer
- Repository возвращает отсоединённую сущность
- Отсутствующая инвалидация кеша
- Сообщение не подтверждено
- Соединение не освобождено

## Краткий справочник: исправление по сообщению об ошибке

| Сообщение об ошибке | Вероятная ошибка | Быстрое исправление |
|---------------------|------------------|---------------------|
| "Call to member function on null" | Null pointer | Добавить проверку null |
| "Undefined array key" | Проблема границ | Проверить array_key_exists |
| "Type error: Argument X" | Проблема типов | Добавить валидацию типов |
| "Maximum execution time" | Бесконечный цикл | Добавить лимит итераций |
| "Allowed memory exhausted" | Утечка ресурсов | Закрывать ресурсы в finally |
| "Integrity constraint violation" | Состояние гонки | Добавить блокировку/транзакцию |
| "Cannot modify readonly property" | Нарушение неизменяемости | Создать новый экземпляр |
