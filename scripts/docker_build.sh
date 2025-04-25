#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

while getopts ':d:np:t:' opt; do
  case "${opt}" in
    d)
      dockerfile="${OPTARG}"
      ;;
    n)
      no_cache='--pull --no-cache'
      ;;
    p)
      platform="${OPTARG}"
      ;;
    t)
      tag="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d Dockerfile] [-n] [-p platform] [-t tag]" >&2
      exit 1
      ;;
  esac
done

readonly dockerfile="${dockerfile:-$PWD/Dockerfile}"

readonly no_cache="${no_cache:-}"

# https://docs.docker.com/reference/cli/docker/buildx/build/#platform
readonly platform="${platform:-}"

readonly tag="${tag:-local}"

if [ ! -f "${dockerfile}" ]; then
  echo "Dockerfile '${dockerfile}' does not exist" >&2
  exit 2
fi

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='de.sdavids'
readonly repository='sdavids-node-docker-image-slimming'

readonly label_group='de.sdavids.docker.group'

readonly image_name="${namespace}/${repository}"

# https://reproducible-builds.org/docs/source-date-epoch/
if [ -z "${SOURCE_DATE_EPOCH+x}" ]; then
  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    SOURCE_DATE_EPOCH="$(git log --max-count=1 --pretty=format:%ct)"
  else
    SOURCE_DATE_EPOCH="$(date +%s)"
  fi
  export SOURCE_DATE_EPOCH
fi

if [ "$(uname)" = 'Darwin' ]; then
  created_at="$(date -r "${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
else
  created_at="$(date -d "@${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
fi
readonly created_at

if [ -n "${GITHUB_SHA+x}" ]; then
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

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
# shellcheck disable=SC2086
if [ -n "${platform}" ]; then
  docker image build \
    ${no_cache} \
    --file "${dockerfile}" \
    --platform="${platform}" \
    --tag "${image_name}:latest" \
    --tag "${image_name}:${tag}" \
    --label "${label_group}=${repository}" \
    --label "org.opencontainers.image.revision=${commit}" \
    --label "org.opencontainers.image.created=${created_at}" \
    .
else
  docker image build \
    ${no_cache} \
    --file "${dockerfile}" \
    --tag "${image_name}:latest" \
    --tag "${image_name}:${tag}" \
    --label "${label_group}=${repository}" \
    --label "org.opencontainers.image.revision=${commit}" \
    --label "org.opencontainers.image.created=${created_at}" \
    .
fi

echo

docker image inspect -f '{{json .Config.Labels}}' "${image_name}:${tag}"
