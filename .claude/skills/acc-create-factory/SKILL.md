---
name: acc-create-factory
description: Генерирует DDD Factory для PHP 8.2. Создает фабрики для сложного создания объектов домена с валидацией и инкапсулированной логикой создания. Включает юнит-тесты.
---

# Factory Generator

Генерация DDD-совместимых фабрик для создания сложных доменных объектов.

## Характеристики фабрики

- **Инкапсулирует создание**: Скрывает сложную логику создания экземпляров
- **Валидирует входные данные**: Обеспечивает создание валидных объектов
- **Именованные конструкторы**: Предоставляет семантические методы создания
- **Доменный слой**: Находится в Domain, без зависимостей от инфраструктуры
- **Возвращает валидные объекты**: Никогда не создает невалидные доменные объекты
- **Статическая или экземплярная**: Статическая для простых случаев, экземплярная для зависимостей

## Когда использовать фабрику

| Сценарий | Пример |
|----------|---------|
| Сложная логика создания | `OrderFactory::createFromCart()` |
| Множество путей создания | `User::register()`, `User::createAdmin()` |
| Создание агрегата | `PolicyFactory::createWithCoverage()` |
| Реконструкция из персистентности | `OrderFactory::reconstitute()` |
| Создание с валидацией | `InvoiceFactory::create()` |

---

## Процесс генерации

### Шаг 1: Определить тип фабрики

- **Статическая фабрика**: Без зависимостей, простая валидация
- **Экземплярная фабрика**: Требует доменные сервисы или репозитории

### Шаг 2: Генерировать фабрику

**Путь:** `src/Domain/{BoundedContext}/Factory/`

1. `{Entity}Factory.php` — Основной класс фабрики

### Шаг 3: Определить методы создания

1. `create()` — Основное создание с валидацией
2. `createFrom{Source}()` — Создание из других объектов
3. `reconstitute()` — Реконструкция из персистентности (без валидации)

### Шаг 4: Генерировать тесты

**Путь:** `tests/Unit/Domain/{BoundedContext}/Factory/`

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Factory | `src/Domain/{BoundedContext}/Factory/` |
| Unit Tests | `tests/Unit/Domain/{BoundedContext}/Factory/` |

---

## Соглашения об именах

| Шаблон | Пример |
|---------|---------|
| Класс фабрики | `{EntityName}Factory` |
| Метод создания | `create()`, `createFrom{Source}()` |
| Именованный конструктор | `create{Variant}()` |
| Реконструкция | `reconstitute()` |
| Валидация | `validate{Aspect}()` |

---

## Краткая справка по шаблонам

### Статическая фабрика

```php
final class {Entity}Factory
{
    public static function create({parameters}): {Entity}
    {
        self::validate({parameters});
        return new {Entity}({constructorArgs});
    }

    public static function createFrom{Source}({SourceType} $source): {Entity}
    {
        return new {Entity}({mappedArgs});
    }

    public static function reconstitute({allFields}): {Entity}
    {
        return new {Entity}({allArgs});
    }

    private static function validate({parameters}): void
    {
        {validationLogic}
    }
}
```

### Экземплярная фабрика

```php
final readonly class {Entity}Factory
{
    public function __construct(
        private {DomainService} $service,
        private {Repository} $repository
    ) {}

    public function create({parameters}): {Entity}
    {
        {creationLogicWithDependencies}
    }
}
```

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|--------------|---------|----------|
| Инфраструктура в фабрике | Вызовы БД в фабрике | Держать чистую доменную логику |
| Нет валидации | Создает невалидные объекты | Валидировать перед созданием |
| Слишком много параметров | Сложно использовать | Использовать Value Objects, Builder |
| Изменяемая фабрика | Состояние при создании | Делать без состояния или readonly |
| Отсутствие reconstitute | Невозможно гидрировать из БД | Добавить метод reconstitute |

---

## Ссылки

Полные PHP-шаблоны и примеры см.:
- `references/templates.md` — Шаблоны Static Factory, Instance Factory, Test
- `references/examples.md` — Примеры фабрик Order, User, Policy с тестами
