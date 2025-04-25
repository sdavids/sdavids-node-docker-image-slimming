#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly host_name="${2:-localhost}"

readonly key_path="${base_dir}/key.pem"
readonly cert_path="${base_dir}/cert.pem"

if [ "$(uname)" = 'Darwin' ]; then
  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${host_name}" 1>/dev/null 2>/dev/null
  found=$?
  set -e

  if [ "${found}" = 0 ]; then
    login_keychain="$(security login-keychain | xargs)"
    readonly login_keychain

    echo "Removing '${host_name}' certificate from keychain ${login_keychain} ..."

    # https://ss64.com/mac/security-delete-cert.html
    security delete-certificate -c "${host_name}" -t "${login_keychain}"
  fi
fi

if [ -f "${key_path}" ]; then
  rm -f "${key_path}"
fi

if [ -f "${cert_path}" ]; then
  rm -f "${cert_path}"
fi

# delete empty certs dir if not $PWD
if [ -d "${base_dir}" ] \
  && [ "${base_dir}" != "$PWD" ] \
  && [ "${base_dir}" != '.' ] \
  && [ -z "$(ls -A "${base_dir}")" ]; then

  rmdir "${base_dir}"
fi
