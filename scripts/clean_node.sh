#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':kr' opt; do
  case "${opt}" in
    k)
      keep_lock='true'
      ;;
    r)
      recurse='true'
      ;;
    ?)
      echo "Usage: $0 [-k] [-r] <dir>" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

readonly base_dir="${1:-$PWD}"
readonly recurse="${recurse:-false}"
readonly keep_lock="${keep_lock:-false}"

if [ ! -d "${base_dir}" ]; then
  printf "The directory '%s' does not exist.\n" "${base_dir}" >&2
  exit 2
fi

if [ "${recurse}" = 'true' ]; then
  find "${base_dir}" -type d -name node_modules -exec rm -rf {} +
  if [ "${keep_lock}" = 'false' ]; then
    find "${base_dir}" -type f -name package-lock.json -exec rm -f {} +
  fi
else
  rm -rf "${base_dir}/node_modules"
  if [ "${keep_lock}" = 'false' ]; then
    rm -f "${base_dir}/package-lock.json"
  fi
fi
