Скриптик на установку свежей версии Soneum, которую надо запустить до December 20, 2024

git clone https://github.com/noderguru/minato_op.git

cd minato-op

chmod +x composer.sh

./composer.sh

выбираете 1) Build node

если у вас есть jwt ключ со старой версии, то просто переместите файл jwt.txt в директорию root/minato-op/ если нет ключа сгенерите при помощи скрипта 4й пункт меню

nano .env 

в переменной L1_URL=https://lb.drpc.org/ogrpc?network=sepolia&dkey=ВАШ---КЛЮЧ----API !!!!!!!!!!
в переменной L1_BEACON=https://eth-beacon-chain-sepolia.drpc.org/rest/

сохраняем и выходим CTRL+O  Enter CTRL+X

./composer.sh

выбираете 2) Run node
