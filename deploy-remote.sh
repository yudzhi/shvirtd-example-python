#!/bin/bash

# ============================================
# deploy-remote.sh — автоматический деплой на ВМ
# ============================================

set -e

# ============================================
# Настройки
# ============================================
VM_NAME="compute-vm-2-2-20-hdd-1781781614146"
SSH_USER="yudzhi"

# Цвета
RED='\033[0:31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }

# ===============================================
# --- Получение EXTERNAL_IP из Yandex Cloud ---
# ===============================================
echo "=== Получение внешнего IP ВМ ==="

# Получить IP по имени ВМ
# EXTERNAL_IP=$(yc compute instance get compute-vm-2-2-20-hdd-1781781614146 --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

if [ -n "$VM_IP" ]; then
    EXTERNAL_IP="$VM_IP"
else
    if command -v jq &> /dev/null; then
        EXTERNAL_IP=$(yc compute instance get $VM_NAME --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')
    else
        EXTERNAL_IP=$(yc compute instance get $VM_NAME --format json | grep -o '"one_to_one_nat": {[^}]*"address": "[^"]*"' | grep -o '"address": "[^"]*"' | head -1 | cut -d'"' -f4)
    fi
fi

# Проверить, что IP получен
if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
    echo "❌ Ошибка: не удалось получить IP ВМ"
    echo "Проверьте, что ВМ с именем 'compute-vm-2-2-20-hdd-1781781614146' существует и запущена"
    exit 1
fi

print_green "✅ Внешний IP: $EXTERNAL_IP"

# ============================================
# Деплой
# ============================================
print_green "========================================="
print_green "Деплой на ВМ $EXTERNAL_IP"
print_green "========================================="

# Проверка SSH
print_yellow "Проверка SSH..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$EXTERNAL_IP "echo 'OK'" 2>/dev/null; then
    print_red "❌ SSH недоступен"
    exit 1
fi
print_green "✅ SSH доступен"

# === Копирование через sudo с перенаправлением ===
print_yellow "Копирование deploy.sh через ssh..."

ssh $SSH_USER@$EXTERNAL_IP "sudo bash -c 'cat > /opt/deploy.sh'" < deploy.sh
ssh $SSH_USER@$EXTERNAL_IP "sudo chmod +x /opt/deploy.sh"

print_green "✅ deploy.sh скопирован на ВМ"

# Копируем deploy.sh на ВМ
#scp -o StrictHostKeyChecking=accept-new deploy.sh yudzhi@$EXTERNAL_IP:/opt/deploy.sh

# Запуск
print_yellow "Запуск deploy.sh на ВМ..."
ssh $SSH_USER@$EXTERNAL_IP "sudo /opt/deploy.sh"

print_green "✅ Деплой завершён!"
print_green "Проверка: http://$EXTERNAL_IP:8090"
