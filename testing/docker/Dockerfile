FROM ubuntu:20.04
ENV NUSHELL_INSTALL_VERSION=0.66.2
ENV NUSHELL_INSTALL_DIR /usr/bin
ENV ANSIBLE_USER=ansible SUDO_GROUP=sudo

RUN set -eu \
  && apt-get update \
  && apt-get install -y python3 sudo bash ca-certificates nano iproute2 wget --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && adduser --system --disabled-password ${ANSIBLE_USER} \
  && adduser ${ANSIBLE_USER} ${SUDO_GROUP} \
  && mkdir -p /home/${ANSIBLE_USER}/.config/nushell/ \
  && wget -q https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/default_config.nu -O /home/${ANSIBLE_USER}/.config/nushell/config.nu \
  && wget -q https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/default_env.nu -O /home/${ANSIBLE_USER}/.config/nushell/env.nu \
  && cd /tmp \
  && wget -qO - https://api.github.com/repos/nushell/nushell/releases/tags/${NUSHELL_INSTALL_VERSION} \
  |grep browser_download_url \
  |grep x86_64 \
  |grep gnu \
  |cut -f4 -d '"' \
  |xargs -I{} wget {} \
  && tar -xzf nu* \
  && chmod +x nu \
  && mv nu ${NUSHELL_INSTALL_DIR}/nu \
  && chown -R ${ANSIBLE_USER}:${SUDO_GROUP} /home/${ANSIBLE_USER}/.config/nushell \
  && rm -rf /tmp/*
USER ${ANSIBLE_USER}
WORKDIR /home/${ANSIBLE_USER}
ENTRYPOINT ["nu"]