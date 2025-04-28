#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

# https://docs.antora.org/antora/latest/whats-new/
readonly antora_version='3.1.10'

# https://stackoverflow.com/a/3915420
# https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
command -v realpath >/dev/null 2>&1 || realpath() {
  if [ -h "$1" ]; then
    # shellcheck disable=SC2012
    ls -ld "$1" | awk '{ print $11 }'
  else
    echo "$(
      cd "$(dirname -- "$1")" >/dev/null
      pwd -P
    )/$(basename -- "$1")"
  fi
}

while getopts ':fo:p:s:' opt; do
  case "${opt}" in
    f)
      force='true'
      ;;
    o)
      build_dir="${OPTARG}"
      ;;
    p)
      playbook_path="${OPTARG}"
      ;;
    s)
      src_dir="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-s <sourceDirectory>] [-o <outputDirectory>] [-p <pathToAntoraPlaybook>] [-f]" >&2
      exit 1
      ;;
  esac
done

src_dir="${src_dir:-$PWD}"

if [ ! -d "${src_dir}" ]; then
  printf "The source directory '%s' does not exist\n" "${src_dir}" >&2
  exit 1
fi

src_dir="$(realpath "${src_dir}")"
readonly src_dir

readonly force="${force:-false}"

playbook_path="${playbook_path:-docs/antora-playbook.yml}"
readonly playbook_path

build_dir="${build_dir:-$PWD/build}"

if [ "${force}" = 'true' ] \
  && [ -d "${build_dir}" ] \
  && [ "${build_dir}" != "$PWD" ]; then

  rm -rf "${build_dir}"
fi

mkdir -p "${build_dir}"

build_dir="$(realpath "${build_dir}")"
readonly build_dir

cache_dir="${HOME}/.cache/antora"
if [ "$(uname)" = 'Darwin' ]; then
  cache_dir="${HOME}/Library/Application Support/antora/cache"
fi
if [ -n "${XDG_CACHE_HOME+x}" ]; then
  cache_dir="${XDG_CACHE_HOME}/antora"
fi
readonly cache_dir

mkdir -p "${cache_dir}"

docker container run \
  --user "$(id -u):$(id -g)" \
  --rm \
  --read-only \
  --security-opt='no-new-privileges=true' \
  --cap-drop=all \
  --mount "type=bind,src=${src_dir},dst=/antora,ro" \
  --mount "type=bind,src=${build_dir},dst=/antora_build" \
  --mount "type=bind,src=${cache_dir},dst=/antora_cache" \
  "antora/antora:${antora_version}" \
  --cache-dir=/antora_cache \
  --to-dir=/antora_build \
  "${playbook_path}"
