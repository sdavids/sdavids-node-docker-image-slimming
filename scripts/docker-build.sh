#!/usr/bin/env sh

#
# Copyright (c) 2020, Sebastian Davids
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

# script needs to be invoked from project root directory

set -eu

readonly tag="${1:-local}"

readonly port=3000

readonly group="sdavids"
readonly name="sdavids-node-docker-image-slimming"

readonly container_name="${group}/${name}"

readonly commit="$(git rev-parse --verify --short HEAD)"

docker build \
  --compress \
  --tag "${container_name}:latest" \
  --tag "${container_name}:${tag}" \
  --build-arg "git_commit=${commit}" \
  --build-arg "port=${port}" \
  .
