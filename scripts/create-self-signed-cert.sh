#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

readonly out_dir="${1:-$PWD}"

if [ -n "${2+x}" ]; then # $2 defined
  case $2 in
    ''|*[!0-9]*) # $2 is not a positive integer or 0
      echo "'$2' is not a positive integer" >&2
      exit 1
    ;;
    *) # $2 is a positive integer or 0
      days="$2"
      if [ "${days}" -lt 1 ]; then
        echo "'$2' is not a positive integer" >&2
        exit 2
      fi
      if [ "${days}" -gt 24855 ]; then
        echo "'$2' is too big; range: [1, 24855]" >&2
        exit 3
      fi
    ;;
  esac
else # $2 undefined
  days=30
fi
readonly days

readonly host_name="${3:-localhost}"

readonly script_path="$PWD/$0"

readonly key_path="${out_dir}/key.pem"
readonly cert_path="${out_dir}/cert.pem"

if [ "$(uname)" = 'Darwin' ]; then
  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${host_name}" 1> /dev/null 2> /dev/null
  found=$?
  set -e

  login_keychain="$(security login-keychain | xargs)"
  readonly login_keychain

  if [ "${found}" = 0 ]; then
    printf "Keychain %s already has a certificate for '%s'. You can delete the existing certificate via:\n\n\tsecurity delete-certificate -c %s -t %s\n" "${login_keychain}" "${host_name}" "${host_name}" "${login_keychain}" >&2
    exit 4
  fi
fi

if [ -f "${key_path}" ]; then
  echo "key '${key_path}' already exists" >&2
  exit 5
fi

if [ -f "${cert_path}" ]; then
  echo "certificate '${cert_path}' already exists" >&2
  exit 6
fi

uid="$(whoami)"

# https://www.ibm.com/docs/en/ibm-mq/9.3?topic=certificates-distinguished-names
if command -v git > /dev/null 2>&1; then
  subj="/CN=${host_name}/UID=${uid}/O=$(git config --get user.name)"
else
  subj="/CN=${host_name}/UID=${uid}"
fi
readonly subj

mkdir -p "${out_dir}"

# https://developer.chrome.com/blog/chrome-58-deprecations/#remove_support_for_commonname_matching_in_certificates
# https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout "${key_path}" \
    -new \
    -out "${cert_path}" \
    -subj "${subj}" \
    -addext "subjectAltName=DNS:${host_name}" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=serverAuth" \
    -addext "nsComment=This certificate was locally generated by ${script_path}" \
    -sha256 \
    -days "${days}" 2> /dev/null

chmod 600 "${key_path}" "${cert_path}"

if [ "$(uname)" = 'Darwin' ]; then
  # https://ss64.com/mac/security-cert-verify.html
  security verify-cert -q -n -L -r "${cert_path}"

  expires_on="$(date -Idate -v +"${days}"d)"
  readonly expires_on

  printf "Adding '%s' certificate (expires on: %s) to keychain %s ...\n" "${host_name}" "${expires_on}" "${login_keychain}"

  # https://ss64.com/mac/security-cert.html
  security add-trusted-cert -p ssl -k "${login_keychain}" "${cert_path}"
fi

(
  cd "${out_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
    exit 0 # ${out_dir} not a git repository
  fi

  set +e
  git check-ignore --quiet key.pem
  key_ignored=$?

  git check-ignore --quiet cert.pem
  cert_ignored=$?
  set -e

  if [ $key_ignored -ne 0 ] || [ $cert_ignored -ne 0 ]; then
      printf "\nWARNING: key.pem and/or cert.pem is not ignored in '%s'\n\n" "$PWD/.gitignore"
      read -p "Do you want me to modify your .gitignore file (Y/N)? " -n 1 -r should_modify

      case "${should_modify}" in
        y|Y ) printf "\n\n" ;;
        * ) printf "\n"; exit 0;;
      esac
  fi

  if [ $key_ignored -eq 0 ]; then
    if [ $cert_ignored -eq 0 ]; then
      exit 0 # both already ignored
    fi
    printf "cert.pem\n" >> .gitignore
  else
    if [ $cert_ignored -eq 0 ]; then
      printf "key.pem\n" >> .gitignore
    else
      printf "cert.pem\nkey.pem\n" >> .gitignore
    fi
  fi

  git status
)

if [ "${host_name}" = 'localhost' ]; then
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c "127\.0\.0\.1\s+localhost" /etc/hosts)" -eq 0 ]; then
    printf "\nWARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost'\n" >&2
  fi
else
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c "127\.0\.0\.1\s+localhost.+${host_name//\./\.}" /etc/hosts)" -eq 0 ]; then
    printf "\nWARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost %s'\n" "${host_name}" >&2
  fi
fi
