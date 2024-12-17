#!/bin/bash

show_menu() {
    echo "Please select an option:"
    echo "1) Build node"
    echo "2) Run node"
    echo "3) Restart docker"
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

check_jwt() {
    cat $HOME/soneium-minato-node/jwt.txt
}

full_docker_prune() {
    docker system prune -a -f
}

while true; do
    show_menu
    read -p "Select an option [1-8]: " option
    case $option in
        1) build_node ;;
        2) run_node ;;
        3) restart_docker ;;
        6) check_jwt ;;
        7) full_docker_prune ;;
        8) exit ;;
        *) echo "Invalid option. Please select a valid option." ;;
    esac
done