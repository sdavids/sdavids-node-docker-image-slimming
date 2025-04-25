#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly key_path="${base_dir}/key.pem"
readonly cert_path="${base_dir}/cert.pem"

if [ ! -f "${key_path}" ]; then
  echo "key '${key_path}' does not exist" >&2
  exit 11
fi

if [ ! -f "${cert_path}" ]; then
  echo "cert '${cert_path}' does not exist" >&2
  exit 12
fi

# https://stackoverflow.com/a/3915420
# https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
command -v realpath >/dev/null 2>&1 || realpath() {
  if [ -h "$1" ]; then
    # shellcheck disable=SC2012
    ls -ld "$1" | awk '{print $11}'
  else
    echo "$(
      cd "$(dirname -- "$1")" >/dev/null
      pwd -P
    )/$(basename -- "$1")"
  fi
}

script_path="$(realpath "$0")"
readonly script_path

script_base_dir="$(dirname -- "${script_path}")"
readonly script_base_dir

readonly create_script_path="${script_base_dir}/create_self_signed_cert.sh"
readonly delete_script_path="${script_base_dir}/delete_self_signed_cert.sh"

if [ ! -f "${create_script_path}" ]; then
  echo "create script '${create_script_path}' does not exist" >&2
  exit 13
fi

if [ ! -f "${delete_script_path}" ]; then
  echo "delete script '${delete_script_path}' does not exist" >&2
  exit 14
fi

if [ -n "${1+x}" ]; then
  if [ -n "${2+x}" ]; then
    if [ -n "${3+x}" ]; then
      $delete_script_path "$1" "$3"
      $create_script_path "$1" "$2" "$3"
    else
      $delete_script_path "$1"
      $create_script_path "$1" "$2"
    fi
  else
    $delete_script_path "$1"
    $create_script_path "$1"
  fi
else
  $delete_script_path
  $create_script_path
fi
