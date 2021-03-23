FROM datalyze/shlibs:latest as shlibs
FROM alpine:latest

ENV CUSTOM_BIN=/opt/bin
ENV PATH=$PATH:${CUSTOM_BIN} \
    LOGGING_LEVEL="info" \
    LOGGING_MODE="echo" \
    LOGGING_STATS=1 \
    CERT_DIR="/certs"

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        curl \
        bash \
        su-exec \
        openssl

# ADD https://api.github.com/repos/datalyze-solutions/shlibs/git/refs/heads/master /usr/local/bin/shlibs-version.json
# RUN apk --update add --virtual build-dependencies --no-cache git && \
#     git clone --depth=1 --branch=master https://github.com/datalyze-solutions/shlibs /usr/local/bin/shlibs && \
#     apk del build-dependencies
COPY --from=shlibs /usr/local/bin/shlibs /usr/local/bin/shlibs

VOLUME ${CERT_DIR}
WORKDIR ${CERT_DIR}

ADD ./bin ${CUSTOM_BIN}

# ENTRYPOINT [ "entrypoint.sh" ]
# STOPSIGNAL SIGTERM

# CMD [ "production" ]
