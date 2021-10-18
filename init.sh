#!/bin/bash

# Ubuntu 20.04 LTS

if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi
packages="docker docker.io docker-compose curl wget nano git"
DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y dist-upgrade && apt-get install -y $packages && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
for image in evilginx gophish nginx-proxy
do
    docker pull scarfaced/rt:$image
    docker tag scarfaced/rt:$image $image
    docker rmi scarfaced/rt:$image
done
git clone https://github.com/thirdbyte/phish_infra /opt/phish_infra
mkdir -p /opt/phish_infra
cp /opt/phish_infra/setup.sh /usr/local/bin/setphish
chmod +x /usr/local/bin/setphish
