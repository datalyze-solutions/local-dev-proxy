#!/usr/bin/env bash

set -e
set -o pipefail

# import shlibs
source /usr/local/bin/shlibs/index.sh

if [ ! -S /var/run/docker.sock ]; then
  log_error "/var/run/docker.sock does not exist."
  exit 1
fi

# eval $(ssh-agent -s)
# ssh-add
# ssh-add -L

clean-compose-file

if [ "$1" = 'install' ]; then
  make installer-up
  make ps
  log_info "Proxy up and running"
  exit 0
fi

if [ "$1" = 'restart' ]; then
  make ps
  make stop
  make up
  log_info "Proxy restarted"
  exit 0
fi

if [ "$1" = 'uninstall' ]; then
  make ps
  make stop
  make ps
  log_info "Proxy stopped"
  exit 0
fi

if [ "$1" = 'ps' ]; then
  log_info "Proxy status"
  make ps
  exit 0
fi

exec "$@"
