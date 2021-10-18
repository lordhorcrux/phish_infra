#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi
dockerhub_username="scarfaced"
phish_infra_dir=/opt/phish_infra
packages="openssl unzip docker docker.io docker-compose net-tools iputils-ping iproute2 curl wget nano"
DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y dist-upgrade && apt-get install -y $packages && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
for image in rt:evilginx rt:gophish rt:nginx-proxy
do
    docker pull $dockerhub_username/$image
    docker tag $dockerhub_username/$image $image
    docker rmi $dockerhub_username/$image
done
mkdir -p $phish_infra_dir/certs
