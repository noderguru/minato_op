Скриптик на установку свежей версии Soneum, которую надо запустить до December 20, 2024

git clone https://github.com/noderguru/minato_op.git

cd minato_op

chmod +x composer.sh

./composer.sh

если у вас есть jwt ключ со старой версии, то просто переместите файл jwt.txt в директорию /root/soneium-minato-node/ если нет ключа сгенерите при помощи скрипта 4й пункт меню

выбираете 1) Build node

nano /root/soneium-minato-node/.env

в переменной L1_URL=https://lb.drpc.org/ogrpc?network=sepolia&dkey=ВАШ---КЛЮЧ----API сеть Sepolia!!!!!!!!!!  можно взять тут https://drpc.org/dashboard

в переменной L1_BEACON=https://eth-beacon-chain-sepolia.drpc.org/rest/

сохраняем и выходим CTRL+O  Enter CTRL+X

./composer.sh

выбираете 2) Run node



Доп команды:

cd /root/soneium-minato-node/

docker-compose logs -f op-geth-minato

docker-compose logs -f op-node-minato

проверка ключа внутри контейнера
docker-compose exec op-geth-minato cat /etc/optimism/jwt.txt

проверка версий:

docker-compose exec op-geth-minato geth version (должна быть 1.101411.3)

docker-compose exec op-node-minato op-node --version  (должна быть  v1.10.1)


