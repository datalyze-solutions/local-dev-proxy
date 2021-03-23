#!/bin/sh

set -e

traefik_label=proxy_proxy
network_name=web

traefik_container_id() {
    docker container ls -q -f name=${traefik_label:-${traefik_label}}
}

wait_for_traefik() {
    # ping -q returns just the return code $?
    # 0 ==> traefik up
    # 1 ==> traefik down
    until ping -q -c1 ${1:-proxy}; do
        echo >&2 "Traefik is unavailable - sleeping"
        sleep 2
    done
    echo "Traefik is available"
    echo
}

add_container_to_network() {
    docker network connect ${2:-network_name} ${1}
}

check_if_connected_to_web_swarm() {
    docker container inspect ${1} | grep ${2:-network_name}
}

if [ "$1" = 'connect' ]; then
    wait_for_traefik $(traefik_container_id)
    add_container_to_network $(traefik_container_id) $network_name && echo "connected traefik to '$network_name'" || echo "traefik is still connected to '$network_name'"
else
    exec "$@"
fi
