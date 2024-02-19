#!/usr/bin/env sh

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

set -eu

readonly base_dir="${1:-$PWD}"

readonly key_path="${base_dir}/key.pem"
readonly cert_path="${base_dir}/cert.pem"

if [ "$(uname)" = 'Darwin' ]; then
  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c localhost 1> /dev/null 2> /dev/null
  found=$?
  set -e

  if [ "${found}" = 0 ]; then
    login_keychain="$(security login-keychain | xargs)"
    readonly login_keychain

    echo "Removing 'localhost' certificate from keychain ${login_keychain} ..."

    # https://ss64.com/mac/security-delete-cert.html
    security delete-certificate -c localhost -t "${login_keychain}"
  fi
fi

if [ -f "${key_path}" ]; then
  rm -f "${key_path}"
fi

if [ -f "${cert_path}" ]; then
  rm -f "${cert_path}"
fi
