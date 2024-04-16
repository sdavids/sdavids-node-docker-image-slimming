#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2022 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# script needs to be invoked from the project's root directory

set -eu

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
  echo "'$PWD' is not a git repository" >&2
  exit 1
fi

git clean -fdx \
  -e .fleet \
  -e .idea \
  -e .vscode \
  -e docker/certs/cert.pem \
  -e docker/certs/key.pem \
  .

origin_url="$(git remote get-url origin 2> /dev/null || echo '')"
if [ -n "${origin_url}" ]; then
  set +e
  git ls-remote --exit-code --heads origin refs/heads/main > /dev/null 2> /dev/null
  remote_exits=$?
  set -e

  if [ ${remote_exits} -eq 0 ]; then
    git remote prune origin 1> /dev/null
  else
    git remote remove origin 1> /dev/null
  fi
fi

git repack -d --quiet
git prune-packed --quiet
git reflog expire --expire=1.month.ago --expire-unreachable=now 1> /dev/null
git gc --aggressive
