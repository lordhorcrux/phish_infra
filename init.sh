#!/bin/bash

# Ubuntu 20.04 LTS

if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi
packages="git openssl unzip docker docker.io docker-compose net-tools iputils-ping iproute2 curl wget nano"
DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y dist-upgrade && apt-get install -y $packages && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
for image in evilginx gophish nginx-proxy
do
    docker pull scarfaced/rt:$image
    docker tag scarfaced/rt:$image $image
    docker rmi scarfaced/rt:$image
done
git clone https://github.com/thirdbyte/phish_infra /opt/phish_infra
mkdir -p /opt/phish_infra
