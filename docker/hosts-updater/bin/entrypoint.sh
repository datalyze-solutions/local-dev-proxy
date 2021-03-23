#!/usr/bin/env bash

set -e
set -o pipefail

# import shlibs
source /usr/local/bin/shlibs/index.sh

export HOSTS_HOST_FILE="${HOSTS_HOST_FILE:-/host/etc/hosts}"
export HOSTS_TEMPLATE="/templates/hosts.tmpl"
export ADDITIONAL_FILE_DIR="/tmp/hosts.d"
export HOSTS_OUTPUT="${ADDITIONAL_FILE_DIR:-/tmp}/docker.hosts"

exec_docker_gen() {
  local template="${1}"
  local temporary_output="${2:-/dev/null}"

  docker-gen \
    -watch \
    -wait "2ms:4s" \
    -notify "update-hosts-file --update --cleanup --hosts-file ${HOSTS_HOST_FILE} --additional-file-dir ${ADDITIONAL_FILE_DIR}" \
    "${template}" "${temporary_output}"
}

# SIGTERM-handler
# will not be called, if you start the container with 'docker-compose up' without '-d'
# this will send the unblockable SIGKILL directly
shutdown() {
  log_info "received SIGTERM, going down gracefully"

  docker_gen_pid=$(pgrep docker-gen)
  kill ${docker_gen_pid}

  # remove added lines
  update-hosts-file --cleanup --hosts-file ${HOSTS_HOST_FILE} --additional-file-dir ${ADDITIONAL_FILE_DIR}

  exit 143 # 128 + 15 -- SIGTERM
}

wait_indefinitely() {
  log_info "Wait forever"
  while true; do
    tail -f /dev/null &
    wait "${!}"
  done
}

if [ ! -f "$HOSTS_HOST_FILE" ]; then
  log_error "$HOSTS_HOST_FILE does not exist."
  exit 1
fi

mkdir -p ${ADDITIONAL_FILE_DIR}
trap 'kill ${!}; shutdown' SIGTERM
trap 'kill ${!}; shutdown' SIGINT

# while true; do inotifywait -e modify  && make; done

if [ "$1" = 'development' ]; then
  log_info "Starting development mode"

  export LOGGING_LEVEL="debug"
  exec_docker_gen "${HOSTS_TEMPLATE}" "${HOSTS_OUTPUT}" &
  wait_indefinitely
fi

if [ "$1" = 'production' ]; then
  log_info "Starting production mode"
  exec_docker_gen "${HOSTS_TEMPLATE}" "${HOSTS_OUTPUT}" &
  wait_indefinitely
fi

exec "$@"
