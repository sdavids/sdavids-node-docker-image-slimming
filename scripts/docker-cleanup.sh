#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly repository='sdavids-node-docker-image-slimming'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${repository}"

docker container prune --force --filter="label=${label}"

docker volume prune --force --filter="label=${label}"

docker image prune --force --filter="label=${label}" --all

docker network prune --force --filter="label=${label}"
