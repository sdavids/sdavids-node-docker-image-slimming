# syntax=docker/dockerfile:1
# check=error=true

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

# https://hub.docker.com/_/debian
FROM debian:13.2-slim

SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get --yes upgrade --no-install-recommends \
  && apt-get --yes install --no-install-recommends \
    libstdc++6 \
    locales \
    sudo \
    openssh-client \
    curl \
    git \
    jq \
    reuse \
    shfmt \
    shellcheck \
    yamllint \
    neovim \
# clean up
  && apt-get --yes autoremove \
  && apt-get --yes clean \
  && rm -rf /var/lib/apt/lists/* \
# ensure en_US.UTF-8 locale is available
  && echo 'en_US.UTF-8 UTF-8' >>/etc/locale.gen \
  && locale-gen \
# create node user/group as sudoer
  && groupadd --gid 1000 node \
  && useradd -u 1000 -g node -s /bin/bash -m node \
  && echo node ALL=\(root\) NOPASSWD:ALL >/etc/sudoers.d/node \
  && chmod 0440 /etc/sudoers.d/node

ENV SHELL /bin/bash
