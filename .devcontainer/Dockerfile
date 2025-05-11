# syntax=docker/dockerfile:1
# check=error=true

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

# https://hub.docker.com/_/debian
FROM debian:12.10-slim

# hadolint ignore=DL3008
RUN apt-get update \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends ca-certificates \
  && mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d \
  && echo 'deb https://deb.debian.org/debian trixie main' >/etc/apt/sources.list.d/trixie.list \
  && printf 'Package: *\nPin: release n=trixie\nPin-Priority: -10\n\nPackage: reuse\nPin: release n=trixie\nPin-Priority: 501\n' > /etc/apt/preferences.d/trixie.pref \
  && apt-get update \
  && apt-get -y upgrade --no-install-recommends \
  && apt-get -y install --no-install-recommends \
    libstdc++6 \
    locales \
    sudo \
    openssh-client \
    curl \
    git \
    shfmt \
    shellcheck \
    yamllint \
    neovim \
  && apt-get -y install --no-install-recommends -f reuse \
# clean up
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* \
# ensure en_US.UTF-8 locale is available
  && echo 'en_US.UTF-8 UTF-8' >>/etc/locale.gen \
  && locale-gen \
# create node user/group as sudoer \
  && groupadd --gid 1000 node \
  && useradd -u 1000 -g node -s /bin/bash -m node \
  && echo node ALL=\(root\) NOPASSWD:ALL >/etc/sudoers.d/node \
  && chmod 0440 /etc/sudoers.d/node
