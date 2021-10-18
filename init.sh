#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi
packages="openssl unzip docker docker.io docker-compose net-tools iputils-ping iproute2 curl wget nano"
DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y dist-upgrade && apt-get install -y $packages && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
for image in rt:evilginx rt:gophish rt:nginx-proxy
do
    docker pull scarfaced/$image
    docker tag scarfaced/$image $image
    docker rmi scarfaced/$image
done
git clone https://github.com/thirdbyte/phish_infra /opt/phish_infra
mkdir -p /opt/phish_infra
