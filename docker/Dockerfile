# ARG necessaire pour la version des app FROM
ARG ALPINE_BASE_IMAGE_VERSION="3.23"
ARG PYTHON_BASE_IMAGE_VERSION="3.15.1-alpine3.24@sha256:54448f67d7c31c39e5cdd3ea2d6382395ce142806c284425f8e897d78a0465b3"

##################################
## RUNNER
##################################
FROM alpine:${ALPINE_BASE_IMAGE_VERSION}

ARG CONTAINER_BUILD_VERSION
ENV CONTAINER_BUILD_VERSION=${CONTAINER_BUILD_VERSION}
ARG DOCKER_GEN_VERSION="0.17.0"
ENV DOCKER_HOST=unix:///var/run/docker.sock

RUN apk update && \
    apk --no-cache add \
    dnsmasq=2.92_p2-r0 \
    bind-tools=9.20.29-r0 \
    tini=0.19.0-r2 && \
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




##################################
## RUNNER
##################################
FROM python:${PYTHON_BASE_IMAGE_VERSION} AS runner
