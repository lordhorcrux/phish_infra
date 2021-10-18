#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi

phish_infra_dir=/opt/phish_infra

function usage {
    echo "Usage: $0 -m gophish -d example.org -s login admin blog" >&2
    echo "       $0 -m evilginx -d example.org -t info -s login admin blog" >&2
    echo "       $0 -a gophish -d extra.org -s login admin blog" >&2
    echo "       $0 -a evilginx -d extra.org -t info -s login admin blog" >&2
    echo "" >&2
    echo "    -m : mode" >&2
    echo "    -a : add domains and subdomains"
    echo "    -d : domain" >&2
    echo "    -s : subdomains" >&2
    echo "    -t : tracking domain" >&2
    exit 1    
}

function calc_hosts {
  if ! [ -z "$subdomains" ]; then
    for i in ${!subdomains[@]}
    do
        hosts_here[i+1]=${subdomains[i]}.$domain
    done
    hosts_here[0]=$domain
    printf -v joined '%s,' "${hosts_here[@]}"
    hosts_here=`echo "${joined%,}"`
  else
    hosts_here=$domain
  fi
}

function gen_certs {
    mkdir -p $phish_infra_dir/certs
    cd $phish_infra_dir/certs
    openssl genrsa 2048 > $domain.key
    openssl req -new -x509 -nodes -sha256 -days 365 -key $domain.key -out $domain.crt -subj "/C=US/ST=Oregon/L=Portland/CN=*.$domain"
}

function compose_init {
    cp $phish_infra_dir/docker-compose.$1 $phish_infra_dir/docker-compose.yml
}

function compose_down_up {
    cd $phish_infra_dir
    docker-compose down
    docker-compose up -d    
}

function check_domain {
  if [ -z "$domain" ]; then
  {
    usage
  }
  fi
}

gophish() { 
    gen_certs
    calc_hosts
    compose_init gophish
    sed -i "s/hosts_here/$hosts_here/g" $phish_infra_dir/docker-compose.yml
    compose_down_up
}

evilginx() {
    if ! [ -z "$tracker" ];then
    {
      tracker=$tracker.$domain
    }
    fi
    gen_certs
    calc_hosts
    compose_init evilginx
    sed -i "s/tracker_here/$tracker/g" $phish_infra_dir/docker-compose.yml
    sed -i "s/hosts_here/$hosts_here/g" $phish_infra_dir/docker-compose.yml
    compose_down_up
    tmux kill-session -t evilginx
    tmux new-session -d -s evilginx && tmux send-keys -t evilginx "cd $phish_infra_dir/evilginx && ./evilginx" Enter
}

gophish_add() {
    gen_certs
    calc_hosts
    old_hosts=`cat $phish_infra_dir/docker-compose.yml | grep gophish -A5 | grep VIRTUAL_HOST | cut -d"=" -f2`
    hosts_here="$old_hosts,$hosts_here"
    sed -i "s/$old_hosts/$hosts_here/g" $phish_infra_dir/docker-compose.yml
    compose_down_up
}

evilginx_add() {
    if ! [ -z "$tracker" ];then
    {
      tracker=$tracker.$domain
    }
    fi
    gen_certs
    calc_hosts
    if ! [ -z "$tracker" ];then
    {
      old_tracker=`cat $phish_infra_dir/docker-compose.yml | grep gophish -A5 | grep VIRTUAL_HOST | cut -d"=" -f2`
      tracker=$old_tracker,$tracker
      sed -i "s/$old_tracker/$tracker/g" $phish_infra_dir/docker-compose.yml
    }
    fi
    old_hosts=`cat $phish_infra_dir/docker-compose.yml | grep evilginx -A5 | grep VIRTUAL_HOST | cut -d"=" -f2`
    hosts_here="$old_hosts,$hosts_here"
    sed -i "s/$old_hosts/$hosts_here/g" $phish_infra_dir/docker-compose.yml
    compose_down_up
    tmux kill-session -t evilginx
    tmux new-session -d -s evilginx && tmux send-keys -t evilginx "cd $phish_infra_dir/evilginx && ./evilginx" Enter
}

while getopts 'm:a:d:s:t:' flag; do
    case "$flag" in
      m)
        mode=${OPTARG}
        ;;
      a)
        add=${OPTARG}
        ;;
      d)
        domain=${OPTARG}
        ;;
      s)
        subdomains=("$OPTARG")
        until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                subdomains+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
        done
        ;;
      t)
        tracker=${OPTARG}
        ;;
      *)
        usage
        ;;
    esac
done

check_domain

if ! [ -z "$mode" ]; then
  {
    case $mode in
      gophish)
        gophish
        ;;
      evilginx)
        evilginx
        ;;
      *)
        usage
        ;;
    esac
  }
else
  {
    case $add in
      gophish)
        gophish_add
        ;;
      evilginx)
        evilginx_add
        ;;
      *)
        usage
        ;;
    esac    
  }
fi

echo "Done!"
