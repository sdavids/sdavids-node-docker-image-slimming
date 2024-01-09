#!/usr/bin/env bash

#
# Copyright (c) 2020-2022, Sebastian Davids
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

# script needs to be invoked from project root directory

set -Eeu -o pipefail

readonly days="${1:-10}"

mkdir -p docker/app

openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout docker/app/key.pem \
    -new \
    -out docker/app/cert.pem \
    -subj '/CN=localhost' \
    -extensions EXT -config <( \
       printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth") \
    -sha256 \
    -days "${days}"
