#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

find . -type d -name node_modules -exec rm -rf {} +

curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION='10.8.0' sh -

bash -i -c 'pnpm env use --global "$(cat .nvmrc)" && npm i --ignore-scripts=true --fund=false --audit=false && npm cache clean --force >/dev/null 2>&1'
