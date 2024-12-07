#!/bin/bash

# Функция для отображения меню
show_menu() {
    echo "Выберите действие:"
    echo "1) Установить ноду"
    echo "2) Посмотреть логи op-node"
    echo "3) Посмотреть логи op-geth"
    echo "5) Посмотреть приватный ключ"
    echo "6) Посмотреть версию"
    echo "7) Удалить ноду"
    echo "8) Выйти"
}

# Функция для поиска свободного порта, увеличивая на 10
find_free_port() {
    local port=$1
    while true; do
        if ! lsof -i:$port >/dev/null 2>&1 && ! netstat -tulpn 2>/dev/null | grep -w ":$port" >/dev/null 2>&1; then
            echo "$port"
            return 0
        else
            echo "Порт $port занят, пробуем порт $((port+10))" >&2
            port=$((port+10))
        fi
    done
}


# Функция для настройки портов
setup_ports() {
    echo "Проверка и настройка портов..."

    # Порты по умолчанию
    PORT_8551=8551
    PORT_6060=6060
    PORT_8545=8545
    PORT_8546=8546
    PORT_30303=30303
    PORT_9545=9545
    PORT_7310=7310
    PORT_9222=9222

    # Проверка и назначение свободных портов
    PORT_8551=$(find_free_port $PORT_8551)
    PORT_6060=$(find_free_port $PORT_6060)
    PORT_8545=$(find_free_port $PORT_8545)
    PORT_8546=$(find_free_port $PORT_8546)
    PORT_30303=$(find_free_port $PORT_30303)
    PORT_9545=$(find_free_port $PORT_9545)
    PORT_7310=$(find_free_port $PORT_7310)
    PORT_9222=$(find_free_port $PORT_9222)

    echo "Назначенные порты:"
    echo "PORT_8551: $PORT_8551"
    echo "PORT_6060: $PORT_6060"
    echo "PORT_8545: $PORT_8545"
    echo "PORT_8546: $PORT_8546"
    echo "PORT_30303: $PORT_30303"
    echo "PORT_9545: $PORT_9545"
    echo "PORT_7310: $PORT_7310"
    echo "PORT_9222: $PORT_9222"

    # Открытие необходимых портов
    ports=($PORT_8551 $PORT_6060 $PORT_8545 $PORT_8546 $PORT_30303 $PORT_9545 $PORT_7310 $PORT_9222)
    for port in "${ports[@]}"; do
        if sudo ufw status | grep -w "$port" >/dev/null 2>&1; then
            echo "Порт $port уже открыт."
        else
            echo "Открываем порт $port..."
            sudo ufw allow $port
        fi
    done

    cp files/docker-compose.yml docker-compose.yml

    # OP-geth service
    sed -i "s/\"[0-9]*:8551\"/\"$PORT_8551:8551\"/g" docker-compose.yml
    sed -i "s/\"[0-9]*:6060\"/\"$PORT_6060:6060\"/g" docker-compose.yml
    sed -i "s/\"[0-9]*:8545\"/\"$PORT_8545:8545\"/g" docker-compose.yml
    sed -i "s/\"[0-9]*:8546\"/\"$PORT_8546:8546\"/g" docker-compose.yml
    sed -i "s/\"[0-9]*:30303\"/\"$PORT_30303:30303\"/g" docker-compose.yml

    # OP-node service
    sed -i "s/\"[0-9]*:9545\"/\"$PORT_9545:9545\"/g" docker-compose.yml
    sed -i "s/\"[0-9]*:7310\"/\"$PORT_7310:7310\"/g" docker-compose.yml
    sed -i "s/\"[0-9]*:9222\"/\"$PORT_9222:9222\"/g" docker-compose.yml
}

