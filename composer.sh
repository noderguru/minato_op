#!/bin/bash

show_menu() {
    echo "Please select an option:"
    echo "1) Build node"
    echo "2) Run node"
    echo "3) Restart docker"
    echo "4) Generate jwt file"
    echo "6) Check jwt file"
    echo "7) Full docker prune"
    echo "8) Exit"
}

build_node() {
    mkdir -p $HOME/soneium-minato-node
    cp -r files/* $HOME/soneium-minato-node
    
    if [ -f "$HOME/soneium-minato-node/jwt.txt" ]; then
        echo "Nice! Your token restored"
    else
        echo "Please generate your token first and then run the script again"
    fi

    cd $HOME/soneium-minato-node
    mv sample.env .env
    docker-compose build
}

run_node() {
    cd $HOME/soneium-minato-node
    docker-compose up -d

    my_ip=$(curl -s ifconfig.me)
    echo "Geth-Minato metric address: http://$my_ip:6060"
    echo "Node-Minato metric address: http://$my_ip:7310"
    echo "Portainer address: http://$my_ip:9443"
}

restart_docker() {
    cd $HOME/soneium-minato-node
    docker-compose restart
}

generate_jwt() {
    mkdir -p $HOME/soneium-minato-node

    if ! command -v openssl &> /dev/null; then
        echo "openssl is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y openssl
    fi

    if [ -f "$HOME/soneium-minato-node/jwt.txt" ]; then
        read -p "jwt.txt already exists. Overwrite? (y/n): " overwrite
        if [ "$overwrite" != "y" ]; then
            echo "Skipping jwt file generation."
            return
        fi
    fi

    openssl rand -hex 32 > $HOME/soneium-minato-node/jwt.txt
    echo "New jwt.txt file generated at $HOME/soneium-minato-node/jwt.txt"
}

check_jwt() {
    if [ -f "$HOME/soneium-minato-node/jwt.txt" ]; then
        cat $HOME/soneium-minato-node/jwt.txt
    else
        echo "jwt.txt file not found in $HOME/soneium-minato-node"
    fi
}

full_docker_prune() {
    docker stop $(docker ps -aq) && docker system prune -af --volumes
}

while true; do
    show_menu
    echo "Make sure to set values in .env file for L1_URL, L1_BEACON, P2P_ADVERTISE_IP"
    read -p "Select an option [1-8]: " option
    case $option in
        1) build_node ;;
        2) run_node ;;
        3) restart_docker ;;
        4) generate_jwt ;;
        6) check_jwt ;;
        7) full_docker_prune ;;
        8) exit ;;
        *) echo "Invalid option. Please select a valid option." ;;
    esac
done
