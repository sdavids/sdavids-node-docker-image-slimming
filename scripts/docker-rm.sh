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

readonly name='sdavids-node-docker-image-slimming'

if [ -n "$(docker container ls --all --quiet --filter="name=^/${name}$")" ]; then
  docker container stop "${name}"
fi

# container not started with --rm ?
if [ -n "$(docker container ls --all --quiet --filter="name=^/${name}$")" ]; then
  docker container remove --force --volumes "${name}"
fi
