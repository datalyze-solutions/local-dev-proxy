#!/usr/bin/env bash

set -e
set -o pipefail

# import shlibs
source /usr/local/bin/shlibs/index.sh

export HOSTS_HOST_FILE="${HOSTS_HOST_FILE:-/host/etc/hosts}"
export HOSTS_TEMPLATE="/templates/hosts.tmpl"
export ADDITIONAL_FILE_DIR="/tmp/hosts.d"
export HOSTS_OUTPUT="${ADDITIONAL_FILE_DIR:-/tmp}/docker.hosts"
export BACKUP_DIR="/backups"

exec_docker_gen() {
  local template="${1}"
  local temporary_output="${2:-/dev/null}"

  docker-gen \
    -watch \
    -wait "2ms:4s" \
    -interval 10 \
    -notify "update-hosts-file.py update ${HOSTS_HOST_FILE} ${ADDITIONAL_FILE_DIR}/docker.hosts --hostname=$(hosts_hostname) --backup-dir=${BACKUP_DIR}" \
    "${template}" "${temporary_output}"
  # -notify "update-hosts-file --update --cleanup --hosts-file ${HOSTS_HOST_FILE} --additional-file-dir ${ADDITIONAL_FILE_DIR}" \
}

hosts_hostname() {
  cat /host/etc/hostname
}

do_backup() {
  log_info "Backing up hosts file"
  update-hosts-file.py backup "${HOSTS_HOST_FILE}" "${BACKUP_DIR}"
  ls -alh "${BACKUP_DIR}"
}

# SIGTERM-handler
# will not be called, if you start the container with 'docker-compose up' without '-d'
# this will send the unblockable SIGKILL directly
shutdown() {
  log_info "received SIGTERM, going down gracefully"

  docker_gen_pid=$(pgrep docker-gen)
  kill ${docker_gen_pid}

  # remove added lines
  update-hosts-file.py clean "${HOSTS_HOST_FILE}" --hostname=$(hosts_hostname) --backup-dir="${BACKUP_DIR}"
  # update-hosts-file --cleanup --hosts-file ${HOSTS_HOST_FILE} --additional-file-dir ${ADDITIONAL_FILE_DIR}

  exit 143 # 128 + 15 -- SIGTERM
}

wait_indefinitely() {
  log_info "Wait forever"
  while true; do
    tail -f /dev/null &
    wait "${!}"
  done
}

is_proxy_up() {
  curl -s -o /dev/null -w "%{http_code}" proxy
}

wait_for_proxy() {
  if [ ! $(is_proxy_up) -eq 302 ]; then
    log_info "Waiting for proxy..."
    sleep 5
  else
    log_info "Proxy is up."
  fi
}

if [ ! -f "$HOSTS_HOST_FILE" ]; then
  log_error "$HOSTS_HOST_FILE does not exist."
  exit 1
fi

mkdir -p ${ADDITIONAL_FILE_DIR}
trap 'kill ${!}; shutdown' SIGTERM
trap 'kill ${!}; shutdown' SIGINT

wait_for_proxy

if [ "$1" = 'development' ]; then
  log_info "Starting development mode"

  export LOGGING_LEVEL="debug"
  do_backup
  exec_docker_gen "${HOSTS_TEMPLATE}" "${HOSTS_OUTPUT}" &
  wait_indefinitely
fi

if [ "$1" = 'production' ]; then
  log_info "Starting production mode"
  exec_docker_gen "${HOSTS_TEMPLATE}" "${HOSTS_OUTPUT}" &
  wait_indefinitely
fi

exec "$@"
