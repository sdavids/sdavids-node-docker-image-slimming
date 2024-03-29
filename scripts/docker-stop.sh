#!/usr/bin/env sh

#
# Copyright (c) 2024, Sebastian Davids
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

readonly container_name='sdavids-node-docker-image-slimming'

container_id="$(docker container ls --all --quiet --filter="name=^/${container_name}$")"

if [ -n "${container_id}" ]; then
  docker stop "${container_id}" > /dev/null
fi

readonly network_name='sdavids-node-docker-image-slimming'

if docker network inspect "${network_name}" > /dev/null 2>&1 ; then
    docker network rm "${network_name}" > /dev/null
fi
