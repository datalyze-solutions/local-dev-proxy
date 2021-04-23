# need to declare PHONY targets
# if a file named e.g. config exists, the target can't be called otherwise
.PHONY: build network network-swarm install uninstall down push push-installer build-installer ps stop logs check-hosts test-page test-page-stop
SHELL := /bin/bash

compose_file_proxy := docker-compose.yml
compose_file_installer := installer.yml

# command macros
compose_build = docker-compose -p proxy -f build.yml
compose_proxy = docker-compose -p proxy -f $(compose_file_proxy)
compose_installer = docker-compose -p proxy-installer -f $(compose_file_installer)

compose_exec = docker exec -it
container_id = $(shell docker container ls -q -f name="proxy_$(services)")

%-hybrid: compose_file_proxy = docker-compose.swarm-hybrid.yml

%-mkcert: services=mkcert
%-proxy: services=proxy
%-hosts-updater: services=hosts-updater
%-installer: services=installer

login:
	docker login

network:
	docker network create  proxy --attachable --opt encrypted || true

network-swarm:
	docker network create --driver overlay proxy-swarm --attachable --opt encrypted || true

build:
	# make service=proxy build will only run build command for the proxy service
	# if services is unset, all services will be build
	$(compose_build) build $(services)
build-%:
	$(compose_build) build $(services)
build-mkcert:
build-proxy:
build-hosts-updater:
build-installer:

push:
	$(compose_build) push $(services)
push-%:
	$(compose_build) push $(services)
push-mkcert:
push-proxy:
push-hosts-updater:
push-installer:

pull:
	$(compose_proxy) pull --ignore-pull-failures --parallel $(services)

up: network
	$(compose_proxy) up -d --remove-orphans $(services)
up-hybrid: network-swarm up
up-%: network
	$(compose_proxy) up -d --remove-orphans $(services)
up-mkcert:
up-proxy:
up-hosts-updater:

restart: stop up

log-%:
	$(compose_proxy) logs $(services)
log-mkcert:
log-proxy:
log-hosts-updater:

logs-%:
	$(compose_proxy) logs -f $(services)
logs-mkcert:
logs-proxy:
logs-hosts-updater:

ps:
	$(compose_proxy) ps $(services)

stop:
	$(compose_proxy) stop $(services)
	@$(compose_proxy) rm -sf $(services)
stop-hybrid: stop
stop-%:
	$(compose_proxy) stop $(services)
	@$(compose_proxy) rm -sf $(services)
stop-mkcert:
stop-proxy:
stop-hosts-updater:

down:
	@read -p "All volumes will be removed, press 'Y' to continue: " confirmed; \
	test "$$confirmed" == "Y" && \
	$(compose_proxy) down --volumes --remove-orphans
down-hybrid: down

exec-%: cmd=bash
exec-%:
	$(compose_exec) $(container_id) $(cmd)
exec-hosts-updater:

install: pull
	$(compose_installer) up --force-recreate install
	$(compose_installer) logs -f
	@$(compose_installer) rm -sf

installer-up: network
	$(compose_proxy) up -d --remove-orphans $(services)

installer-restart:
	$(compose_installer) up --force-recreate restart

uninstall:
	$(compose_installer) up --force-recreate uninstall
	$(compose_installer) logs -f
	@$(compose_installer) rm -sf

check-hosts:
	tail -F -n 50 /etc/hosts

test-page:
	docker-compose -f test.yml up -d

test-page-stop:
	docker-compose -f test.yml stop

test-page-swarm:
	docker stack deploy -c test.swarm.yml test

test-page-swarm-stop:
	docker stack rm test

push-gitlab-netpipe:
	./bin/push-gitlab-netpipe.sh
