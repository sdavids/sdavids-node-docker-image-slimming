#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2022 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# script needs to be invoked from the root directory

set -eu

readonly base_dir="$PWD"

readonly build_dir="${base_dir}/dist"

rm -rf "${build_dir}"
