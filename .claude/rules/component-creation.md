---
paths:
  - .claude/commands/*.md
  - .claude/agents/*.md
  - .claude/skills/**/SKILL.md
---

# Создание компонентов

## Команда (`.claude/commands/acc-name.md`)

```yaml
---
description: Обязательное поле (отображается в /help)
allowed-tools: Опционально (например, "Read, Grep, Glob, Bash, Task")
model: Опционально (sonnet|haiku|opus — opus для координаторов)
argument-hint: Опционально (например, "<path> [-- instructions]")
---
```

Команды парсят `$ARGUMENTS` для ввода. Разделитель `--` передает мета-инструкции. Всегда явно указывайте `model:` (`sonnet` для большинства, `opus` для координаторов).

## Агент (`.claude/agents/acc-name.md`)

```yaml
---
name: Обязательное поле (соответствует имени файла без .md)
description: Обязательное поле
tools: Опционально (по умолчанию: все инструменты)
model: Опционально (по умолчанию: opus)
skills: acc-skill-one, acc-skill-two
---
```

**Важно**: `skills:` — это список через запятую (не YAML массив). Имена навыков должны точно соответствовать именам папок навыков.

Для координаторов с 3+ фазами: добавьте `TaskCreate, TaskUpdate` в tools, включите `acc-task-progress-knowledge` в skills.

## Навык (`.claude/skills/acc-name/SKILL.md`)

```yaml
---
name: Обязательное поле (строчные буквы, дефисы, должно совпадать с именем папки)
description: Обязательное поле (макс. 1024 символа)
---
```

Максимум 500 строк в SKILL.md — большой контент выносите в подпапку `references/`.
