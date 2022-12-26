# Dockerfile for EOTK

FROM ubuntu:jammy

# MKCERT: determines if mkcert and root CA are included in image. To get consistent root CA,
# generate your rootCA-key.pem and rootCA.pem files with mkcert locally and add them to ./secrets.d
ARG MKCERT=true

# ENV/ENVIRONMENT: suffix used to target different configs and determines secrets behavior
ARG ENV=dev
ENV ENVIRONMENT=$ENV

# PROJECT: the suffix name of your configuration file, typically your site name
ARG PROJECT=example
ENV PROJECT=$PROJECT

# Standard environment varibles, you probably won't need to change
ENV DEBIAN_FRONTEND=non-interactive
ENV TZ=Etc/UTC
ENV EOTK_HOME=/opt/eotk

# renovate: datasource=github-tags depName=torproject/tor versioning=loose extractVersion=^tor-(?<version>.*)$
ENV TOR_VERSION=0.4.7.11
# renovate: datasource=github-tags depName=openresty/openresty versioning=loose
ENV OPENRESTY_VERSION=v1.21.4.1
# renovate: datasource=github-tags depName=openssl/openssl extractVersion=OpenSSL_(?<major>.+)_(?<minor>.+)_(?<patch>.+)(?<build>.+)
ENV OPENSSL_VERSION=1.1.1s
# renovate: datasource=github-releases depName=phuslu/nginx-ssl-fingerprint
ENV NGINX_SSL_FINGERPRINT_VERSION=v0.3.0
# renovate: datasource=github-tags depName=FiloSottile/mkcert
ENV MKCERT_VERSION=v1.4.4

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        apt-transport-https \
        build-essential \
        curl \
        dirmngr \
        dumb-init \
        git \
        gnupg2 \
        libjansson-dev \
        libevent-dev \
        libpcre3-dev \
        libssl-dev \
        libssl3 \
        make \
        nginx-extras \
        perl \
        python-is-python3 \
        python3 \
        python3-dev \
        python3-pip \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${EOTK_HOME} \
    && useradd -u 1000 user --home-dir $EOTK_HOME --no-create-home --system \
    && chown -R user:user $EOTK_HOME \
    && echo 'export PATH="$EOTK_HOME:$PATH"' > $EOTK_HOME/.bashrc

# Copy installation scripts (to save caching layer)
COPY ./opt.d/ $EOTK_HOME/opt.d/
# Build tor and openresty
RUN $EOTK_HOME/opt.d/build-docker.sh
# Copy remaining source material filtered by .dockerignore
COPY ./ ${EOTK_HOME}
# Move dhparams file to shared location
COPY ./dhparams.pem /etc/nginx/dhparams.pem

# do mkcert setup - not used in prod

RUN if [ "$MKCERT" = "true" ] ; then curl -JLO "https://dl.filippo.io/mkcert/${MKCERT_VERSION}?for=linux/amd64" \
    && sha256sum -c ${EOTK_HOME}/tools.d/mkcert-${MKCERT_VERSION}.sha256sum \
    && chmod +x mkcert-${MKCERT_VERSION}-linux-amd64 \
    && mv mkcert-${MKCERT_VERSION}-linux-amd64 /usr/local/bin/mkcert \
    && mkdir -p $EOTK_HOME/.local/share/mkcert \
    && mkdir -p /root/.local/share/mkcert \
    && cp ${EOTK_HOME}/secrets.d/rootCA* /root/.local/share/mkcert/ \
    && cp ${EOTK_HOME}/secrets.d/rootCA* $EOTK_HOME/.local/share/mkcert/ ; fi

# setup non-root user
RUN chown -R user:user $EOTK_HOME
USER user
WORKDIR $EOTK_HOME

# nginx stub status metrics endpoint
EXPOSE 8080
# tor prometheus metrics endpoint
EXPOSE 9053

ENTRYPOINT [ "/usr/bin/dumb-init", "--"]
CMD [ "tools.d/docker-entrypoint.sh" ]
