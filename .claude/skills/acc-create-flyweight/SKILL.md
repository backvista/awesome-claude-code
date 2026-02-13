---
name: acc-create-flyweight
description: Генерирует паттерн Flyweight для PHP 8.2. Оптимизирует память через разделяемое внутреннее состояние. Включает юнит-тесты.
---

# Flyweight Pattern Generator

Создает инфраструктуру паттерна Flyweight для оптимизации памяти через разделение объектов.

## Когда использовать

| Сценарий | Пример |
|----------|---------|
| Большое количество похожих объектов | Иконки, глифы, частицы |
| Ограничения памяти | Мобильные приложения, встроенные системы |
| Неизменяемое разделяемое состояние | Коды валют, налоговые ставки |
| Оптимизация производительности | Снижение накладных расходов на создание объектов |

## Характеристики компонентов

### Flyweight Interface
- Определяет операции
- Принимает внешнее состояние как параметры

### ConcreteFlyweight
- Хранит внутреннее состояние (разделяемое)
- Неизменяемый
- Переиспользуемый в разных контекстах

### FlyweightFactory
- Создает и управляет flyweight'ами
- Возвращает существующий или новый flyweight
- Обеспечивает разделение

---

## Процесс генерации

### Шаг 1: Генерировать Flyweight Interface

**Путь:** `src/Domain/{BoundedContext}/`

1. `{Name}Interface.php` — Контракт операций

### Шаг 2: Генерировать ConcreteFlyweight

**Путь:** `src/Domain/{BoundedContext}/`

1. `{Name}Flyweight.php` — Разделяемый объект

### Шаг 3: Генерировать FlyweightFactory

**Путь:** `src/Domain/{BoundedContext}/Factory/` или `src/Infrastructure/`

1. `{Name}FlyweightFactory.php` — Управление flyweight'ами

### Шаг 4: Генерировать тесты

1. `{ClassName}Test.php` — Тесты поведения Flyweight и проверка разделения

---

## Размещение файлов

| Компонент | Путь |
|-----------|------|
| Flyweight Interface | `src/Domain/{BoundedContext}/` |
| ConcreteFlyweight | `src/Domain/{BoundedContext}/` |
| FlyweightFactory | `src/Domain/{BoundedContext}/Factory/` |
| Unit Tests | `tests/Unit/Domain/{BoundedContext}/` |

---

## Соглашения об именах

| Компонент | Шаблон | Пример |
|-----------|---------|---------|
| Flyweight Interface | `{Name}Interface` | `CurrencyInterface` |
| ConcreteFlyweight | `{Name}Flyweight` | `CurrencyFlyweight` |
| FlyweightFactory | `{Name}FlyweightFactory` | `CurrencyFlyweightFactory` |
| Test | `{ClassName}Test` | `CurrencyFlyweightTest` |

---

## Краткая справка по шаблонам

### Flyweight

```php
final readonly class {Name}Flyweight implements {Name}Interface
{
    public function __construct(
        private string $intrinsicState
    ) {}

    public function {operation}(string $extrinsicState): {returnType}
    {
        return {combine intrinsic and extrinsic state};
    }
}
```

### FlyweightFactory

```php
final class {Name}FlyweightFactory
{
    private array $flyweights = [];

    public function getFlyweight(string $key): {Name}Interface
    {
        if (!isset($this->flyweights[$key])) {
            $this->flyweights[$key] = new {Name}Flyweight($key);
        }

        return $this->flyweights[$key];
    }

    public function getCount(): int
    {
        return count($this->flyweights);
    }
}
```

---

## Пример использования

```php
$factory = new CurrencyFlyweightFactory();

// Возвращается один и тот же объект
$usd1 = $factory->getFlyweight('USD');
$usd2 = $factory->getFlyweight('USD');

assert($usd1 === $usd2); // true

// Форматирование с внешним состоянием
$usd1->format(100.50); // "$100.50"
```

---

## Распространенные Flyweight'ы

| Flyweight | Назначение |
|-----------|---------|
| CurrencyFlyweight | Коды и символы валют |
| IconFlyweight | UI иконки |
| TaxRuleFlyweight | Налоговые ставки по регионам |
| CharacterFlyweight | Глифы для отрисовки текста |
| ColorFlyweight | Цветовые палитры |

---

## Антипаттерны, которых следует избегать

| Антипаттерн | Проблема | Решение |
|--------------|---------|----------|
| Изменяемый Flyweight | Изменения состояния влияют на всех пользователей | Сделать flyweight неизменяемым |
| Нет фабрики | Ручное управление объектами | Использовать фабрику flyweight |
| Большое внутреннее состояние | Память не оптимизирована | Держать внутреннее состояние минимальным |
| Внешнее в Flyweight | Не переиспользуемый | Передавать внешнее через параметры |
| Преждевременная оптимизация | Сложность без пользы | Сначала профилировать |

---

## Ссылки

Полные PHP-шаблоны и примеры см.:
- `references/templates.md` — Шаблоны Flyweight, фабрики
- `references/examples.md` — Currency, icon, tax rule flyweight'ы с юнит-тестами
