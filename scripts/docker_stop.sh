#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly container_name='sdavids-node-docker-image-slimming'

container_id="$(docker container ls --all --quiet --filter="name=^/${container_name}$")"
readonly container_id

if [ -n "${container_id}" ]; then
  docker stop "${container_id}" >/dev/null
fi
