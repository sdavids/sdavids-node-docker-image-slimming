#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# openssl needs to be in $PATH
#   Linux:
#     sudo apt-get install openssl

set -Eeu -o pipefail -o posix

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

while getopts ':c:d:v:xy' opt; do
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
    x)
      allow_existing='true'
      ;;
    y)
      yes='true'
      ;;
    ?)
      echo "Usage: $0 [-c <common_name>] [-d <dir>] [-v <days; 1..24855>] [-x] [-y]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD}"
readonly common_name="${common_name:-localhost}"
readonly allow_existing="${allow_existing:-false}"
readonly yes="${yes:-false}"

if [ -n "${days+x}" ]; then # $days defined
  case ${days} in
    '' | *[!0-9]*) # $days is not a positive integer or 0
      echo "'${days}' is not a positive integer" >&2
      exit 2
      ;;
    *) # $days is a positive integer or 0
      if [ "${days}" -lt 1 ]; then
        echo "'${days}' is not a positive integer" >&2
        exit 3
      fi
      if [ "${days}" -gt 24855 ]; then
        echo "'${days}' is outside of the range 1..24855" >&2
        exit 4
      fi
      if [ "${days}" -gt 180 ]; then
        printf "ATTENTION: '%s' exceeds 180 days, the certificate will not be accepted by Apple platforms or Safari; see https://support.apple.com/en-us/103214 for more information.\n\n" "${days}"
      fi
      if [ "${days}" -gt 47 ]; then
        printf "ATTENTION: '%s' exceeds 47 days, the certificate will not be accepted by browsers after March 14, 2029; see https://www.digicert.com/blog/tls-certificate-lifetimes-will-officially-reduce-to-47-days for more information.\n\n" "${days}"
      fi
      ;;
  esac
else # $days undefined
  days=30
fi
readonly days

script_path="$(realpath "$0")"
readonly script_path

readonly key_path="${base_dir}/key.pem"
readonly cert_path="${base_dir}/cert.pem"

if [ "$(uname)" = 'Darwin' ]; then
  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${common_name}" 1>/dev/null 2>/dev/null
  found=$?
  set -e

  login_keychain="$(security login-keychain | xargs)"
  readonly login_keychain

  if [ "${allow_existing}" = 'false' ] && [ "${found}" = 0 ]; then
    printf "Keychain %s already has a certificate for '%s'. You can delete the existing certificate via:\n\n\tsecurity delete-certificate -c %s -t %s\n" "${login_keychain}" "${common_name}" "${common_name}" "${login_keychain}" >&2
    exit 5
  fi
fi

if [ "${allow_existing}" = 'false' ] && [ -e "${key_path}" ]; then
  printf "The key '%s' already exists.\n" "${key_path}" >&2
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "${key_path}" | pbcopy
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "${key_path}" | xclip -selection clipboard
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${key_path}" | wl-copy
    printf 'The path has been copied to the clipboard.\n' >&2
  fi
  exit 6
fi

if [ "${allow_existing}" = 'false' ] && [ -e "${cert_path}" ]; then
  printf "The certificate '%s' already exists.\n" "${cert_path}" >&2
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "${cert_path}" | pbcopy
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "${cert_path}" | xclip -selection clipboard
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${cert_path}" | wl-copy
    printf 'The path has been copied to the clipboard.\n' >&2
  fi
  exit 7
fi

if [ "${allow_existing}" = 'true' ] && [ ! -e "${key_path}" ] && [ -e "${cert_path}" ]; then
  if [ "$(uname)" = 'Darwin' ]; then
    printf "The key '%s' does not exist.\n\nDelete the certificate '%s' and remove the certificate from the login keychain via:\n\n\tsecurity delete-certificate -c %s -t %s\n" "${key_path}" "${cert_path}" "${common_name}" "${login_keychain}" >&2
  else
    printf "The key '%s' does not exist.\n\nDelete the certificate '%s' and execute this script again.\n" "${key_path}" "${cert_path}" >&2
  fi
  exit 8
fi

