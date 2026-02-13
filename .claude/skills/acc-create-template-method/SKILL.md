---
name: acc-create-template-method
description: Генерирует паттерн Template Method для PHP 8.2. Создаёт абстрактный скелет алгоритма с настраиваемыми шагами, позволяя подклассам переопределять отдельные части без изменения структуры. Включает юнит-тесты.
---

# Генератор паттерна Template Method

Создаёт инфраструктуру паттерна Template Method для скелетов алгоритмов с настраиваемыми шагами.

## Когда использовать

| Сценарий | Пример |
|----------|---------|
| Общая структура алгоритма | Импорт/экспорт данных с вариациями форматов |
| Контролируемые точки расширения | Генерация отчётов с настраиваемыми секциями |
| Повторное использование кода между вариантами | Обработка заказов с зависящими от типа шагами |
| Защита инвариантных частей | Рендеринг шаблонов с хуками |

## Характеристики компонентов

### Абстрактный класс Template

- Определяет скелет алгоритма
- Реализует инвариантные шаги
- Объявляет абстрактные/хук-методы
- Вызывает методы в последовательности

### Конкретные реализации

- Переопределяют конкретные шаги
- Предоставляют варианты алгоритма
- Наследуют общее поведение
- Сохраняют общую структуру

### Хук-методы

- Опциональные точки переопределения
- Пустая реализация по умолчанию
- Позволяют настройку
- Не нарушают поток

---

## Процесс генерации

### Шаг 1: Генерация абстрактного Template

**Путь:** `src/Domain/{BoundedContext}/Template/`

1. `Abstract{Name}Template.php` — Скелет алгоритма с шаблонным методом

### Шаг 2: Генерация конкретных Templates

**Путь:** `src/Domain/{BoundedContext}/Template/` или `src/Application/{BoundedContext}/`

1. `{Variant1}{Name}Template.php` — Первый вариант реализации
2. `{Variant2}{Name}Template.php` — Второй вариант реализации
3. `{Variant3}{Name}Template.php` — Третий вариант реализации

### Шаг 3: Генерация вспомогательных классов (опционально)

**Путь:** `src/Domain/{BoundedContext}/ValueObject/`

1. `{Name}Result.php` — Value object результата
2. `{Name}Config.php` — Value object конфигурации

### Шаг 4: Генерация тестов

1. `{Variant}{Name}TemplateTest.php` — Тесты отдельных шаблонов
2. `Abstract{Name}TemplateTest.php` — Тесты скелета шаблона

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Абстрактный Template | `src/Domain/{BoundedContext}/Template/` |
| Конкретные Templates (доменная логика) | `src/Domain/{BoundedContext}/Template/` |
| Конкретные Templates (логика приложения) | `src/Application/{BoundedContext}/` |
| Юнит-тесты | `tests/Unit/Domain/{BoundedContext}/Template/` |

---

## Соглашения об именовании

| Компонент | Паттерн | Пример |
|-----------|---------|---------|
| Абстрактный | `Abstract{Name}Template` | `AbstractDataImporterTemplate` |
| Конкретный | `{Variant}{Name}Template` | `CsvDataImporterTemplate` |
| Шаблонный метод | `execute()` или `process()` | `execute()` |
| Хук-метод | `before{Step}()`, `after{Step}()` | `beforeValidation()` |
| Тест | `{ClassName}Test` | `CsvDataImporterTemplateTest` |

---

## Краткий справочник по шаблонам

### Абстрактный Template

```php
abstract readonly class Abstract{Name}Template
{
    public function execute({InputType} $input): {OutputType}
    {
        $this->validate($input);
        $data = $this->extract($input);
        $transformed = $this->transform($data);
        $result = $this->load($transformed);
        $this->afterLoad($result);

        return $result;
    }

    abstract protected function extract({InputType} $input): array;
    abstract protected function transform(array $data): array;

    protected function validate({InputType} $input): void
    {
        // Валидация по умолчанию
    }

    protected function afterLoad({OutputType} $result): void
    {
        // Хук-метод — опциональное переопределение
    }
}
```

### Конкретный Template

```php
final readonly class {Variant}{Name}Template extends Abstract{Name}Template
{
    protected function extract({InputType} $input): array
    {
        // Извлечение специфичное для варианта
    }

    protected function transform(array $data): array
    {
        // Трансформация специфичная для варианта
    }
}
```

---

## Пример использования

```php
// Создаём шаблоны для разных форматов
$csvImporter = new CsvDataImporterTemplate();
$jsonImporter = new JsonDataImporterTemplate();
$xmlImporter = new XmlDataImporterTemplate();

// Используем одинаковый интерфейс
$result = $csvImporter->execute($fileContent);
```

---

## Общие варианты Template Method

| Домен | Варианты |
|--------|----------|
| Импорт данных | CSV, JSON, XML, Excel |
| Генерация отчётов | PDF, Excel, HTML, Email |
| Обработка заказов | Standard, Express, International |
| Рендеринг документов | Markdown, LaTeX, HTML |
| Поток оплаты | Card, Bank Transfer, Digital Wallet |

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|--------------|---------|----------|
| Слишком много абстрактных методов | Сложно реализовать | Использовать хук-методы с реализацией по умолчанию |
| Публичные шаги шаблона | Нарушает инкапсуляцию | Делать шаги protected/private |
| Изменяемое состояние | Побочные эффекты | Использовать readonly классы, передавать данные |
| Глубокое наследование | Сложность | Ограничить 2-3 уровнями |
| Нарушение LSP | Несогласованное поведение | Сохранять контракт в переопределениях |

---

## Ссылки

Для полных PHP-шаблонов и примеров см.:
- `references/templates.md` — Abstract Template, Concrete Template, Hook Methods шаблоны
- `references/examples.md` — DataImporter, ReportGenerator, OrderProcessor с тестами
