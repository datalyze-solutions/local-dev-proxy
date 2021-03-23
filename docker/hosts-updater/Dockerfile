FROM datalyze/shlibs:latest as shlibs
FROM alpine:latest

ENV CUSTOM_BIN=/opt/bin
ENV LOGGING_LEVEL="info" \
    LOGGING_MODE="echo" \
    LOGGING_STATS=1 \
    PATH=$PATH:${CUSTOM_BIN}

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        curl \
        bash \
        inotify-tools \
        su-exec

# ADD https://api.github.com/repos/datalyze-solutions/shlibs/git/refs/heads/master /usr/local/bin/shlibs-version.json
# RUN apk --update add --virtual build-dependencies --no-cache git && \
#     git clone --depth=1 --branch=master https://github.com/datalyze-solutions/shlibs /usr/local/bin/shlibs && \
#     apk del build-dependencies
COPY --from=shlibs /usr/local/bin/shlibs /usr/local/bin/shlibs

ENV DOCKER_GEN_VERSION 0.7.4
RUN wget --quiet https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

ENV TEMPLATES=/templates
RUN mkdir -p ${TEMPLATES}
ADD ./templates ${TEMPLATES}
ADD ./bin ${CUSTOM_BIN}

ENTRYPOINT [ "entrypoint.sh" ]
STOPSIGNAL SIGTERM

CMD [ "production" ]
