#!/usr/bin/env sh

#
# Copyright (c) 2022-2024, Sebastian Davids
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

# script needs to be invoked from the project's root directory

set -eu

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo "'${PWD}' is not a git repository" >&2
  exit 1
fi

git clean -fdx \
  -e .fleet \
  -e .idea \
  -e .settings \
  -e .vscode \
  -e docker/app/cert.pem \
  -e docker/app/key.pem \
  .

origin_url="$(git remote get-url origin 2> /dev/null || echo '')"
if [ -n "${origin_url}" ]; then
  set +e
  git ls-remote --exit-code --heads origin refs/heads/main > /dev/null 2> /dev/null
  remote_exits=$?
  set -e

  if [ ${remote_exits} -eq 0 ]; then
    git remote prune origin
  else
    git remote remove origin
  fi
fi

git repack -d
git prune-packed
git reflog expire --expire=1.month.ago --expire-unreachable=now
git gc --aggressive
