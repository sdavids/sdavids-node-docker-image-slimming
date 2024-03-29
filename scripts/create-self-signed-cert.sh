#!/usr/bin/env bash

#
# Copyright (c) 2024, Sebastian Davids
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
        exit 2
      fi
    ;;
  esac
else # $2 undefined
  days=30
fi
readonly days

readonly script_path="$PWD/$0"

readonly key_path="${out_dir}/key.pem"
readonly cert_path="${out_dir}/cert.pem"

if [ "$(uname)" = 'Darwin' ]; then
  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c localhost 1> /dev/null 2> /dev/null
  found=$?
  set -e

  login_keychain="$(security login-keychain | xargs)"
  readonly login_keychain

  if [ "${found}" = 0 ]; then
    printf "Keychain %s already has a certificate for 'localhost'.\n
You can delete the existing certificate via:\n
\tsecurity delete-certificate -c localhost -t %s\n" "${login_keychain}" "${login_keychain}" >&2
    exit 3
  fi
fi

if [ -f "${key_path}" ]; then
  echo "key '${key_path}' already exists" >&2
  exit 4
fi

if [ -f "${cert_path}" ]; then
  echo "certificate '${cert_path}' already exists" >&2
  exit 5
fi

uid="$(whoami)"

# https://www.ibm.com/docs/en/ibm-mq/9.3?topic=certificates-distinguished-names
if type git > /dev/null 2>&1; then
  subj="/CN=localhost/UID=${uid}/O=$(git config --get user.name)"
else
  subj="/CN=localhost/UID=${uid}"
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
    -addext "subjectAltName=DNS:localhost" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=serverAuth" \
    -addext "nsComment=This certificate was locally generated by ${script_path}" \
    -sha256 \
    -days "${days}" 2> /dev/null

chmod 600 "${key_path}" "${cert_path}"

if [ "$(uname)" = 'Darwin' ]; then
  # https://ss64.com/mac/security-cert-verify.html
  security verify-cert -q -n -L -r "${cert_path}"

  printf "Adding 'localhost' certificate (expires on: %s) to keychain %s ...\n" "$(date -Idate -v +"${days}"d)" "${login_keychain}"

  # https://ss64.com/mac/security-cert.html
  security add-trusted-cert -p ssl -k "${login_keychain}" "${cert_path}"
fi

(
  cd "${out_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
    exit 0 # ${out_dir} not a git repository
  fi

  set +e
  git check-ignore -q key.pem
  key_ignored=$?

  git check-ignore -q cert.pem
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
