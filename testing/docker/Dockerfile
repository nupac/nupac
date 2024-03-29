FROM ubuntu:20.04
ENV NUSHELL_INSTALL_VERSION=0.73.0
ENV NUSHELL_INSTALL_DIR=/usr/local/bin
ENV ANSIBLE_USER=ansible
ENV SUDO_GROUP=sudo

RUN set -eu \
  && apt-get update \
  && apt-get install -y python3 sudo bash ca-certificates nano iproute2 wget --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && adduser --system --disabled-password ${ANSIBLE_USER} \
  && adduser ${ANSIBLE_USER} ${SUDO_GROUP} \
  && mkdir -p /home/${ANSIBLE_USER}/.config/nushell/ \
  && wget -q https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/default_config.nu -O /home/${ANSIBLE_USER}/.config/nushell/config.nu \
  && wget -q https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/default_env.nu -O /home/${ANSIBLE_USER}/.config/nushell/env.nu \
  && wget -q https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/sample_login.nu -O /home/${ANSIBLE_USER}/.config/nushell/login.nu \
  && cd /tmp \
  && wget https://github.com/nushell/nushell/releases/download/${NUSHELL_INSTALL_VERSION}/nu-${NUSHELL_INSTALL_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
  && tar -xzf nu* \
  && chmod +x nu*/nu \
  && mv nu*/nu ${NUSHELL_INSTALL_DIR}/nu \
  && chown -R ${ANSIBLE_USER}:${SUDO_GROUP} /home/${ANSIBLE_USER}/.config/nushell \
  && rm -rf /tmp/*
USER ${ANSIBLE_USER}
WORKDIR /home/${ANSIBLE_USER}
CMD ["sleep", "infinity"]
