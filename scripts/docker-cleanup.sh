#!/usr/bin/env sh

#
# Copyright (c) 2020-2024, Sebastian Davids
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eu

readonly group='sdavids-node-docker-image-slimming'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${group}"

docker container prune --force --filter="label=${label}"

docker volume prune --force --filter="label=${label}"

docker image prune --force --filter="label=${label}" --all

docker network prune --force --filter="label=${label}"
