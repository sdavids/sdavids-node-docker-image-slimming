#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2022 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# script needs to be invoked from the project's root directory

set -eu

if [ ! -d 'node_modules' ]; then
  npm install --ignore-scripts=false --fund=false;
fi

npm outdated --long
