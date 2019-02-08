# Development dockerfile for EOTK
# EOTK will be downloaded and setup ready-to-run without root privileges

# To build:
# docker build --tag eotk-image .

# To run:
# docker run -it --cap-drop=all --name eotk-container eotk-image

# credit:
# v1 Alex Haydock <alex@alexhaydock.co.uk>
# v2 Alec Muffett <alec.muffett@gmail.com>

FROM ubuntu:16.04

LABEL maintainer "Alec Muffett <alec.muffett@gmail.com>"

ENV TOR_REPO https://deb.torproject.org/torproject.org
ENV TOR_FINGERPRINT A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
ENV TOR_KEYURL $TOR_REPO/$TOR_FINGERPRINT.asc

ENV EOTK_REPO https://github.com/alecmuffett/eotk.git
ENV EOTK_HOME /opt/eotk

# no-one will ever convince me that this syntax is not an awful hack
RUN apt-get update \
    && apt-get install -y apt-transport-https \
    && apt-get install -y gnupg2 curl sudo \
    && curl $TOR_KEYURL | gpg --import \
    && gpg --export $TOR_FINGERPRINT | sudo apt-key add - \
    && echo "deb $TOR_REPO xenial main" >/etc/apt/sources.list.d/tor.list \
    && apt-get update \
    && apt-get install -y deb.torproject.org-keyring \
    && apt-get clean \
    && apt-get install -y \
      git \
      nginx-extras \
      perl \
      python \
      python-dev \
      python-pip \
      socat \
      tor \
    && apt-get clean \
    && pip install onionbalance \
    && git clone $EOTK_REPO $EOTK_HOME \
    && useradd user --home-dir $EOTK_HOME --no-create-home --system \
    && chown -R user:user $EOTK_HOME \
    && echo 'export PATH="$EOTK_HOME:$PATH"' > $EOTK_HOME/.bashrc \
    && chown -R user /var/log/nginx \
    && chown -R user /var/lib/nginx \
    && find /usr/local/bin /usr/local/lib -perm -0400 -print0 | xargs -0 chmod a+r \
    && find /usr/local/bin /usr/local/lib -perm -0100 -print0 | xargs -0 chmod a+x

USER user
WORKDIR $EOTK_HOME
ENTRYPOINT [ "/bin/bash" ]
