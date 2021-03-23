FROM datalyze/shlibs:latest as shlibs
FROM docker:latest

ENV CUSTOM_BIN=/opt/bin
ENV LOGGING_LEVEL="info" \
    LOGGING_MODE="echo" \
    LOGGING_STATS=1 \
    PATH=$PATH:${CUSTOM_BIN} \
    INSTALLER_DIR="/proxy"

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        curl \
        bash \
        git \
        su-exec \
        make \
        docker-compose

# ADD https://api.github.com/repos/datalyze-solutions/shlibs/git/refs/heads/master /usr/local/bin/shlibs-version.json
# RUN apk --update add --virtual build-dependencies --no-cache git && \
#     git clone --depth=1 --branch=master https://github.com/datalyze-solutions/shlibs /usr/local/bin/shlibs && \
#     apk del build-dependencies
COPY --from=shlibs /usr/local/bin/shlibs /usr/local/bin/shlibs

WORKDIR ${INSTALLER_DIR}
ADD . ${INSTALLER_DIR}

ADD ./docker/installer/bin ${CUSTOM_BIN}

ENTRYPOINT [ "entrypoint.sh" ]
STOPSIGNAL SIGTERM

CMD [ "install" ]