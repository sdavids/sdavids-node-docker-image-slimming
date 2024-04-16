#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2023 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# _shellcheck needs to be in $PATH
# https://www.shellcheck.net
#   Mac:
#     brew install shellcheck
#   Linux:
#     sudo apt-get install shellcheck

set -eu

readonly base_dir="${1:-$PWD}"

find "${base_dir}" -type f -name '*.sh' -not -path '*/node_modules/*' -not -path '*/.husky/*' -print0 | xargs -0L1 shellcheck
