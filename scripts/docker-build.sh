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

readonly tag="${1:-local}"

readonly dockerfile="${2:-$PWD/Dockerfile}"

readonly port=3000

if [ ! -f "${dockerfile}" ]; then
  echo "Dockerfile '${dockerfile}' does not exist" >&2
  exit 1
fi

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='sdavids-node-docker-image-slimming'
readonly repository='sdavids-node-docker-image-slimming'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${namespace}"

readonly image_name="${namespace}/${repository}"

if [ -n "${GITHUB_SHA:-}" ]; then
  # https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables
  commit="${GITHUB_SHA}"
elif [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
  commit='N/A'
else
  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    ext=''
  else
    ext='-next'
  fi
  commit="$(git rev-parse --verify HEAD)${ext}"
  unset ext
fi
readonly commit

# to ensure ${label} is set, we use --label "${label}"
# which might overwrite the LABEL ${label_group} of the Dockerfile
docker image build \
  --file "${dockerfile}" \
  --compress \
  --tag "${image_name}:latest" \
  --tag "${image_name}:${tag}" \
  --build-arg "git_commit=${commit}" \
  --build-arg "port=${port}" \
  --label "${label}" \
  .

echo

docker image inspect -f '{{json .Config.Labels}}' "${image_name}:${tag}"
