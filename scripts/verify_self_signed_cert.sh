#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# openssl needs to be in $PATH
#   Linux:
#     sudo apt-get install openssl

set -Eeu -o pipefail -o posix

readonly base_dir="${1:-$PWD}"

readonly cert_path="${base_dir}/cert.pem"
readonly key_path="${base_dir}/key.pem"

if [ "$(uname)" = 'Darwin' ]; then
  if [ "$(stat -f '%A' "${cert_path}")" != '600' ]; then
    printf '\nWARNING: cert.pem does not have the correct permissions. You can change them via:\n\n\tchmod 600 %s\n' "${cert_path}"
    exit 1
  fi

  if [ "$(stat -f '%A' "${key_path}")" != '600' ]; then
    printf '\nWARNING: key.pem does not have the correct permissions. You can change them via:\n\n\tchmod 600 %s\n' "${key_path}"
    exit 2
  fi
else
  if [ "$(stat -c '%a' "${cert_path}")" != '600' ]; then
    printf '\nWARNING: cert.pem does not have the correct permissions. You can change them via:\n\n\tchmod 600 %s\n' "${cert_path}"
    exit 3
  fi

  if [ "$(stat -c '%a' "${key_path}")" != '600' ]; then
    printf '\nWARNING: key.pem does not have the correct permissions. You can change them via:\n\n\tchmod 600 %s\n' "${key_path}"
    exit 4
  fi
fi

host_name="$(openssl x509 -ext subjectAltName -noout -in cert.pem | grep 'DNS:' | sed 's/DNS:\(.*\)/\1/' | awk '{$1=$1};1')"
readonly host_name

if [ "$(uname)" = 'Darwin' ]; then
  # https://ss64.com/mac/security-cert-verify.html
  security verify-cert -q -n -L -r "${cert_path}"

  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${host_name}"
fi

printf '\n%s\n' "${cert_path}"

openssl x509 -text -noout -in "${cert_path}"

if [ "${host_name}" = 'localhost' ]; then
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c '127\.0\.0\.1\s+localhost' /etc/hosts)" -eq 0 ]; then
    echo "WARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost'" >&2
  fi
else
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c "127\.0\.0\.1\s+localhost.+${host_name//\./\.}" /etc/hosts)" -eq 0 ]; then
    echo "WARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost ${host_name}'" >&2
  fi
fi