if [ "${allow_existing}" = 'true' ] && [ -e "${key_path}" ] && [ ! -e "${cert_path}" ]; then
  if [ "$(uname)" = 'Darwin' ]; then
    printf "The certificate '%s' does not exist.\n\nDelete the key '%s' and remove the certificate from the login keychain via:\n\n\tsecurity delete-certificate -c %s -t %s\n" "${cert_path}" "${key_path}" "${common_name}" "${login_keychain}" >&2
  else
    printf "The certificate '%s' does not exist.\n\nDelete the key '%s' and execute this script again.\n" "${cert_path}" "${key_path}" >&2
  fi
  exit 9
fi

if [ ! -e "${key_path}" ] && [ ! -e "${cert_path}" ]; then
  # https://www.ibm.com/docs/en/ibm-mq/9.3?topic=certificates-distinguished-names
  readonly subj="/CN=${common_name}"

  mkdir -p "${base_dir}"

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
    -addext "subjectAltName=DNS:${common_name}" \
    -addext 'keyUsage=digitalSignature' \
    -addext 'extendedKeyUsage=serverAuth' \
    -addext "nsComment=This certificate was locally generated by ${script_path}" \
    -sha256 \
    -days "${days}" 2>/dev/null

  chmod 600 "${key_path}" "${cert_path}"
fi

if [ "$(uname)" = 'Darwin' ]; then
  # https://ss64.com/mac/security-cert-verify.html
  security verify-cert -q -n -L -r "${cert_path}"

  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${common_name}" 1>/dev/null 2>/dev/null
  found=$?
  set -e

  if [ "${found}" != 0 ]; then
    expires_on="$(date -Idate -v +"${days}"d)"
    readonly expires_on

    printf "Adding '%s' certificate (expires on: %s) to keychain %s ...\n" "${common_name}" "${expires_on}" "${login_keychain}"

    # https://ss64.com/mac/security-cert.html
    security add-trusted-cert -p ssl -k "${login_keychain}" "${cert_path}"
  fi
fi

(
  cd "${base_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    exit 0 # ${base_dir} not a git repository
  fi

  set +e
  git check-ignore --quiet key.pem
  key_ignored=$?

  git check-ignore --quiet cert.pem
  cert_ignored=$?
  set -e

  if [ "${yes}" = 'false' ] && [ $key_ignored -ne 0 ] || [ $cert_ignored -ne 0 ]; then
    printf "\nWARNING: key.pem and/or cert.pem is not ignored in '%s'\n\n" "$PWD/.gitignore"
    read -p 'Do you want me to modify your .gitignore file (Y/N)? ' -n 1 -r should_modify

    case "${should_modify}" in
      y | Y) printf '\n\n' ;;
      *)
        printf '\n'
        exit 0
        ;;
    esac
  fi

  if [ $key_ignored -eq 0 ]; then
    if [ $cert_ignored -eq 0 ]; then
      exit 0 # both already ignored
    fi
    printf 'cert.pem\n' >>.gitignore
  else
    if [ $cert_ignored -eq 0 ]; then
      printf 'key.pem\n' >>.gitignore
    else
      printf 'cert.pem\nkey.pem\n' >>.gitignore
    fi
  fi

  git status
)

if [ "${common_name}" = 'localhost' ]; then
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c '127\.0\.0\.1\s+localhost' /etc/hosts)" -eq 0 ]; then
    printf "\nWARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost'\n" >&2
  fi
else
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c "127\.0\.0\.1.+${common_name//\./\.}" /etc/hosts)" -eq 0 ]; then
    printf "\nWARNING: /etc/hosts does not have an entry for '127.0.0.1 %s'\n" "${common_name}" >&2
  fi
fi

# https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker#1-use-the-localworkspacefolder-as-environment-variable-in-your-code
if [ -n "${LOCAL_WORKSPACE_FOLDER+x}" ]; then
  if [ "${base_dir}" = "${base_dir#/}" ]; then
    printf "The following certificate has been created on your host:\n\n\t%s\n\nExecute the following command on your host to add it to your host's trust store:\n\n\tcd %s && %s -x\n" "${LOCAL_WORKSPACE_FOLDER}/${cert_path}" "${LOCAL_WORKSPACE_FOLDER}" "$0 $*"
  else
    printf "The following certificate has been created in your Development Container:\n\n\t%s\n\nCopy it to your host and add it to your host's trust store.\n" "$(realpath "${cert_path}")"
  fi
fi
