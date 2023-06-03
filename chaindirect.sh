#!/bin/bash
# Created By: Jayrald B. Empino

PORT=8012
NODE_ID=$1
DEV=$2
VERSION="v2.1.11"

if [ "$DEV" = "dev" ]; then
  VERSION=dev
fi

if [ -x "$(command -v docker)" ]; then

  echo "Docker detected"

else
  
  apt-get update
  apt-get install -y cloud-utils apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install -y docker-ce
  usermod -aG docker ubuntu

  if [ -x "$(command -v docker)" ]; then
    echo "Docker is now installed"
  else
    echo "Docker installation failed"
    exit 0
  fi

fi

echo "Proceeding pulling chaindirect image"

docker pull chaindirect/chain-direct:$VERSION

echo " "
echo "Checking blockchain_network network if exists"
if docker network inspect blockchain_network >/dev/null 2>&1; then
  echo "The blockchain_network network exists. Proceeding to run the image"
else
  echo "The blockchain_network network does not exist. Proceeding to create the network..."
  docker network create blockchain_network
  echo "blockchain_network created."
fi

echo " "



#if netstat -ln | grep ":$PORT " >/dev/null; then
#    echo "Port $PORT is in use"
#    echo "Allocating new port..."
#    PORT=$(shuf -i 8013-65535 -n 1)
#    echo "New port: $PORT"
#fi

# if [ "$DEV" = "true" ]; then
#   docker volume create $NODE_ID
#   npm run dev
# else 
# fi

docker run -d --net host --restart always --name $NODE_ID -v /var/run/docker.sock:/var/run/docker.sock -v $NODE_ID:/chaindirect -v /var/lib/docker/volumes/$NODE_ID/_data:/var/lib/docker/volumes/$NODE_ID/_data -v /etc/chaindirect:/etc/chaindirect -e NODE_ID=$NODE_ID -p $PORT:8012 chaindirect/chain-direct:$VERSION

echo " "

interfaces=( $(ip -o link show | awk -F': ' '{print $2}') )

echo -e "\033[1mSetup your node: \033[0m"

for i in "${interfaces[@]}"
do
    if ! ip link show "$i" &> /dev/null; then
        continue
    fi
    
    IP_ADDRESS=$(ip -o -4 addr show dev "$i" | awk '{split($4,a,"/"); print a[1]}')
    
    if [ -z "$IP_ADDRESS" ]; then
        continue
    fi
    
    echo -e "\033[32mhttp://$IP_ADDRESS:$PORT\033[0m"
done
