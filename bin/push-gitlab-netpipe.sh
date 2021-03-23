#!/bin/bash

SOURCE_NAME="datalyze/local-dev-proxy"
TARGET_NAME="registry.gitlab.com/netpipe/software/development/local-dev-proxy"

GITLAB_REGISTRY_USERNAME="kube.netpipe@gmail.com"
GITLAB_REGISTRY_URL="registry.gitlab.com"
echo "${GITLAB_REGISTRY_PASSWORD}" | docker login --username "${GITLAB_REGISTRY_USERNAME}" --password-stdin "${GITLAB_REGISTRY_URL}"

retag_image() {
    local source="${1}"
    local target="${2}"

    echo "Retagging ${source} to ${target}"
    docker pull "${source}"
    docker tag "${source}" "${target}"
    docker push "${target}"
}

SERVICES=("traefik" "mkcert" "installer" "hosts-updater")
TAGS=("latest")
for tag in ${TAGS[@]}; do
    for service in ${SERVICES[@]}; do
        source="${SOURCE_NAME}/${service}:${tag}"
        target="${TARGET_NAME}/${service}:${tag}"
        retag_image "${source}" "${target}"
    done
done

# docker logout "${GITLAB_REGISTRY_URL}"
