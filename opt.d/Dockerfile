#
# This Dockerfile is for testing EOTK. When building this container,
# EOTK will be downloaded and setup ready-to-run without root privileges.
#
# To build, run:
#     docker build -t eotk .
#
# To run the newly-built container:
#     docker run -it --cap-drop=all --name eotk eotk
#
# This will drop you into a bash prompt with EOTK ready to run.
#
# To test EOTK, try running:
#     ./010-setup-demo-config.sh
# at the prompt, and follow the instructions.
#

FROM ubuntu:16.04
LABEL maintainer "Alex Haydock <alex@alexhaydock.co.uk>"

ENV TORFINGERPRINT A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89

# Prepare apt
RUN apt-get update && \
    apt-get install -y \
      apt-transport-https \
      gnupg2 \
      gnupg-curl && \
    echo "deb https://deb.torproject.org/torproject.org xenial main" > /etc/apt/sources.list.d/tor.list && \
    apt-key adv --keyserver hkps://keyserver.ubuntu.com --recv-keys "$TORFINGERPRINT" && \
    apt-get clean

# Install prereqs
RUN apt-get update && \
    apt-get install -y \
      curl \
      deb.torproject.org-keyring \
      git \
      gnupg2 \
      nano \
      nginx nginx-extras \
      perl \
      python python-dev python-pip \
      socat \
      tor && \
    apt-get clean

RUN pip install --upgrade pip && \
    pip install onionbalance

RUN git clone https://github.com/alecmuffett/eotk.git /opt/eotk

# Add unprivileged user to run as
RUN useradd user --home-dir /opt/eotk --no-create-home --system
RUN chown -R user:user /opt/eotk
RUN echo 'export PATH="/opt/eotk:$PATH"' > /opt/eotk/.bashrc

# Fix some permissions
RUN chown -R user /var/log/nginx && \
    chown -R user /var/lib/nginx && \
    find /usr/local/bin /usr/local/lib -perm -0400 -print0 | xargs -0 chmod a+r && \
    find /usr/local/bin /usr/local/lib -perm -0100 -print0 | xargs -0 chmod a+x

USER user
WORKDIR /opt/eotk
ENTRYPOINT [ "/bin/bash" ]
