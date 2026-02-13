.PHONY: help list-commands list-skills list-agents validate-claude changelog release test test-clear upgrade

.DEFAULT_GOAL := help

# Цвета
GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RESET  := \033[0m

help: ## Показать эту справку
	@echo ""
	@echo "$(CYAN)Доступные команды:$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Компоненты Claude
# =============================================================================

list-commands: ## Список всех доступных slash-команд
	@echo ""
	@echo "$(CYAN)Доступные команды:$(RESET)"
	@echo ""
	@if [ -d ".claude/commands" ]; then \
		find .claude/commands -name "*.md" -type f | while read file; do \
			name=$$(basename "$$file" .md); \
			desc=$$(head -1 "$$file" 2>/dev/null | sed 's/^#* *//'); \
			printf "  $(GREEN)/%-20s$(RESET) %s\n" "$$name" "$$desc"; \
		done; \
	else \
		echo "  $(YELLOW)Команды не найдены$(RESET)"; \
	fi
	@echo ""

list-skills: ## Список всех доступных навыков
	@echo ""
	@echo "$(CYAN)Доступные навыки:$(RESET)"
	@echo ""
	@if [ -d ".claude/skills" ]; then \
		find .claude/skills -name "*.md" -type f | while read file; do \
			name=$$(basename "$$file" .md); \
			desc=$$(grep -m1 "^description:" "$$file" 2>/dev/null | sed 's/^description: *//'); \
			printf "  $(GREEN)%-20s$(RESET) %s\n" "$$name" "$$desc"; \
		done; \
	else \
		echo "  $(YELLOW)Навыки не найдены$(RESET)"; \
	fi
	@echo ""

list-agents: ## Список всех доступных агентов
	@echo ""
	@echo "$(CYAN)Доступные агенты:$(RESET)"
	@echo ""
	@if [ -d ".claude/agents" ]; then \
		find .claude/agents -name "*.md" -type f | while read file; do \
			name=$$(basename "$$file" .md); \
			desc=$$(head -1 "$$file" 2>/dev/null | sed 's/^#* *//'); \
			printf "  $(GREEN)%-20s$(RESET) %s\n" "$$name" "$$desc"; \
		done; \
	else \
		echo "  $(YELLOW)Агенты не найдены$(RESET)"; \
	fi
	@echo ""

validate-claude: ## Валидация структуры директории .claude
	@echo ""
	@echo "$(CYAN)Валидация структуры .claude...$(RESET)"
	@echo ""
	@errors=0; \
	if [ ! -d ".claude" ]; then \
		echo "  $(YELLOW)Предупреждение: директория .claude не найдена$(RESET)"; \
		exit 0; \
	fi; \
	for dir in commands skills agents; do \
		if [ -d ".claude/$$dir" ]; then \
			echo "  $(GREEN)✓$(RESET) .claude/$$dir существует"; \
			count=$$(find ".claude/$$dir" -name "*.md" -type f | wc -l | tr -d ' '); \
			echo "    Найдено $$count markdown файлов"; \
		else \
			echo "  $(YELLOW)○$(RESET) .claude/$$dir не найден (опционально)"; \
		fi; \
	done; \
	echo ""; \
	echo "$(CYAN)Проверка markdown синтаксиса...$(RESET)"; \
	find .claude -name "*.md" -type f | while read file; do \
		if head -1 "$$file" | grep -q "^#\|^---"; then \
			echo "  $(GREEN)✓$(RESET) $$file"; \
		else \
			echo "  $(YELLOW)?$(RESET) $$file (заголовок не найден)"; \
		fi; \
	done; \
	echo ""

# =============================================================================
# Обновление
# =============================================================================

upgrade: ## Принудительное обновление компонентов Claude (создает резервную копию)
	@./bin/acc upgrade

# =============================================================================
# Тестирование
# =============================================================================

test: ## Установка пакета в тестовое окружение (tests/)
	@echo ""
	@echo "$(CYAN)Установка пакета в тестовое окружение...$(RESET)"
	@cd tests && docker compose run --rm php composer install --no-interaction
	@echo ""
	@echo "$(GREEN)Готово! Проверьте tests/.claude/ для установленных компонентов$(RESET)"
	@echo ""

test-clear: ## Очистка тестового окружения (удаление vendor, .claude)
	@echo ""
	@echo "$(CYAN)Очистка тестового окружения...$(RESET)"
	@rm -rf tests/vendor tests/composer.lock tests/.claude
	@echo "$(GREEN)Готово!$(RESET)"
	@echo ""

# =============================================================================
# Релиз
# =============================================================================

changelog: ## Генерация changelog из git коммитов
	@echo ""
	@echo "$(CYAN)Changelog:$(RESET)"
	@echo ""
	@git log --oneline --no-merges HEAD~10..HEAD 2>/dev/null || git log --oneline --no-merges -10
	@echo ""

release: validate-claude ## Подготовка релиза (запуск проверок)
	@echo ""
	@echo "$(GREEN)Все проверки пройдены!$(RESET)"
	@echo ""
	@echo "$(CYAN)Для создания релиза:$(RESET)"
	@echo "  1. Обновите версию в composer.json (при необходимости)"
	@echo "  2. git add -A && git commit -m 'Release vX.Y.Z'"
	@echo "  3. git tag vX.Y.Z"
	@echo "  4. git push origin master --tags"
	@echo ""
