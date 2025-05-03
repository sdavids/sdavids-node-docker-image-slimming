#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

bash -i -c 'export SHELL=bash && curl -fsSL https://get.pnpm.io/install.sh | sh -'

bash -i -c 'pnpm env use --global "$(cat .nvmrc)" && rm -rf node_modules && npm i --silent --ignore-scripts=false --fund=false --audit=false && npm cache clean --force > /dev/null 2>&1'
