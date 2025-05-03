#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':c:d:v:' opt; do
  case "${opt}" in
    c)
      common_name="${OPTARG}"
      ;;
    d)
      base_dir="${OPTARG}"
      ;;
    v)
      days="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-c <common_name>] [-d <dir>] [-v <days; 1..24855>]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD}"

if [ -n "${common_name+x}" ]; then
  common_name=" -c ${common_name}"
else
  common_name=''
fi
readonly common_name

if [ -n "${days+x}" ]; then
  days=" -v ${days}"
else
  days=''
fi
readonly days

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

$delete_script_path -d "${base_dir}${common_name}"
$create_script_path -d "${base_dir}${common_name}${days}"