# Функция для установки ноды
install_node() {
    # Обновление системы
    sudo apt update && sudo apt upgrade -y

    # Установка необходимых зависимостей
    dependencies=(curl git jq build-essential gcc unzip wget lz4 openssl)
    for pkg in "${dependencies[@]}"; do
        if ! dpkg -s $pkg >/dev/null 2>&1; then
            echo "Устанавливается $pkg..."
            sudo apt install $pkg -y
        else
            echo "$pkg уже установлен, пропускаем..."
        fi
    done

    # Установка Docker, если не установлен
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker не установлен. Устанавливаем Docker..."
        # Удаление старых версий
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg -y; done
        # Установка Docker
        sudo apt-get update
        sudo apt-get install ca-certificates curl gnupg -y
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        sudo docker run hello-world
    else
        echo "Docker уже установлен, пропускаем..."
    fi


    # Генерация JWT секретного ключа, если не существует или пустой
    if [ ! -s "jwt.txt" ]; then
        openssl rand -hex 32 > jwt.txt
        if [ $? -ne 0 ]; then
            echo "Ошибка при генерации JWT секретного ключа!"
            exit 1
        else
            echo "JWT секретный ключ сгенерирован."
        fi
    else
        echo "JWT секретный ключ уже существует, пропускаем..."
    fi

    # Получение публичного IP адреса
    PUBLIC_IP=$(curl -s api.ipify.org)
    echo "Ваш публичный IP: $PUBLIC_IP"

    # Изменение файла .env
    if [ ! -f ".env" ]; then
        if cp files/sample.env .env; then
            echo ".env файл успешно скопирован."
        else
            echo "Ошибка при копировании sample.env в .env!"
            exit 1
        fi
    fi

    # копирование файлов из папки files (minato-genesis.json, minato-rollup.json)
    if cp minato/minato-rollup.json ./ && cp minato/minato-genesis.json ./; then
        echo "minato-rollup.json и minato-genesis.json успешно скопированы."
    else
        echo "Ошибка при копировании minato-rollup.json или minato-genesis.json!"
        exit 1
    fi

    sed -i "s|<Node Public IP>|$PUBLIC_IP|g" .env
    sed -i "s|L1_URL=.*|L1_URL=https://ethereum-sepolia-rpc.publicnode.com|" .env
    sed -i "s|L1_BEACON=.*|L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|" .env

    # Изменение файла docker-compose.yml
    sed -i "s|<your_node_public_ip>|$PUBLIC_IP|g" docker-compose.yml

    # Настройка портов
    setup_ports

    # Запуск Docker контейнеров
    docker-compose up -d

    sleep 5

    if lsof -i:9443 >/dev/null 2>&1; then
        echo "Portainer запущен и доступен по адресу: http://$PUBLIC_IP:9443"
    else
        echo "Portainer не запустился."
    fi

    echo "Нода установлена и запущена."
}

# Остальные функции остаются без изменений...

# Функция для просмотра логов op-node
view_op_node_logs() {

    docker-compose logs -f op-node-minato
}

# Функция для просмотра логов op-geth
view_op_geth_logs() {

    docker-compose logs -f op-geth-minato
}


# Функция для просмотра приватного ключа
view_private_key() {
    if [ -f "$HOME/soneium-node/minato/jwt.txt" ]; then
        echo "Ваш приватный ключ:"
        cat $HOME/soneium-node/minato/jwt.txt
    else
        echo "jwt.txt не найден!"
    fi
}

# Функция для просмотра версии
view_version() {
    cd $HOME/soneium-node/minato
    NODE_VERSION=$(docker ps -a | grep "op-node-minato" | awk '{print $2}')
    GETH_VERSION=$(docker ps -a | grep "op-geth-minato" | awk '{print $2}')
    echo "Node version: $NODE_VERSION"
    echo "Geth version: $GETH_VERSION"
}

# Функция для удаления ноды
remove_node() {
    docker-compose down
    cd $HOME
    rm -rf soneium-node
    echo "Нода удалена."
}

# Главный цикл меню
while true; do
    show_menu
    read -p "Введите номер действия: " choice
    case $choice in
        1)
            install_node
            ;;
        2)
            view_op_node_logs
            ;;
        3)
            view_op_geth_logs
            ;;
        4)
            view_private_key
            ;;
        5)
            view_version
            ;;
        6)
            remove_node
            ;;
        7)
            echo "Выход из программы."
            exit 0
            ;;
        *)
            echo "Неверный выбор, попробуйте снова."
            ;;
    esac
done
