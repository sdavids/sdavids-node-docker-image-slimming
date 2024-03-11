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

readonly http_port="${1:-3000}"

readonly tag='local'

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='sdavids-node-docker-image-slimming'
readonly repository='sdavids-node-docker-image-slimming'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${namespace}"

readonly image_name="${namespace}/${repository}"

readonly container_name='sdavids-node-docker-image-slimming'

readonly host_name='localhost'

readonly network_name="${repository}"

docker network inspect "${network_name}" > /dev/null 2>&1 \
  || docker network create \
       --driver bridge "${network_name}" \
       --label "${label_group}=${namespace}"> /dev/null

# to ensure ${label} is set, we use --label "${label}"
# which might overwrite the label ${label_group} of the image
docker container run \
  --init \
  --rm \
  --interactive \
  --read-only \
  --security-opt='no-new-privileges=true' \
  --cap-drop=all \
  --network="${network_name}" \
  --publish "${http_port}:3000/tcp" \
  --name "${container_name}" \
  --label "${label}" \
  "${image_name}:${tag}"

readonly url="http://${host_name}:${http_port}"

printf '\nListen local: %s\n' "${url}"

if command -v pbcopy > /dev/null 2>&1; then
  printf "%s" "${url}" | pbcopy
  printf '\nThe URL has been copied to the clipboard.\n'
elif command -v xclip > /dev/null 2>&1; then
  printf "%s" "${url}" | xclip -selection clipboard
  printf '\nThe URL has been copied to the clipboard.\n'
elif command -v wl-copy > /dev/null 2>&1; then
  printf "%s" "${url}" | wl-copy
  printf '\nThe URL has been copied to the clipboard.\n'
fi
