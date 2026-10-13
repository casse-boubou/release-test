# ARG necessaire pour la version des app FROM
ARG ALPINE_BASE_IMAGE_VERSION="3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6"

##################################
## RUNNER
##################################
FROM alpine:${ALPINE_BASE_IMAGE_VERSION}

ARG CONTAINER_BUILD_VERSION
ENV CONTAINER_BUILD_VERSION=${CONTAINER_BUILD_VERSION}
ARG DOCKER_GEN_VERSION="0.17.2"
ENV DOCKER_HOST=unix:///var/run/docker.sock

RUN apk update && \
    apk --no-cache add \
    dnsmasq=2.92_p2-r0 \
    bind-tools=9.20.26-r0 \
    tini=0.19.0-r3 && \
    rm -rf /var/cache/apk/*

# Set shell pipefail before RUN with a pipe in
# See https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN set -o pipefail && wget -qO- https://github.com/nginx-proxy/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin

COPY buildFiles /app
RUN cp /app/dnsmasq/dnsmasq.conf /etc/dnsmasq.conf && \
    cp /app/dnsmasq/rDNS_PTR_defaultBridge.conf /etc/dnsmasq.d/rDNS_PTR_defaultBridge.conf

# Copy entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
# Copy healthcheck
COPY healthcheck /app/healthcheck
# Make it executable
RUN chmod +x /docker-entrypoint.sh /app/healthcheck /app/main.sh


##################################
## PRODUCTION MODE
##################################
WORKDIR /app
HEALTHCHECK --interval=30s --timeout=15s --retries=5 \
    CMD ["sh","healthcheck"]

ENTRYPOINT ["/sbin/tini", "--", "sh", "/docker-entrypoint.sh"]
