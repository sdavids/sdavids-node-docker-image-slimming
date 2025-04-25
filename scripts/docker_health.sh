#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly container_name='sdavids-node-docker-image-slimming'

container_id="$(docker container ls --all --quiet --filter="name=^/${container_name}$")"

if [ -n "${container_id}" ]; then
  # HEALTHCHECK defined?
  if [ "$(docker container inspect --format='{{.State.Health}}' "${container_name}")" = '<nil>' ]; then
    exit
  fi

  docker container inspect \
    --format='{{.State.Health.Status}} {{.State.Health.FailingStreak}}' \
    "${container_name}"
fi
