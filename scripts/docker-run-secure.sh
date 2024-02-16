#!/usr/bin/env sh

#
# Copyright (c) 2020-2023, Sebastian Davids
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

readonly port="${1:-3000}"

readonly group='sdavids'
readonly name='sdavids-node-docker-image-slimming'

readonly container_name="${group}/${name}"

# https://nodejs.org/docs/latest/api/cli.html#node_tls_reject_unauthorizedvalue
docker run \
  --init \
  --interactive \
  --rm \
  --read-only \
  --security-opt=no-new-privileges \
  --cap-drop=all \
  --env PROTOCOL=https \
  --env NODE_TLS_REJECT_UNAUTHORIZED='0' \
  --publish "${port}:3000/tcp" \
  --mount "type=bind,source=${PWD}/docker/app,target=/run/secrets,readonly" \
  --name "${name}" \
  "${container_name}"
