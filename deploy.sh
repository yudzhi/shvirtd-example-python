#!/bin/bash

set -e  # Остановить скрипт при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }

print_green "========================================="
print_green "Начинаем развёртывание приложения"
print_green "========================================="

# Шаг 1: Очистка старых контейнеров
print_yellow "Шаг 1: Очистка старых контейнеров..."
docker compose down -v 2>/dev/null || true

# Шаг 1.2: (опционально) Полная очистка - раскомментировать если нужна
# print_yellow "Шаг 1.2: Полная очистка (удаление образов и томов)..."
# docker compose down -rmi all --volumes --remove-orphans 2>/dev/null || true 

# Шаг 2: Проверка синтаксиса compose.yaml
print_yellow "Шаг 2: Проверка синтаксиса compose.yaml..."
docker compose config > /dev/null
print_green "✅ Синтаксис корректный"

# Шаг 3: Сборка Docker-образа
print_yellow "Шаг 3: Сборка Docker-образа для Python приложения..."
docker compose build --no-cache

# Шаг 4: Запуск всех сервисов
print_yellow "Шаг 4: Запуск всех сервисов..."
docker compose up -d

# Шаг 5: Ожидание готовности сервисов
print_yellow "Шаг 5: Ожидание готовности сервисов (30 секунд)..."
sleep 30

# Шаг 6: Проверка статуса контейнеров
print_yellow "Шаг 6: Проверка статуса контейнеров..."
docker compose ps

# Шаг 7: Проверка логов
print_yellow "Шаг 7: Проверка логов (последние 10 строк)..."
docker compose logs --tail=10

# Шаг 8: Тестирование приложения
print_yellow "Шаг 8: Тестирование приложения через порт 8090..."

print_green "Отправляем тестовый запрос на http://localhost:8090..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090)

if [ "$RESPONSE" == "200" ]; then
    print_green "✅ УСПЕХ! Приложение отвечает с кодом $RESPONSE"
    print_green "========================================="
    print_green "Развёртывание завершено успешно!"
    print_green "========================================="
    print_green ""
    print_green "Проверьте работу:"
    print_green "  curl http://localhost:8090"
    print_green "  curl http://localhost:8090/requests"
    print_green "  curl http://localhost:8090/debug"
    print_green ""
    print_green "Остановить всё: docker compose down"
    print_green "Просмотр логов: docker compose logs -f"
else
    print_red "❌ ОШИБКА! Приложение отвечает с кодом $RESPONSE"
    print_red "Проверьте логи: docker compose logs"
    exit 1
fi
