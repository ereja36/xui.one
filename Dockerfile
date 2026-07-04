FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

WORKDIR /opt/xui

# System dependencies + libssl1.1 (required by bundled PHP on Ubuntu 24.04)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dos2unix \
    iproute2 \
    net-tools \
    nginx \
    python-is-python3 \
    python3 \
    python3-dev \
    sudo \
    unzip \
    wget \
    && wget -q https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb \
    && dpkg -i libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb || apt-get install -f -y \
    && rm -f libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/configure.sh /configure.sh
COPY docker/configure-paths.sh /configure-paths.sh
COPY docker/persist-data.sh /persist-data.sh
COPY docker/install-docker.sh /install-docker.sh
COPY docker/nginx-unified.conf /opt/xui/nginx-unified.conf

RUN dos2unix /entrypoint.sh /configure.sh /configure-paths.sh /persist-data.sh /install-docker.sh \
    && chmod +x /entrypoint.sh /configure.sh /configure-paths.sh /persist-data.sh /install-docker.sh

VOLUME ["/home/xui", "/var/lib/mysql"]

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
