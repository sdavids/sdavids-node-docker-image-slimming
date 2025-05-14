#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly container_name='sdavids-node-docker-image-slimming'

if [ -n "$(docker container ls --all --quiet --filter="name=^/${container_name}$")" ]; then
  docker container stop "${container_name}" >/dev/null
fi

# container not started with --rm ?
if [ -n "$(docker container ls --all --quiet --filter="name=^/${container_name}$")" ]; then
  docker container remove --force --volumes "${container_name}" >/dev/null
fi

readonly network_name="sdavids_node_docker_image_slimming"

if docker network inspect "${network_name}" >/dev/null 2>&1; then
  docker network rm "${network_name}" >/dev/null
fi
