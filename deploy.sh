#!/bin/bash

set -e

# ============================================
# Настройки
# ============================================
REPO_URL="https://github.com/yudzhi/shvirtd-example-python.git"
PROJECT_DIR="/opt/shvirtd-example-python"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }

print_green "========================================="
print_green "Развёртывание проекта на ВМ"
print_green "========================================="

# Шаг 1: Клонирование репозитория
print_yellow "Шаг 1: Клонирование репозитория..."
if [ -d "$PROJECT_DIR" ]; then
    print_yellow "Директория $PROJECT_DIR уже существует. Удаляем..."
    sudo rm -rf "$PROJECT_DIR"
fi

sudo git clone "$REPO_URL" "$PROJECT_DIR"

# Шаг 2: Переход в папку проекта
print_yellow "Шаг 2: Переход в папку проекта..."
cd "$PROJECT_DIR"

# Шаг 3: Проверка наличия файлов
print_yellow "Шаг 3: Проверка файлов..."
ls -la

## Шаг 3.1: Убедиться, что .env существует
#if [ ! -f ".env" ]; then
#    print_red "Файл .env не найден! Создаём..."
#    cat > .env << 'EOF'
#MYSQL_ROOT_PASSWORD="YtReWq4321"
#MYSQL_DATABASE="virtd"
#MYSQL_USER="app"
#MYSQL_PASSWORD="QwErTy1234"
#EOF
#fi

# Шаг 4: Остановка старых контейнеров
print_yellow "Шаг 4: Остановка старых контейнеров..."
docker compose down -v 2>/dev/null || true

# Шаг 5: Сборка и запуск
print_yellow "Шаг 5: Сборка и запуск проекта..."
docker compose build --no-cache
docker compose up -d

# Шаг 6: Ожидание готовности
print_yellow "Шаг 6: Ожидание готовности сервисов (30 секунд)..."
sleep 30

# Шаг 7: Проверка статуса
print_yellow "Шаг 7: Статус контейнеров..."
docker compose ps

# Шаг 8: Проверка работы
print_yellow "Шаг 8: Проверка работы приложения..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090)

if [ "$RESPONSE" == "200" ]; then
    print_green "✅ УСПЕХ! Приложение работает на порту 8090"
    print_green "========================================="
    print_green "Внешний IP: $(curl -s ifconfig.me)"
    print_green "Проверка: http://$(curl -s ifconfig.me):8090"
    print_green "========================================="
else
    print_red "❌ ОШИБКА! Код ответа: $RESPONSE"
    print_yellow "Логи:"
    docker compose logs --tail=20
    exit 1
fi

# Шаг 9: Показать логи
print_yellow "Шаг 9: Последние логи..."
docker compose logs --tail=10
